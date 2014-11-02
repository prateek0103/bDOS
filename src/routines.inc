
;Print_string routine

sprint:
      pusha	    	  ; Routine: output string in SI to screen
      mov ah, 0x0E		; int 10h 'print char' function

repeat:
	lodsb			; Get character from string
    cmp al,"$"
	je done		; If char is zero, end of string
	int 0x10	; Otherwise, print it
	jmp repeat
   
done: 
popa
ret

;Input_string routine

inputs:
pusha
mov dx,di
input:
mov ah,0x0
int 0x16
cmp al,0x0d
je enter_pressed
cmp al,0x08
je backspace_pressed
mov ah,0x0e
int 0x10
stosb
jmp input

backspace_pressed:
cmp dx,di
je input
mov ah,0x0e
int 0x10
mov ah,0x0a
mov al,0x20
xor bx,bx
mov cx,2
int 0x10
dec di
mov byte [di],0
jmp input

enter_pressed:
mov byte [di],"$"
mov ah,0x0e
mov al,0x0d
int 0x10
mov al,0x0a
int 0x10
popa
ret

;Compare_string routine

comps:
push cx
xor ax,ax
cmp byte [di],"$"
je equ
cld
mov cx,[di]
xor ch,ch
inc di
repe cmpsb
jne notequ
cmp byte [si],"$"
je equ
cmp byte [si]," "
je equ
notequ:
add di,cx
pop cx
mov ah,0x0
jmp end
equ:
pop cx
mov ah,0x01
end:
ret

;Hexadecimal_to_ASCII routine


hex2ascii:
mov dword  eax,[si]
hextoasc: 
                                ;si input address , di point result storage addres
        pusha
        mov ecx,00h
        mov ebx,0ah
        hexloop1:
                mov edx,0
                div ebx
                add dl,'0'
                push edx
                inc ecx
                cmp eax,0ah
                jge hexloop1
                add al,'0'
                mov [di],al
        hexloop2:
                pop eax
                inc di
                mov [di],al
                loop hexloop2
                inc di
                mov al,'$'
                mov [di],al
                popa
                ret

;memcpy routine

memcpy:
cld
rep movsb
ret

;string_lenght routine

strlen:
xor di,di
push si
calc_len:
cmp byte [si],"$"
je strlen_end
inc si
jmp calc_len
strlen_end:
mov di,si
pop si
sub di,si
ret

;flush_buffer routine

flush:
pusha
flush_start:
cmp byte [si],"«"
je flush_end
mov byte [si]," "
inc si
jmp flush_start
flush_end:
popa
ret

fnconv:
pusha
xor cx,cx
fnconv_loop:
cmp byte [si],"."
je fnconv_next
mov byte al,[si]
mov byte [di],al
inc si
inc di
inc cl
jmp fnconv_loop
fnconv_next:
mov ch,7
sub ch,cl
fnconv_loop1:
cmp ch,0
je fnconv_next1
mov byte [di],32
inc di
dec ch
jmp fnconv_loop1
fnconv_next1:
mov ch,3
fnconv_loop2:
cmp ch,0
je fnconv_end
inc si
inc di
dec ch
mov byte al,[si]
mov byte [di],al
jmp fnconv_loop2
fnconv_end:
popa
ret

;Lcase_to_Ucase routine

ltou:
pusha
ltou_start:
cmp byte [si],96
jng ltou_next
cmp byte [si],123
jnl ltou_next
sub word [si],32
inc si
jmp ltou_start
ltou_next:
cmp byte [si],"$"
je ltou_end
inc si
jmp ltou_start
ltou_end:
popa
ret

;Command_parser routine
  
cmdparser:
pusha
xor dx,dx
xor cx,cx
xor al,al
mov ah,1
mov di,cmd
cmdparser_start1:
cmp byte [si]," "
je cmdparser_next
cmp byte [si],"$"
je cmdparser_final
cmp word cx,12
je cmdparser_bad
inc cx                  ;counts the characters
mov ah,0
mov byte al,[si]
mov byte [di],al
inc si
inc di
jmp cmdparser_start1
cmdparser_loop:
mov byte [di],"$"
inc dx                  ;counts buffers
cmp word dx,3
je cmdparser_final
sub di,cx
add di,12
xor cx,cx
jmp cmdparser_start1
cmdparser_next:
inc ah                  ;counts the spaces
cmp byte ah,1
je cmdparser_loop
inc si
jmp cmdparser_start1
cmdparser_bad:
mov si,badmsg
call sprint
jmp cmdparser_end
cmdparser_final:
mov byte [di],"$"
cmdparser_end:
popa 
ret
badmsg       db "Invalid string lenght!$"
