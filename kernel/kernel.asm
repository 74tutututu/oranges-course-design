bits 32
org 0x10000

DATA_SELECTOR equ 0x10
DEBUG_PORT    equ 0xe9
EXIT_PORT     equ 0xf4

start:
	mov ax, DATA_SELECTOR
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x9f000
	cld

	mov esi, kernel_message
	mov edi, 0xb8000 + (4 * 80 * 2)
	mov ah, 0x0f

.print_character:
	lodsb
	test al, al
	jz .done
	out DEBUG_PORT, al
	mov [edi], ax
	add edi, 2
	jmp .print_character

.done:
	mov al, 13
	out DEBUG_PORT, al
	mov al, 10
	out DEBUG_PORT, al
	mov al, 0x10
	out EXIT_PORT, al

	cli
.halt:
	hlt
	jmp .halt

kernel_message: db 'Kernel OK', 0
