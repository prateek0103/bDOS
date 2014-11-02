LOAD_ROOT:
     ; compute size of root directory and store in "cx"
          xor     cx, cx
          xor     dx, dx
          mov     ax, 0x0020                          ; 32 byte directory entry
          mul     WORD [MaxRootEntries]               ; total size of directory
          div     WORD [BytesPerSector]               ; sectors used by directory
          xchg    ax, cx
     ; compute location of root directory and store in "ax"
          mov     al, BYTE [TotalFATs]                ; number of FATs
          mul     WORD [SectorsPerFAT]                ; sectors used by FATs
          add     ax, WORD [ReservedSectors]          ; adjust for bootsector
          mov     WORD [datasector], ax               ; base of root directory
          add     WORD [datasector], cx
     ; read root directory into memory (7C00:0200)
	      
          lea     bx,[rdir]
          add     bx,[fatsize]		  
          call    ReadSectors
          ret
LOAD_FAT: 
     ; compute size of FAT and store in "cx"
          xor     ax, ax
          mov     al, BYTE [TotalFATs]                ; number of FATs
          mul     WORD [SectorsPerFAT]                ; sectors used by FATs
          mov     cx, ax
     ; compute location of FAT and store in "ax"
          mov     ax, WORD [ReservedSectors]          ; adjust for bootsector
     ; read FAT into memory (rdir address)
          mov     bx, rdir                          ; copy FAT on rdir address
          call    ReadSectors
     ret

;Root_directory_parse routine

rdirparse:
          pop ax                  
		  mov word [pointer],ax      
          mov     cx, WORD [MaxRootEntries]           ; load loop counter
          mov    di,rdir                              ; locate first root entry
		  add    di,[fatsize]
     .LOOP:
          push    cx
          mov     cx, 0x000B                          ; eleven character name
          mov     si, ImageName               		  ; image name to find
		  push di
     rep  cmpsb                                       ; test for entry match
          pop di
          je      next
          pop     cx
          add     di, 0x0020                          ; queue next directory entry
          loop    .LOOP
          jmp     FALIURE
	next:
	      mov     dx, WORD [di + 0x001a]
          mov     WORD [cluster], dx 		  ; file's first cluster  
          mov     si,di		  
          mov word ax,[pointer]     
		  jmp ax

;Load_Image routine

LOAD_IMAGE:
          pop ax                 
		  mov word [pointer],ax      
          mov ax,0x0050                             ; destination for image
		  mov es,ax
          push    bx                                ;es:bx is loaded with destination address before invoking
		                                              ;this function
     LOAD_IT:
          mov     ax, WORD [cluster]                  ; cluster to read
          pop     bx                                  ; buffer to read into
          call    ClusterLBA                          ; convert cluster to LBA
          xor     cx, cx
          mov     cl, BYTE [SectorsPerCluster]        ; sectors to read
          call    ReadSectors
          push    bx
     ; compute next cluster
          mov     ax, WORD [cluster]                  ; identify current cluster
          mov     cx, ax                              ; copy current cluster
          mov     dx, ax                              ; copy current cluster
          shr     dx, 0x0001                          ; divide by two
          add     cx, dx                              ; sum for (3/2)
          mov     bx,rdir                             ; location of FAT in memory
          add     bx, cx                              ; index into FAT
          mov     dx, WORD [bx]                       ; read two bytes from FAT
          test    ax, 0x0001
          jnz     .ODD_CLUSTER
     .EVEN_CLUSTER:
          and     dx, 0000111111111111b               ; take low twelve bits
         jmp     .DONE
     .ODD_CLUSTER:
          shr     dx, 0x0004                          ; take high twelve bits
     .DONE:
          mov     WORD [cluster], dx                  ; store new cluster
          cmp     dx, 0x0FF0                          ; test for end of file
          jb      LOAD_IT
		  mov word ax,[pointer]      ;patch ;)
		  jmp ax

     ; PROCEDURE ReadSectors

     ReadSectors:
     .MAIN:
          mov     di, 0x0005                          ; five retries for error
     .SECTORLOOP:
          push    ax
          push    bx
          push    cx
          call    LBACHS
          mov     ah, 0x02                            ; BIOS read sector
          mov     al, 0x01                            ; read one sector
          mov     ch, BYTE [absoluteTrack]            ; track
          mov     cl, BYTE [absoluteSector]           ; sector
          mov     dh, BYTE [absoluteHead]             ; head
          mov     dl, BYTE [DriveNumber]              ; drive
          int     0x13                                ; invoke BIOS
          jnc     .SUCCESS                            ; test for read error
          xor     ax, ax                              ; BIOS reset disk
          int     0x13                                ; invoke BIOS
          dec     di                                  ; decrement error counter
          pop     cx
          pop     bx
          pop     ax
          jnz     .SECTORLOOP                         ; attempt to read again
          int     0x18
     .SUCCESS:
          pop     cx
          pop     bx
          pop     ax
          add     bx, WORD [BytesPerSector]           ; queue next buffer
          inc     ax                                  ; queue next sector
          loop    .MAIN                               ; read next sector
          ret

     ; PROCEDURE LBACHS
 
     LBACHS:
          xor     dx, dx                              ; prepare dx:ax for operation
          div     WORD [SectorsPerTrack]              ; calculate
          inc     dl                                  ; adjust for sector 0
          mov     BYTE [absoluteSector], dl
          xor     dx, dx                              ; prepare dx:ax for operation
          div     WORD [NumHeads]                     ; calculate
          mov     BYTE [absoluteHead], dl
          mov     BYTE [absoluteTrack], al
          ret

     ; PROCEDURE ClusterLBA

     ClusterLBA:
          sub     ax, 0x0002                          ; zero base cluster number
          xor     cx, cx
          mov     cl, BYTE [SectorsPerCluster]        ; convert byte to word
          mul     cx
          add     ax, WORD [datasector]               ; base data sector
          ret
FALIURE:
mov si,fail
call sprint
jmp main
