VIDEO_MEMORY equ 0xb8000
SCREEN_WIDTH equ 80
SCREEN_HEIGHT equ 25

cursor_x:
	db 0
cursor_y:
	db 0

color:
	db 0x0f

clear_screen:
	mov eax, VIDEO_MEMORY
	mov ebx, 2000
.loop:
	mov WORD [eax], 0x0f00
	add eax, 2
	dec ebx
	cmp ebx, 0
	jg .loop
	ret

; Input al = char
; Modifies eax, ebx, ecx, edx
print_char:
	cmp al, 0xa
	je .newline
	cmp al, 0x8
	je .backspace
	
	mov bl, al
	mov eax, 0
	mov al, [cursor_y]
	mov ecx, SCREEN_WIDTH
	mul ecx
	mov cl, [cursor_x]
	add eax, ecx
	shl eax, 1
	add eax, VIDEO_MEMORY
	mov [eax], bl
	inc eax
	mov bl, [color]
	mov [eax], bl
	
	; Move cursor
	inc BYTE [cursor_x]
	mov al, [cursor_x]
	cmp al, SCREEN_WIDTH
	jl .end
	mov BYTE [cursor_x], 0
	inc BYTE [cursor_y]
.end:
	; Move cursor display
	mov eax, 0
	mov ebx, 0
	mov al, [cursor_y]
	mov bl, [cursor_x]
	mov dl, SCREEN_WIDTH
	mul dl
	add bx, ax
	
	mov dx, 0x3d4
	mov al, 0x0f
	out dx, al
	
	inc dl
	mov al, bl
	out dx, al
	
	dec dl
	mov al, 0x0e
	out dx, al
	
	inc dl
	mov al, bh
	out dx, al
	ret
.newline:
	mov BYTE [cursor_x], 0
	inc BYTE [cursor_y]
	jmp .end
.backspace:
	mov al, [cursor_x]
	cmp al, 0
	jne .not_start
	mov BYTE [cursor_x], SCREEN_WIDTH - 1
	dec BYTE [cursor_y]
	jmp .cont
.not_start:
	dec BYTE [cursor_x]
.cont:
	mov eax, 0
	mov al, [cursor_y]
	mov ecx, SCREEN_WIDTH
	mul ecx
	mov cl, [cursor_x]
	add eax, ecx
	shl eax, 1
	add eax, VIDEO_MEMORY
	mov BYTE [eax], 0
	inc eax
	mov bl, [color]
	mov [eax], bl
	jmp .end


hex_chars:
	db "0123456789ABCDEF"
print_nybble:
	and eax, 0xff
	add eax, hex_chars
	mov eax, [eax]
	call print_char
	ret
print_byte:
	push eax
	shr al, 4
	call print_nybble
	pop eax
	and al, 0xf
	call print_nybble
	ret
print_int:
	; Switch color
	mov bl, [color]
	push ebx
	mov BYTE [color], 0x1f
	
	push eax
	shr eax, 24
	call print_byte
	mov eax, [esp]
	shr eax, 16
	and eax, 0xff
	call print_byte
	mov eax, [esp]
	shr eax, 8
	and eax, 0xff
	call print_byte
	pop eax
	and eax, 0xff
	call print_byte
	; Switch color back
	pop ebx
	mov [color], bl
	ret
print_str:
.loop:
	cmp BYTE [eax], 0
	je .end
	push eax
	mov eax, [eax]
	call print_char
	pop eax
	inc eax
	jmp .loop
.end:
	ret