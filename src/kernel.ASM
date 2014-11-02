[BITS 16]
org 0x0

%include 'init.inc'         ;initialisation routine
%include 'routines.inc'		;all routines used in kernel
%include 'fat12.inc'		;fat12 filesystem driver
%include 'data.inc'			;all data used in kernel

mov si,welcome
call sprint                 ;prints out the welcome string

main:
xor cx,cx
mov si,newlin
call sprint                 ;prints a new line

mov si,drive0
call sprint                 ;prints out 'A:\'

mov si,prompt
call sprint                 ;prints the prompt '>'

mov di,bufferz
call inputs                 ;waits for input from user

mov si,cmd
call flush                  ;clears the cmd buffer

mov si,param1
call flush                  ;clears the param1 buffer

mov si,ImageName
call flush                 

mov si,bufferz
call cmdparser              ;parses the user input into command,parameter1,parameter2,parameter3

mov si,cmd
call ltou                   ;converts command in buffer into all caps

mov di,commands
.loop1:
mov si,cmd
call comps                  ;compares the user command with the predefined commands
inc cx                      ;cx is counting which command was compared by order
cmp ah,0                    ;if user input do not matches with the predefined command,
je .loop1                   ;then jump to make another loop
cmp cx,8                    ;each command has it's own number and they are 'jumped' to according to this order
je type1
cmp cx,7
je cd2
cmp cx,6
je cd
cmp cx,5
je dir
cmp cx,4
je cls
cmp cx,3
je reboot
cmp cx,2
je ver
cmp cx,1
je help

mov si,bad                    ;prints out a text if the entered command was not found
call sprint
jmp main

;          HELP command          ;


help:                         ;prints out available commands
mov si,xhelp
call sprint
jmp main

;          VER command          ;


ver:
cmp word [param1],"/?"       ;if parameter1 buffer holds the '/?' string,then
je helptext1                 ;jump to specified label and display command usage
mov si,ver1
call sprint                  ;displays BDOS version
jmp main
helptext1:
mov si,verhelp
call sprint
jmp main

;          EXIT command         ;


reboot:
cmp word [param1],"/?"             ;if parameter1 buffer holds the '/?' string,then
je helptext2                       ;jump to specified label and display command usage
db 0x0ea,0x0f0,0x0ff,00h,0x0f0     ;code for reboot
helptext2:
mov si,exithelp
call sprint
jmp main

;          CLS command          ;


cls:
cmp word [param1],"/?"             ;if parameter1 buffer holds the '/?' string,then
je helptext3                       ;jump to specified label and display command usage
mov cx,25                          ;counter is set to 25 because DOS can display 25 line 
loop:
mov si,clear
call sprint                        ;prints out 25 times CR and LF chars
dec cx                             ;cx is decremented in each run
cmp cx,0                           ;if cx = 0 then
je set_cursor                      ;set the cursor position
jmp loop
set_cursor:
xor bx,bx                          ;bx register is cleared,we want to print on first page of screen
mov ah,0x02                        ;see Ralph Brown's interrupt list (int 0x10 , ah = 0x2)
xor dx,dx
int 0x10                           
jmp main
clear dw 0x0d0a,"$"                ;CR LF in hexadecimal
helptext3:
mov si,clshelp
call sprint
jmp main

;          DIR command          ;


dir:
cmp word [param1],"/?"             ;if parameter1 buffer holds the '/?' string,then
je helptext0                       ;jump to specified label and display command usage
pusha                              ;registers and flags are saved onto stack
lea si,[rdir]                      ;loads the starting memory address of the FAT table into 'si'
add si,[fatsize]                   ;and adds the size of the FAT table to 'si' (now si = root directory 
sub si,32                          ;starting address - 32)

loop2:
add si,32                          ;starting address of root directory
push si                            ;'si' is saved onto stack
mov bx,si                          
push bx
cmp byte [ds:si],0xe5              ;if the first char in the root directory entry equals to 0xe5 (deleted file)
je loop2                           ;then check the next entry
cmp byte [ds:si+2],0x00            ;if the 3rd char is equal to 0 ,then
je checkit                         ;jump to check the first char
mov cx,11                          ;filename is 11 chars long
mov di,filename.ext                ;buffer for filenames

repeat1:                          
cmp cx,0                           ;loop until cx = 0 and then 
je ext                             ;jump to check is it a directory
mov ax,[ds:si]                     ;copies one char to out buffer
mov [di],ax
inc di                             ;increments pointers
inc si
dec cx                             ;decrements the counter
jmp repeat1

ext:
cmp byte [bx+11],0x10              ;check byte 11 ,does it queals to 0x10 (directory) and then 
je printit                         ;jumps to print directory out

printit:
mov byte [di],"$"                  ;put a string terminator '$' after the filename
mov si,filename.ext
call sprint                        ;display our filename
mov si,space2                      ;print out some spaces 
cmp byte [bx+11],0x10              ;if the 11th byte in the entry equals to 0x10 then,
jne go                             ;jump over
mov si,dirsign
call sprint                        ;prints out '<DIR>' sign
mov si,space

go:
call sprint                        ;some spaces
mov di,filesize
pop bx                             ;bx is now the starting address of the root directory entry
lea si,[bx+28]                   
call hex2ascii                     ;coverts file size (bits 28-31) from hex to ASCII decimal
mov si,filesize
call sprint                        ;prints out file size
mov si,newlin
call sprint                        ;newline
pop si
jmp loop2

