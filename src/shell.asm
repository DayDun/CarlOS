welcome:
	db `Welcome to CarlOS\n`, 0

prompt:
	db "> ", 0

line_buffer_index:
	dd line_buffer
line_buffer:
	times 0x100 db 0

shell_start:
	; Print welcome
	mov eax, welcome
	call print_str
	
.loop:
	mov eax, prompt
	call print_str
	
	call read_line
	mov eax, `\n`
	call print_char
	
	;mov eax, line_buffer
	;call print_str
	
	mov eax, command_table
.cmd_loop:
	mov ebx, [eax]
	cmp ebx, 0
	je .cmd_loop_end
	push eax
	mov eax, line_buffer
	call str_cmp
	pop eax
	add eax, 4
	cmp edx, 1
	jne .cmd_loop
	
	inc ebx
	call ebx
.cmd_loop_end:
	jmp .loop
	
.end:
	hlt
	jmp .end



read_line:
	mov DWORD [line_buffer_index], line_buffer
.loop:
	mov eax, SYSCALL_GETCHAR
	int 0x80
	cmp al, `\n`
	je .newline
	
	mov ebx, [line_buffer_index]
	mov [ebx], al
	inc DWORD [line_buffer_index]
	call print_char
	jmp .loop
.newline:
	mov ebx, [line_buffer_index]
	mov BYTE [ebx], 0
	ret


; Input:	eax = strA, ebx = strB
; Output:	edx = equal
str_cmp:
	mov edx, 0
.loop:
	mov cl, [eax]
	cmp cl, 0
	je .end
	mov ch, [ebx]
	;cmp ch, 0
	;je .end
	cmp cl, ch
	jne .not_equal
	inc eax
	inc ebx
	mov edx, 1
	jmp .loop
.not_equal:
	mov edx, 0
.end:
	ret


command_table:
	dd command_help
	dd command_other
	dd 0

command_help:
	db "help", 0
	mov eax, .help
	call print_str
	ret
.help:
	db `This is the help menu!\n`, 0

command_other:
	db "other", 0
	mov eax, .other
	call print_str
	ret
.other:
	db `This is the other command!\n`, 0