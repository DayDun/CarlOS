key_table:
	db 0, 0, '1', '2', '3', '4', '5', '6'		; 00 - 07
	db '7', '8', '9', '0', '-', '=', 0x8, 0		; 08 - 0f
	db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i'	; 10 - 17
	db 'o', 'p', '[', ']', 0xa, 0, 'a', 's'		; 18 - 1f
	db 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';'	; 20 - 27
	db 0, '`', 0, 0, 'z', 'x', 'c', 'v'			; 28 - 2f
	db 'b', 'n', 'm', ',', '.', '/', 0, '*'		; 30 - 37
	db 0, ' ', 0, 0, 0, 0, 0, 0					; 38 - 3f
	db 0, 0, 0, 0, 0, 0, 0, '7'					; 40 - 47
	db '8', '9', '-', '+', '1', '2', '3', '0'	; 48 - 4f
	db '.', 0, 0, 0, 0, 0, 0, 0					; 50 - 57
key_table_shift:
	db 0, 0, '!', '@', '#', '$', '%', '^'
	db '&', '*', '(', ')', '_', '+', 0x8, 0
	db 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I'
	db 'O', 'P', '{', '}', 0xa, 0, 'A', 'S'
	db 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':'
	db 0, '~', 0, '|', 'Z', 'X', 'C', 'V'
	db 'B', 'N', 'M', '<', '>', '?', 0, '*'
	db 0, ' ', 0, 0, 0, 0, 0, 0
	db 0, 0, '-', 0, 0, 0, '+', 0


key_status:
	times 256 db 0

caps_lock:
	db 0

keyboard_buffer:
	db 0

poll_keyboard:
	in al, 0x64
	and al, 0b1
	cmp al, 1
	jne .end
	mov eax, 0
	in al, 0x60
	call key_event
.end:
	ret

key_event:
	mov ebx, eax
	and ebx, 0x80 ; Is this a key up event?
	cmp ebx, 0
	jne .up
	call key_down
	jmp .end
.up:
	call key_up
.end:
	ret

key_down:
	; Enable key flag
	mov ebx, eax
	add ebx, key_status
	mov BYTE [ebx], 1
	
	cmp al, 0x3a ; Is caps lock?
	jne .not_caps
	mov al, [caps_lock]
	xor al, 1
	mov BYTE [caps_lock], al
	ret
.not_caps:
	
	mov bl, [key_status + 0x2a] ; Left shift
	add bl, [key_status + 0x36] ; Right shift
	add bl, [caps_lock]
	cmp bl, 0
	jne .is_shift
	add eax, key_table
	jmp .cont
.is_shift:
	add eax, key_table_shift
.cont:
	mov al, [eax]
	
	cmp al, 0 ; Don't print control keys
	jne .print
	ret
.print:
	
	mov [keyboard_buffer], al
	;call print_char
	ret

key_up:
	; Disable key flag
	mov ebx, eax
	add ebx, key_status - 0x80
	mov BYTE [ebx], 0
	ret