;-----------------------------------------
;BDOS_INIT
;-----------------------------------------

cli
          mov     ax, 0x0050
          mov     es, ax
          mov     fs, ax
          mov     gs, ax
                                           ; create stack
          mov     ax, 0x0000
          mov     ss, ax
          mov     sp, 0xFFFF
          sti

mov si,0xb
mov di,BytesPerSector
mov cx,25
call memcpy
cli
mov ax,0x0050
mov ds,ax
sti
call LOAD_FAT                               ;loads FAT table in the memory address specified by 'rdir' label
                                            
xor     ax, ax                              ; compute size of FAT and store in fatsize buffer
mov     al, BYTE [SectorsPerFAT]            ; 
mul     WORD [BytesPerSector]               ; 
mov [fatsize],ax
xor ax,ax
mov al,byte [MaxRootEntries]
mul word [BytesPerSector]
mul byte [SectorsPerCluster]
mov [rootdirsize],ax
call LOAD_ROOT                              ;loads root directory in the memory address  'rdir+fatsize'
