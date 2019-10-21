;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      ;;
;;        CarlOS        ;;
;;                      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

bits 32

section .multiboot
	MAGIC equ 0x1BADB002
	FLAGS equ 0x00
	CHECKSUM equ -(MAGIC + FLAGS)

	dd MAGIC
	dd FLAGS
	dd CHECKSUM

section .text
global kernel_start
kernel_start:
	cli ;block interrupts
	mov esp, stack_space ;set stack pointer
	call kernel_init_gdt
	call kernel_init_idt
	call kernel_init_pic
	sti
	
	call clear_screen
	
	call kernel_sanity
	mov eax, `\n`
	call print_char
	
	mov eax, 0xc001b0bb
	call print_int
	mov eax, ' '
	call print_char
	mov eax, SYSCALL_TEST
	int 0x80
	call print_int
	
	mov eax, `\n`
	call print_char
	call shell_start
	
.end:
	hlt
	jmp .end

; Make sure the system isn't fucked
kernel_sanity:
	; Print CPU vendor id
	mov eax, 0
	cpuid
	push 0
	push ecx
	push edx
	push ebx
	mov eax, esp
	call print_str
	add esp, 16
	
	; Get CPU flags
	mov eax, 1
	cpuid
	mov eax, edx
	and eax, 0x200 ; APIC enabled flag
	jz panic
	mov eax, edx
	and eax, 0x20 ; MSR enabled flag
	jz panic
	
	mov eax, fine_text
	call print_str
	ret
fine_text:
	db " - everything appears to be fine.", 0

panic_text:
	db "System encountered an unexpected problem.", 0
panic:
	mov eax, panic_text
	call print_str
	jmp $

;;;;;;;;;;;;;;;
;     GDT
;;;;;;;;;;;;;;;

gdtr:
	dw gdt_end - gdt - 1
	dd gdt
gdt:
	; null descriptor
	dq 0
	
	; code
	dw 0xffff
	dw 0
	db 0
	db 0x9a
	db 0b11001111
	db 0
	
	; data
	dw 0xffff
	dw 0
	db 0
	db 0x92
	db 0b11001111
	db 0
gdt_end:
kernel_init_gdt:
	lgdt [gdtr]
	ret

;;;;;;;;;;;;;;;;;;
;      IDT
;;;;;;;;;;;;;;;;;;

idtr:
	dw idt_end - idt - 1
	dd idt
idt:
	times 256 dq 0
idt_end:

; eax = interrupt, ebx = routine pointer
idt_set_int:
	shl eax, 3
	add eax, idt
	
	mov ecx, ebx
	mov [eax], cx			; Offset 0-15
	add eax, 2
	mov WORD [eax], 0x8		; Selector
	add eax, 2
	mov BYTE [eax], 0		; Unused
	add eax, 1
	mov BYTE [eax], 0x8e	; Flags
	add eax, 1
	shr ecx, 16
	mov [eax], cx			; Offset 16-31
	ret

kernel_init_idt:
	lidt [idtr]
	
;	mov eax, 255
;.loop:
;	push eax
;	mov ebx, test_int
;	call idt_set_int
;	pop eax
;	dec eax
;	cmp eax, 0
;	jge .loop
	
	mov eax, 0
	mov ebx, int_divide_by_zero
	call idt_set_int
	
	mov eax, 8
	mov ebx, int_double_fault
	call idt_set_int
	
	mov eax, 0xd
	mov ebx, int_general_protection_fault
	call idt_set_int
	
	mov eax, 0x21
	mov ebx, int_keyboard
	call idt_set_int
	
	mov eax, 0x80
	mov ebx, int_syscall
	call idt_set_int
	
	ret

int_divide_by_zero:
	pushad
	mov eax, .exception
	call print_str
	popad
	;iret ; should handle exception
	jmp $
.exception:
	db "Exception: Divide by zero", 0

int_double_fault:
	mov eax, .exception
	call print_str
	jmp $
.exception:
	db "Exception: Double fault", 0

int_general_protection_fault:
	mov eax, .exception
	call print_str
	hlt
.exception:
	db "Exception: General protection fault", 0

int_keyboard:
	pusha
	call poll_keyboard
	mov al, 0x20
	out 0x20, al
	popa
	iret


kernel_init_pic:
	mov al, 0x10 | 0x01
	out 0x20, al
	out 0xa0, al
	mov al, 0x20 ; Master PIC offset
	out 0x21, al
	mov al, 0x28 ; Slave PIC offset
	out 0xa1, al
	mov al, 4
	out 0x21, al
	mov al, 2
	out 0xa1, al
	mov al, 0x01
	out 0x21, al
	out 0xa1, al
	
	; Mask keyboard only
	mov al, 0xfd
	out 0x21, al
	mov al, 0xff
	out 0xa1, al
	ret


%include "src/syscalls.asm"
%include "src/video.asm"
%include "src/keyboard.asm"
%include "src/shell.asm"


section .bss
resb 8192                ;8KB for stack
stack_space: