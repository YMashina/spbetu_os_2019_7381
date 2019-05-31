AStack SEGMENT STACK
 dw 64 dup(?)
AStack ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack

DATA SEGMENT
	wrongadress db 'Wrong memory address',13, 10,'$'
	nonexist db 'Error: Non-existent function', 13, 10, '$'   
	manyfiles db 'Error: Too many opened files', 13, 10, '$'
	noaccess db 'Error: No access', 13, 10, '$'					
	notenoughmemry db 'Error: Not enough memory', 13, 10, '$'					
	incenv db 'Error: Incorrect environment', 13, 10, '$'
    memryblockdestroyed db 'Memory control block destroyed',13, 10,'$'
	notenough db 'Not enough memory to perform the function',13, 10,'$'
	filenf db 'Error: File not found', 13, 10, '$'
	pathnf db 'Error: Path not found', 13, 10, '$'
	
    str_overlay1 db 'LAB7OVL1.OVL', 0
	str_overlay2 db 'LAB7OVL2.OVL', 0
	DTA db 43 dup (0), '$'
	Overlay_Path db 100h	dup (0), '$'
	OVERLAY_ADDR dd 0
	KEEP_PSP dw 0
	Overlay_Adress dw 0
DATA ENDS


Print PROC NEAR 
    push ax 
    mov ah, 09h
    int 21h
    pop ax
    ret
Print ENDP

OVL_Path PROC NEAR
push ax
push bx
push cx
push dx
push si
push di
push es
mov es, KEEP_PSP
mov ax, es:[2Ch]
mov es, ax
mov bx, 0
mov cx, 2
call Variables
call Path

get_way:
mov ah, [di]
mov [si], ah
cmp ah, 0
jz check_way
inc di
inc si
jmp get_way

check_way:
pop es
pop di
pop si
pop dx
pop cx
pop bx
pop ax
ret
OVL_Path ENDP

Path PROC NEAR
get_path:
mov al, es:[bx]
mov [si], al
inc si
inc bx
cmp al, 0
jz check_path
jmp get_path

check_path:
sub si, 9
mov di, bp
ret
Path ENDP

Clear_Memory PROC NEAR ; освобождение памяти для загрузки оверлеев
mov bx,offset LAST_BYTE 
mov ax,es 
sub bx,ax 
mov cl,4h
shr bx,cl 
mov ah,4Ah ; освобождение памяти перед загрузкой оверлея
int 21h
jnc end_clear 

call Errors
xor al,al
mov ah,4Ch
int 21h
end_clear:
ret
Clear_Memory ENDP

Errors PROC NEAR
cmp ax,7
mov dx,offset memryblockdestroyed
je print1
cmp ax,8
mov dx,offset notenough
je print1
cmp ax,9
mov dx,offset wrongadress
je print1

print1:
call Print
ret
Errors ENDP

Variables PROC NEAR
get_variables:
inc cx
mov al, es:[bx]
inc bx
cmp al, 0
jz check_end
loop get_variables

check_end:
cmp byte PTR es:[bx], 0
jnz get_variables
add bx, 3
mov si, offset Overlay_Path
ret
Variables ENDP

ovl_size PROC NEAR ; чтение размера файла оверлея 
push bx
push es
push si

push ds
push dx
mov dx, SEG DTA
mov ds, dx
mov dx, offset DTA
mov ax, 1A00h ; в области памяти буфера DTA со смещением 1Ah будет находиться младшее слово размера файла
int 21h
pop dx
pop ds

push ds
push dx
xor cx, cx
mov dx, SEG Overlay_Path
mov ds, dx
mov dx, offset Overlay_Path
mov ax, 4E00h ; определение размера оверлея
int 21h
pop dx
pop ds

jnc no_err_size 
cmp ax, 2
je err1
cmp ax, 3
je err2
jmp no_err_size

err1:
mov dx, offset filenf
call Print
jmp exit
err2:
mov dx, offset pathnf
call Print
jmp exit

no_err_size:
push es
push bx
push si
mov si, offset DTA
add si, 1Ch ; в слове со смещением 1Сh в  DTA будет находиться старшее слово размера памяти в байтах
mov bx, [si]

sub si, 2
mov bx, [si]
push cx
mov cl, 4
shr bx, cl 
pop cx
mov ax, [si+2] 
push cx
mov cl, 12
sal ax, cl
pop cx
add bx, ax
add bx, 2
mov ax, 4800h ; отведение памяти 
int 21h
mov Overlay_Adress, ax
pop si
pop bx
pop es

exit:
pop si
pop es
pop bx
ret
ovl_size ENDP

Bhfuncerrors PROC NEAR ; от обращения к функции 4B03h:
cmp ax, 1 ; несуществующая функция
mov dx, offset nonexist
je print3
cmp ax, 2 ; файл не найден
mov dx, offset filenf
je print3
cmp ax, 3 ; маршрут не найден
mov dx, offset pathnf
je print3
cmp ax, 4 ; слишком много открытых файлов
mov dx, offset manyfiles
je print3
cmp ax, 5 ; нет доступа
mov dx, offset noaccess
je print3
cmp ax, 8 ; мало памяти
mov dx, offset notenoughmemry
je print3
cmp ax, 10 ; неправильная среда
mov dx, offset incenv
je print3

print3:
call Print
ret
Bhfuncerrors ENDP

NO_ERROR_RUN PROC NEAR
mov ax, SEG DATA
mov ds, ax
mov ax, Overlay_Adress
mov WORD PTR OVERLAY_ADDR+2, ax
call OVERLAY_ADDR
mov ax, Overlay_Adress
mov es, ax
mov ax, 4900h ; освобождение памяти после отработки оверлея
int 21h
mov ax, SEG DATA
mov ds, ax
ret
NO_ERROR_RUN ENDP

Run_ovl PROC NEAR
push bp
push ax
push bx
push cx
push dx
mov bx, SEG Overlay_Adress
mov es, bx
mov bx, offset Overlay_Adress

mov dx, SEG Overlay_Path
mov ds, dx
mov dx, offset Overlay_Path
push ss
push sp

mov ax, 4B03h ; для запуска вызываемого оверлейного модуля
int 21h
jnc no_error_way

call Bhfuncerrors
jmp exit_way
no_error_way:
call NO_ERROR_RUN

exit_way:
pop sp
pop ss
mov es, KEEP_PSP
pop dx
pop cx
pop bx
pop ax
pop bp
ret
Run_ovl ENDP


MAIN PROC FAR
mov ax, seg DATA
mov ds, ax
mov KEEP_PSP, es
call Clear_Memory
mov bp, offset str_overlay1
call OVL_Path
call ovl_size
call Run_ovl
mov bp, offset str_overlay2
call OVL_Path
call ovl_size
call Run_ovl

xor al, al
mov ah, 4Ch
int 21H 
ret
MAIN ENDP
CODE ENDS

LAST_BYTE SEGMENT
LAST_BYTE ENDS

END MAIN 