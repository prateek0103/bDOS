;---------------------------------------
;Kernel_data
;---------------------------------------

prompt db ">$"
drive0 db "VITOS:\","$"
times 50 db 0
bufferz db "$"
times 50 db 0
xhelp dw "HELP",0x09,"VER",0x09,"EXIT",0x09,"CLS",0x09,"DIR",0x09,"CD",0x0d0a,0x0d0a,"$"
ver1 dw "VITOS 0.1",0x0d0a,"$"
bad dw 0x0d0a,"Bad command!",0x0d0a,"$"
welcome dw "VIT Disk Operating System version 0.1 ",0x0d0a,"$"
commands db 0x4,"HELP",0x3,"VER",0x4,"EXIT",0x3,"CLS",0x3,"DIR",0x2,"CD",0x4,"CD..",0x4,"TYPE","$"
newlin dw 0x0d0a,"$"
dirsign db " <DIR>$"
dirhelp dw 0x0d0a,"Lists local directory",0x0d0a,0x0d0a,"DIR",0x0d0a,"$"
cdhelp dw 0x0d0a,"Displays the name or changes to local directory.",0x0d0a,0x0d0a,"CD..",0x0d0a,"CD [directory]",0x0d0a,"$"
verhelp dw 0x0d0a,"Displays BDOS version.",0x0d0a,0x0d0a,"VER",0x0d0a,"$"
clshelp dw 0x0d0a,"Clears the screen.",0x0d0a,0x0d0a,"CLS",0x0d0a,"$"
typehelp dw 0x0d0a,"Lists the contents of a text file.",0x0d0a,0x0d0a,"TYPE filename.ext [/p]",0x0d0a,"$"
exithelp dw 0x0d0a,"Restarts the system.",0x0d0a,0x0d0a,"EXIT",0x0d0a,"$"
fail dw 0x0d0a,"Operation failed!",0x0d0a,"$"
pausemsg dw 0x0d0a,"Press any key to continue..","$"
errmsg1 dw "Not a file or bad file!",0x0d0a,"$"
pointer dw 0

Bios_BPB:                    ;Space for bios parameter block copied here from 0x7c00 address
BytesPerSector        dw 0
SectorsPerCluster     db 0
ReservedSectors       dw 0
TotalFATs             db 0
MaxRootEntries        dw 0
TotalSectorsSmall     dw 0
MediaDescriptor       db 0
SectorsPerFAT         dw 0
SectorsPerTrack       dw 0
NumHeads              dw 0
HiddenSectors         dd 0
TotalSectorsLarge     dd 0
DriveNumber           db 0

;data used by fat driver
fatsize        dw 0
rootdirsize    dw 0
absoluteSector db 0x00
absoluteHead   db 0x00
absoluteTrack  db 0x00
datasector     dw 0x0000
cluster        dw 0
ImageName      db 32,32,32,32,32,32,32,32,32,32,32,"$"
;command parser space
cmd            db 0,0,0,0,0,0,0,0,0,0,0,0
param1         db 0,0,0,0,0,0,0,0,0,0,0,0
param2         db 0,0,0,0,0,0,0,0,0,0,0,0
param3         db 0,0,0,0,0,0,0,0,0,0,0,0,"«"
rdir db 0                    ;Location of the FAT table and root dir in memory
                             