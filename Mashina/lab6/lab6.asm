AStack SEGMENT STACK
	DW 100h DUP(?)
AStack ENDS

DATA SEGMENT
error1 db 'Memory control block has been destroyed.', 0dh, 0ah, '$'
error2 db 'The adress of memory block is incorrect.', 0dh, 0ah, '$'
error3 db 'Not enough memory for function to be performed.', 0dh, 0ah, '$'
error4 db 'The file wasnt found.', 0dh, 0ah, '$'
error5 db 'Disk error.', 0dh, 0ah, '$'
error6 db 'Incorrect number of function.', 0dh, 0ah, '$'
error7 db 'Not enough memory.', 0dh, 0ah, '$'
error8 db 'Incorrect environment string.', 0dh, 0ah, '$'
error9 db 'Incorrect format.', 0dh, 0ah, '$'

finishcode db  0dh, 0ah,'Program finished with code #  ',0dh, 0ah, '$'
finishednormally db  'Finished normally.', 0dh, 0ah, '$'
ctrlfinish db  'Finished by Ctrl-Break', 0dh, 0ah, '$'
deverrfinish db  'Finished by device error.', 0dh, 0ah, '$'
funcfinish db  'Finished by 31h function.', 0dh, 0ah, '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack

KEEP_SS dw  ?
KEEP_SP dw  ?

parameter_block db  14 dup(0)
filepath db  70 dup(0)
position dw  0

Print PROC near
    push ax
    mov ah,09h
    int 21h
    pop ax
    ret
Print ENDP

MAIN PROC
    mov ax,DATA
    mov ds,ax
    mov ax,ENDCB
    mov bx,es
    sub ax,bx
    mov cx,0004h
    shl ax,cl
    mov bx,ax ; в регистр bx-число параграфов, которые будут выделяться в программе
    mov ax,4A00h ; сначала нужно освободить место в памяти
    int 21h      ; эта функция позволяет уменьшить отведенный программе блок памяти
    jnc success ; если не может быть выполнена то выставится флаг CF=1 и в ах вынесется код ошибки
    cmp ax,07h ; разрушен управляющий блок памяти
    je error1j
    cmp ax,08h ; недостаточно памяти для выполнения функции
    je error3j
    cmp ax,09h ; неверный адрес блока пямяти
    je error2j
error1j:
    lea dx,error1
    call Print
    jmp ending
error2j:
    lea dx,error2
    call Print
    jmp ending
error3j:
    lea dx,error3
    call Print
    jmp ending

success: ; потом создать блок параметров (14 байтовый блок памяти с сегментным адресом среды,
    mov byte ptr [parameter_block],00h ; сегментом и смещением командной строки, сегментом и смещением
    mov es,es:[2Ch]                    ; первого и второго FCB 
    mov si,00h
is_zero:            ;если сегментный адрес среды 0, то вызываемая прога наследует среду вызывающей проги
    mov ax,es:[si]  ; то вызываемая прога наследует среду вызывающей проги
    inc si
    cmp ax,0000h
    jne is_zero
    add si,03h
    mov di,00h
write_path:  ; подготовка строки содерж путь и имя вызываемой прогр
    mov cl,es:[si]
    cmp cl,00h ; в конце строки должен стоять код ASCII 0
    je flagn
    cmp cl,'\'
    jne not_yet
    mov position,di
not_yet:
    mov byte ptr [filepath+DI],cl
    inc si
    inc di
    jmp write_path
flagn:
    mov bx,position
    inc bx
    mov byte ptr [filepath+BX],'l'
    inc bx
    mov byte ptr [filepath+BX],'a'
    inc bx
    mov byte ptr [filepath+BX],'b'
    inc bx
    mov byte ptr [filepath+BX],'2'
    inc bx
    mov byte ptr [filepath+BX],'.'
    inc bx
    mov byte ptr [filepath+BX],'c'
    inc bx
    mov byte ptr [filepath+BX],'o'
    inc bx
    mov byte ptr [filepath+BX],'m'
    inc bx
    mov byte ptr [filepath+BX],'$'
    push ds
    push es
    mov KEEP_SP, sp
    mov KEEP_SS, ss
    mov sp,0FEh
    mov ax,CODE
    mov ds,ax
    mov es,ax
    lea bx,parameter_block
    lea dx,filepath
    mov ax,4B00h ; загрузчик ОС
    int 21h
    mov ss,cs:KEEP_SS
    mov sp,cs:KEEP_SP
    pop es
    pop ds
    

    jnc is_performed_4Bh
    cmp ax,01h
    je error6j
    cmp ax,02h
    je error4j
    cmp ax,05h
    je error5j
    cmp ax,08h
    je error3j_4Bh
    cmp ax,0Ah
    je error8j
    cmp ax,0Bh
    je error9j
error6j:
    lea dx,error6
    call Print
    jmp ending
error4j:
    lea dx,error4
    call Print
    jmp ending
error5j:
    lea dx,error5
    call Print
    jmp ending
error3j_4Bh:
    lea dx,error7
    call Print
    jmp ending
error8j:
    lea dx,error8
    call Print
    jmp ending
error9j:
    lea dx,error9
    call Print
    jmp ending
is_performed_4Bh:
    mov ax,4D00h ; обработка завершения - в AH причина, в AL код завершения
    int 21h
    mov bx,ax
    add bh,30h
    lea di,finishcode
    mov [di+29],bl
    lea dx,finishcode
    call Print
    cmp ah,00h
    je finish_0
    cmp ah,01h
    je finish_1
    cmp ah,02h
    je finish_2
    cmp ah,03h
    je finish_3
finish_0:
    lea dx,finishednormally
    call Print
    jmp ending
finish_1:
    lea dx,ctrlfinish
    call Print
    jmp ending
finish_2:
    lea dx,deverrfinish
    call Print
    jmp ending
finish_3:
    lea dx,funcfinish
    call Print
ending:
    mov ah,4Ch
    int 21h
MAIN ENDP
CODE ENDS

ENDCB SEGMENT
ENDCB ENDS

END MAIN