checkit:
cmp byte [ds:si],0                 ;if the first byte in the entry does not equals to 0 then
jne loop2                          ;jump to loop again,else its end of the root directory

finish:
popa                               ;restores registers and flags from stack
jmp main

helptext0:
mov si,dirhelp
call sprint
jmp finish
filename.ext db 0,0,0,0,0,0,0,0,0,0,0,0
filesize db 0,0,0,0,0,0,0,0
space db 0x20,"$"
space2 db "       $"

;          CD command           ;


cd:
cmp word [param1],"/?"               ;if parameter1 buffer holds the '/?' string,then
je helptext5                         ;jump to specified label and display command usage
pusha
cmp byte [param1],0x20               ;if the parameter1 buffer is empty ( filled with spaces) ,then
je show_path                         ;jump to show current path
mov si,param1
call ltou                            ;converts string in param1 buffer to uppercase
mov di,ImageName

dirname:
cmp byte [si],"$"                    ;if the char in the ImageName bufer is a string terminator ,then                   
je mod_path                          ;jump to modify the path
mov al,[si]                          ;copies a char from param1 to ImageName
mov byte [di],al
inc si                               ;pointers are incremented
inc di
jmp dirname

mod_path:
call rdirparse                       ;search for the filename in the directory entries
mov si,drive0
call strlen                          ;determine the lenght of the current path string
lea bx,[drive0+di]                   ;bx now points to the and of the current path string
mov si,param1
                        
cd_loop:
cmp byte [si],"$"                    ;if the char is a string terminator ,then
je dirname1                          ;jump to put the slash on the end of the string
mov al,[si]                          ;copies characters from param1 to drive0
mov byte [bx],al
inc bx                               ;pointers are incremented
inc si
jmp cd_loop

dirname1:
mov word [bx],"\$"                   ;'\$' is appended to the end of the current path string
lea bx,[rdir]                        ;starting address of the root directory is calculated
add bx,[fatsize]
call LOAD_IMAGE                      ;loads the directory file from disk into calculated location
cd_end:
jmp main

show_path:
call sprint
mov si,drive0
call sprint                          ;displays current path
pop si
call sprint
jmp cd_end

helptext5:
mov si,cdhelp
call sprint
jmp cd_end

;          CD.. command         ;


cd2:
lea bx,[rdir]                        ;calculates the starting address of the root directory
add bx,[fatsize]
mov si,bx
add si,32
cmp word [si],".."                   ;if the first 2 bytes in the second entry in the root directory is not "..",then
jne cd2_end                          ;jump to end (no parent directory = root)
pusha
mov si,drive0
call strlen                          ;the lenght of the current path is determined
add di,si                            ;now di points to the end of the current path string
sub di,2                             ;di - 2 because we have to "jump" over the last slash

separator:
dec di                               
cmp byte [di],"\"                    ;if the character doesn't equals to "\",then
jne separator                        ;try the next one,else
inc di                               ;increment the pointer and   
mov byte [di],"$"                    ;put a string terminator
popa                                 ;restores registers and flags,among them di = starting address of the root directory entry
mov di,[si+0x1a]                     ;saves the starting cluster of the file
mov [cluster],di
cmp word [cluster],0                 ;if cluster = 0 then
je rootload                          ;jump to load the root directory,else
call LOAD_IMAGE                      ;load the directory file specified by filename
jmp cd2_end

rootload:
call LOAD_ROOT                       ;loads root directory

cd2_end:
jmp main

;          TYPE command         ;


type1:
cmp word [param1],"/?"               ;if parameter1 buffer holds the '/?' string,then
je helptext6                         ;jump to specified label and display command usage
pusha
mov si,param2                        
call ltou                            ;converts the string in parameter2 buffer into uppercase       
mov si,param1
call ltou                            ;converts the string in parameter2 buffer into uppercase
mov di,ImageName
call fnconv                          ;converts the filename to match the directory entry type (from param1 to ImageName)
cmp byte [di+0x9],0x20               ;if the file has no extension (directory),then
je done2                             ;jump to display error message,else
call rdirparse                       ;search directory entries for the specified filename
mov bx,0x4000                        ;location where the specified file is loaded
call LOAD_IMAGE                      ;load it
mov di,0x4000                        ;calculates the address of the end of the file and
add word di,[si+28]
mov byte [di],"$"                    ;adds a string terminator
cmp word [param2],"/P"               ;if parameter2 equals to "/p" then
je type1_page                        ;jump to type the file in pages,else
mov si,0x4000
call sprint                          ;display the content of the file
jmp main

type1_page:                          ;prints the content of the file in screenful pages
mov si,0x4000
pusha	
xor cx,cx     	  
mov ah, 0x0E		
repeat2:
	lodsb			
	inc cx
    cmp al,"$"
	je done1		
	int 0x10	
	cmp cx,1080
	je next2
	jmp repeat2
	
next2:
call pause                           ;pauses after each pages of content
xor cx,cx
jmp  repeat2   

done1: 
popa
jmp main

done2:
mov si,errmsg1
call sprint
jmp done1
helptext6:
mov si,typehelp
call sprint
jmp done1

pause:
pusha
mov si,pausemsg
call sprint
xor ax,ax
int 0x16
mov si,newlin
call sprint
popa
ret
