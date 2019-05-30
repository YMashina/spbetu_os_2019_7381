PCINF SEGMENT
 ASSUME CS:PCINF, DS:PCINF, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN

inaccessibleMemoryAdr db 'Inaccesible memory segment begins at adress: $'
InaccessibleMemAdr db '    $'
EnvironmentAdr db 'Environment segment adress: $'
EnvAdr db '    $'
PrintTail db 'Tail:$'
TAIL db 50h DUP(' '),'$'
NoTail db 'No tail$'
EnvironmentContents db 'Environment contents:',0DH,0AH,'$'
ModulePath db 'Module path:',0DH,0AH,'$'
_ENDL db 0DH,0AH,'$'
	
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
loop_bd: div CX
	or DL,30h
	mov [SI],DL
	dec SI
	xor DX,DX
	cmp AX,10
	jae loop_bd
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

Print PROC near
	mov AH,09h
	int 21h
	ret
Print ENDP

Inaccessible_memory_adress PROC near ; сегментный адрес недоступной памяти, взятый из Program Segment Prefix (префикса сегмента программы)
	mov ax,ds:[2] ; сегментный адрес первого байта недоступной памяти
	mov es,ax
	mov di,offset InaccessibleMemAdr+3

	call WRD_TO_HEX
	mov dx,offset inaccessibleMemoryAdr
	call Print
	mov dx,offset InaccessibleMemAdr
	call Print
	mov dx,offset _ENDL
	call Print
	ret
Inaccessible_memory_adress ENDP

Environment_adress PROC near ;сегментный адрес среды, передаваемой программе, в шестн. виде
	mov ax,ds:[2Ch] ;сегментный адрес среды
	mov di,offset EnvAdr+3

	call WRD_TO_HEX
	mov dx,offset EnvironmentAdr
	call Print
	mov dx,offset EnvAdr
	call Print
	mov dx,offset _ENDL
	call Print
	ret
Environment_adress ENDP

Print_tail PROC near ; хвост командной строки в символьном виде
	xor ch,ch
	mov cl,ds:[80h] ; число символов в хвосте командной строки
	
	cmp cl,0
	jne notnil
	mov dx,offset NoTail
	call Print
	mov dx,offset _ENDL
	call Print
	ret
	notnil:
	
	mov dx,offset PrintTail
	call Print
	
	mov bp,offset TAIL
	cycle:
	mov di,cx
	mov bl,ds:[di+80h]
	mov ds:[bp+di-1],bl
	loop cycle
	
	mov dx,offset TAIL
	call Print
	ret
Print_tail ENDP

Print_environment PROC near ; содержимое области среды в символьном виде
	mov dx, offset _ENDL
	call Print
	mov dx, offset EnvironmentContents
	call Print

	mov ax,ds:[2ch]; сегментный адрес среды передаваемый программе
	mov es,ax
	
	xor bp,bp
	PE_cycle1:
		cmp word ptr es:[bp],0001h ; после 00h, 01h располагается маршрут загруженной программы
		je PE_exit1
		cmp byte ptr es:[bp],00h ; среда заканчивается байтом нулей
		jne PE_noendl
		mov dx,offset _ENDL
		call Print
		inc bp
	PE_noendl:
		mov dl,es:[bp]
		mov ah,02h
		int 21h
		inc bp
	jmp PE_cycle1
	PE_exit1:
	add bp,2
	
	mov dx, offset _ENDL
	call Print
	mov dx, offset ModulePath
	call Print
	
	PE_cycle2:
		cmp byte ptr es:[bp],00h ;маршрут заканчивается байтом нулей
		je PE_exit2
		mov dl,es:[bp]
		mov ah,02h
		int 21h
		inc bp
	jmp PE_cycle2
	PE_exit2:
	
	ret
Print_environment ENDP

BEGIN:
	call Inaccessible_memory_adress
	call Environment_adress
	call Print_tail
	call Print_environment
	mov ah,01h
    int 21h
	;xor AL,AL  ;|
	mov AH,4Ch ;| exit to dos
	int 21H    ;|
PCINF ENDS
 END START