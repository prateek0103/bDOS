[BITS 16]
          ORG 0
		  
		;
		;   code by Prateek Gupta, Abhishek Verma, Abhinaba Ghosh
		;	12BCE0275, VIT University
		;	This Command Line OS was developed by me as a part of OS project.
          jmp     START
          nop
     
     OEM_ID                db "VITOS 0.1"
     BytesPerSector        dw 0x0200
     SectorsPerCluster     db 0x01
     ReservedSectors       dw 0x0001
     TotalFATs             db 0x02
     MaxRootEntries        dw 0x00E0
     TotalSectorsSmall     dw 0x0B40
     MediaDescriptor       db 0xF0
     SectorsPerFAT         dw 0x0009
     SectorsPerTrack       dw 0x0012
     NumHeads              dw 0x0002
     HiddenSectors         dd 0x00000000
     TotalSectorsLarge     dd 0x00000000
     DriveNumber           db 0x00
     Flags                 db 0x00
     Signature             db 0x29
     VolumeID              dd 0xFFFFFFFF
     VolumeLabel           db "VITOS   BOOT"
     SystemID              db "FAT12   "
     
     START:
     ; code located at 0000:7C00,marks start of boot
          cli
          mov     ax, 0x07C0
          mov     ds, ax
          mov     es, ax
          mov     fs, ax
          mov     gs, ax

          mov     ax, 0x0000
          mov     ss, ax
          mov     sp, 0xFFFF
          sti
     
          mov     si, msgLoading
          call    DisplayMessage
     LOAD_ROOT:
     ; size of root
          xor     cx, cx
          xor     dx, dx
          mov     ax, 0x0020                         
          mul     WORD [MaxRootEntries]               
          div     WORD [BytesPerSector]               
          xchg    ax, cx
     ; location of root
          mov     al, BYTE [TotalFATs]              
          mul     WORD [SectorsPerFAT]               
          add     ax, WORD [ReservedSectors]         
          mov     WORD [datasector], ax              
          add     WORD [datasector], cx
     
          mov     bx, 0x0200                       
          call    ReadSectors
 
          mov     cx, WORD [MaxRootEntries]           
          mov     di, 0x0200                        
     .LOOP:
          push    cx
          mov     cx, 0x000B                          
          mov     si, ImageName                      
          push    di
     rep  cmpsb                                       
          pop     di
          je      LOAD_FAT
          pop     cx
          add     di, 0x0020                        
          loop    .LOOP
          jmp     FAILURE
     LOAD_FAT:
     ; save starting cluster of boot image
          mov     si, msgCRLF
          call    DisplayMessage
          mov     dx, WORD [di + 0x001A]
          mov     WORD [cluster], dx                  ; file's first cluster
     ; compute size of FAT and store in "cx"
          xor     ax, ax
          mov     al, BYTE [TotalFATs]                ; number of FATs
          mul     WORD [SectorsPerFAT]                ; sectors used by FATs
          mov     cx, ax
     ; compute location of FAT and store in "ax"
          mov     ax, WORD [ReservedSectors]          ; adjust for bootsector
     ; read FAT into memory (7C00:0200)
          mov     bx, 0x0200                          ; copy FAT above bootcode
          call    ReadSectors
     ; read image file into memory (0050:0000)
          mov     si, msgCRLF
          call    DisplayMessage
          mov     ax, 0x0050
          mov     es, ax                              ; destination for image
          mov     bx, 0x0000                          ; destination for image
          push    bx
     LOAD_IMAGE:
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
          mov     bx, 0x0200                          ; location of FAT in memory
          add     bx, cx                              ; index into FAT
          mov     dx, WORD [bx]                       ; read two bytes from FAT
          test    ax, 0x0001
          jnz     .ODD_CLUSTER
     .EVEN_CLUSTER:
          and     dx, 0000111111111111b               
         jmp     .DONE
     .ODD_CLUSTER:
          shr     dx, 0x0004                          
     .DONE:
          mov     WORD [cluster], dx                 
          cmp     dx, 0x0FF0                        
          jb      LOAD_IMAGE
     DONE:
          mov     si, msgCRLF
          call    DisplayMessage
          push    WORD 0x0050
          push    WORD 0x0000
          retf
     FAILURE:
          mov     si, msgFailure
          call    DisplayMessage
          mov     ah, 0x00
          int     0x16                             
          int     0x19                                
     
   
     DisplayMessage:
          lodsb                                       
          or      al, al                              
          jz      .DONE
          mov     ah, 0x0E                           
          mov     bh, 0x00                           
          mov     bl, 0x07                          
          int     0x10                              
          jmp     DisplayMessage
     .DONE:
          ret
     

     ReadSectors:
     .MAIN:
          mov     di, 0x0005                         
     .SECTORLOOP:
          push    ax
          push    bx
          push    cx
          call    LBACHS
          mov     ah, 0x02                           
          mov     al, 0x01                            
          mov     ch, BYTE [absoluteTrack]            
          mov     cl, BYTE [absoluteSector]          
          mov     dh, BYTE [absoluteHead]            
          mov     dl, BYTE [DriveNumber]           
          int     0x13                              
          jnc     .SUCCESS                           
          xor     ax, ax                             
          int     0x13                               
          dec     di                                
          pop     cx
          pop     bx
          pop     ax
          jnz     .SECTORLOOP                       
          int     0x18
     .SUCCESS:
          mov     si, msgProgress
          call    DisplayMessage
          pop     cx
          pop     bx
          pop     ax
          add     bx, WORD [BytesPerSector]          
          inc     ax                                
          loop    .MAIN                            
          ret
     

     ClusterLBA:
          sub     ax, 0x0002                      
          xor     cx, cx
          mov     cl, BYTE [SectorsPerCluster]      
          mul     cx
          add     ax, WORD [datasector]              
          ret
     
 
     LBACHS:
          xor     dx, dx                             
          div     WORD [SectorsPerTrack]              
          inc     dl                                  
          mov     BYTE [absoluteSector], dl
          xor     dx, dx                              
          div     WORD [NumHeads]                     
          mov     BYTE [absoluteHead], dl
          mov     BYTE [absoluteTrack], al
          ret

     absoluteSector db 0x00
     absoluteHead   db 0x00
     absoluteTrack  db 0x00
     
     datasector  dw 0x0000
     cluster     dw 0x0000
     ImageName   db "KERNEL  BIN"
     msgLoading  db 0x0D, 0x0A, "Loading BDOS ", 0x0D, 0x0A, 0x00
     msgCRLF     db 0x0D, 0x0A, 0x00
     msgProgress db ".", 0x00
     msgFailure  db 0x0D, 0x0A, "ERROR : Press Any Key to Reboot", 0x00
     
          TIMES 510-($-$$) DB 0
          DW 0xAA55
