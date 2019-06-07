TESTPC	SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG	100H

START: JMP BEGIN

PCtype db 'PC type: $'
PCtype_PC db 'PC',0DH,0AH,'$'
PCtype_PCXT db 'PC/XT',0DH,0AH,'$'
PCtype_AT db 'AT',0DH,0AH,'$'
PCtype_PS2_30 db 'PS2 model 30',0DH,0AH,'$'
PCtype_PS2_50_or_60 db 'PS2 model 50 or 60',0DH,0AH,'$'
PCtype_PS2_80 db 'PS2 model 80',0DH,0AH,'$'
PCtype_PCjr db 'PCjr',0DH,0AH,'$'
PCtype_PC_Convertible db 'PC Convertible',0DH,0AH,'$'

System_version db 'System version:  . ',0DH,0AH,'$'
OEM db 'OEM:   ',0DH,0AH,'$'
Serial_number db 'Serial number:       ',0DH,0AH,'$'

;-----------------------------------------------------
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


Type_of_PC PROC near
    push ax
	lea dx,PCtype
	call Print
    mov ax,0F000h ;тип хранится в байте по адресу 0F000:0FFFEh (предпоследний байт ROM BIOS)
	mov es,ax
	mov ax,es:0FFFEh

	cmp al,0FFh ; PC
	je PC_type

	cmp al,0FEh ; PC/XT
	je PCXT_type
                    ;(FE,FB)
	cmp al,0FBh ; PC/XT
	je PCXT_type

	cmp al,0FCh ;AT
	je AT_type

	cmp al,0FAh ;PS2 модель 30
	je PS2_30_type

	cmp al,0FCh ;PS2 модель 50 или 60
	je PS2_50_or_60_type

	cmp al,0F8h  ;PS2 модель 80
	je PS2_80_type

	cmp al,0FDh
	je PCjr_type

	cmp al,0F9h
	je PC_Convertible_type

	PC_type:
		lea dx,PCtype_PC
		jmp PrintType
	PCXT_type:
		lea dx,PCtype_PCXT
		jmp PrintType
	AT_type:
		lea dx,PCtype_AT
		jmp PrintType
	PS2_30_type:
		lea dx,PCtype_PS2_30
		jmp PrintType
	PS2_50_or_60_type:
		lea dx,PCtype_PS2_50_or_60
		jmp PrintType
	PS2_80_type:
		lea dx,PCtype_PS2_80
		jmp PrintType
	PCjr_type:
		lea dx,PCtype_PCjr
		jmp PrintType
	PC_Convertible_type:
		lea dx,PCtype_PC_Convertible
		jmp PrintType

	PrintType:
	call Print
	pop ax
	ret
Type_of_PC ENDP


SystemVersion PROC near
	mov ah,30h
	int 21h

    ; System version (AL- номер основной версии, AH - номер модификации)
    
	lea dx,System_version
	mov si,dx
	add si,16
	call BYTE_TO_DEC
	add si,3
	mov al,ah
	call BYTE_TO_DEC
	call Print

    ; OEM (BH-сериный номер Original Equipment Manufacturer)

	lea dx,OEM
	mov si,dx
	add si,7
	mov al,bh
	call BYTE_TO_DEC
	call Print

    ; Serial number (BL:CX - 24-битовый серийный номер пользователя)
    
	lea dx,Serial_number
	mov di,dx
	mov al,bl
	call BYTE_TO_HEX
	add di,15
	mov [di],ax
	mov ax,cx
	mov di,dx
	add di,20
	call WRD_TO_HEX
	call Print

	ret
SystemVersion ENDP

; Код

BEGIN:

    call Type_of_PC
	call SystemVersion
	xor AL,AL  ;|
	mov AH,4Ch ;| exit to dos
	int 21H    ;|
TESTPC ENDS
    END START