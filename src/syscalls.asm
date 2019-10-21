SYSCALL_TEST equ 0x00
SYSCALL_GETCHAR equ 0x01

syscall_table:
	dd syscall_test
	dd syscall_getchar

int_syscall:
	shl eax, 2
	add eax, syscall_table
	call [eax]
	iret

syscall_test:
	mov eax, 0x69
	ret
syscall_getchar:
	;mov eax, 0x59
	;mov al, 0x20
	;out 0x20, al
	;call poll_keyboard
	mov BYTE [keyboard_buffer], 0
.loop:
	; Wait for next interrupt
	sti
	hlt
	cli
	cmp BYTE [keyboard_buffer], 0
	je .loop
	
	mov al, [keyboard_buffer]
	ret