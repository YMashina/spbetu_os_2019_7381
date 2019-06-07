PCMemory 	SEGMENT
		ASSUME CS:PCMemory, DS:PCMemory, es:NOTHING, SS:NOTHING
		ORG 100H
START: JMP BEGIN

AvailableMemory db "Available memory:        bytes", 0dh, 0ah, '$'
FreeMemory db "Free memory:        bytes", 0dh, 0ah, '$'
endline db 0dh, 0ah, '$'
ExtendedMemory db "Extended memory:         kbytes", 0dh, 0ah, 0dh, 0ah, '$'
MCBchain db '                 MCB chain ', 0dh, 0ah, '$'
header db 'Adress     Owner      Size      MCBName   Type', 0dh, 0ah, '$'
MCB db '                                              ', 0dh, 0ah, '$'

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шестн. числа в AX 
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX; в AL старшая цифра
	pop CX          ; в AH младшая
	ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
; перевод в 16 с/c 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
	push BX
	mov BH,AH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	dec DI
	mov AL,BH
	call BYTE_TO_HEX
	mov [DI],AH
	dec DI
	mov [DI],AL
	pop BX
	ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
    push AX
	push CX
	push DX
	xor AH,AH
	xor DX,DX
	mov CX,10
loopfld: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loopfld
	cmp AL,00h
	je end_l
	or AL,30h
	mov [SI],AL
end_l: pop DX
	pop CX
	pop AX
	ret
BYTE_TO_DEC ENDP
;-------------------------------
WRD_TO_DEC PROC near
	push cx
	push dx
		
	mov cx,10
fl: div cx
	or DL, 30h
	mov [SI],DL
	dec SI
	xor dx,dx
	cmp ax,10
	jae fl
	cmp AL,00h
	je endl
	or AL,30h
	mov [SI],AL
endl:
	pop dx
	pop cx
	ret
WRD_TO_DEC ENDP
;--------------------------------

Print PROC near
	mov AH,09h
	int 21h
	ret
Print ENDP 

Available_Memory PROC NEAR 
	push AX
	push BX
	push DX
	push si
	
	sub ax, ax
	mov ah, 04Ah
	mov bx, 0FFFFh
	int 21h
	mov ax, 10h
	mul bx
	mov si, offset AvailableMemory
	add si, 017h
	call WRD_TO_DEC
	mov dx, offset AvailableMemory
	call Print

	pop si
	pop DX
	pop BX
	pop AX
	ret
Available_Memory ENDP

Extended_Memory PROC NEAR
	push ax
	push si
	push dx
	mov al, 31h ;размер расширенной памяти нах. в ячейках 30h, 31h CMOS
	out 70h, al
	in al, 71h ; чтение старшего байта размера расширенной памяти
	mov ah, al ;			
	mov al, 30h ; запись адреса ячейки CMOS 
	out 70h, al
	in al, 71h ; чтение младшего байта
	mov bl, al ; размера расширенной памяти 
		
	lea si, ExtendedMemory
	add si, 23
	xor dx, dx
	call WRD_TO_DEC		
	lea dx, ExtendedMemory
	call Print
		
	pop dx
	pop si
	pop ax
	ret
Extended_Memory ENDP

MCB_Data PROC near
	push ax
	push bx
	push cx
	push dx
	push es
	push si
	push di
		
	lea dx, MCBchain
	call Print
	lea dx,  header
	call Print
	mov AH, 52h ; Get List of Lists
	int 21h
	mov es, es:[bx-2]		; слово по адресу es:[bx-2] - адрес самого первого MCB

	loopMCB:
	    mov ax, es	; текущий адрес MCB
	    lea di, MCB
		add di, 4
		call WRD_TO_HEX
		mov ax, es:[01h] ; сегментный адрес PSP владельца участка памяти
		lea di, MCB
		add di, 14
		call WRD_TO_HEX
		mov ax, es:[03h]		; размер участка в параграфах
		mov bx, 10h
		mul bx
		lea si, MCB
		add si, 25
		call WRD_TO_DEC
		
		lea di, MCB
		add di, 32
		mov cx, 8
		mov bx, 0
	MCBname:
		mov al, es:[08h + bx] ;sc- в участке системный код, sd-в нем системные данные
		mov [di + bx], al
		inc bx
	loop MCBname
		
	mov al, es:[00h] ; тип MCB
	lea di, MCB
	add di, 43
	call BYTE_TO_HEX
	mov [di], al
	inc di
	mov [di], ah
	lea dx, MCB
	call Print
	mov ax, es
	add ax, es:[03h]
	inc ax
	mov BL, es:[00h]	
	mov es, ax	; адрес следующего MCB в списке
	cmp BL, 4Dh ; 4Dh - не последний в списке
	je loopMCB	; 5Ah - последний в списке

	pop di
	pop si
	pop es
	pop dx
	pop cx
	pop bx
	pop ax
	ret
MCB_Data ENDP

BEGIN:
	call Available_Memory
	call Extended_Memory
	call MCB_Data
	xor AL,AL  ;|
	mov AH,4Ch ;| exit to dos
	int 21H    ;|
PCMemory 	ENDS
		END START