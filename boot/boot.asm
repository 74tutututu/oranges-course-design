bits 16
org 0x7c00

VIDEO_INTERRUPT   equ 0x10
TEXT_MODE         equ 0x0003
TELETYPE_FUNCTION equ 0x0e
TEXT_ATTRIBUTE    equ 0x07
DEBUG_PORT        equ 0xe9

start:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00
	sti
	cld

	; Start from a predictable 80x25 text screen.
	mov ax, TEXT_MODE
	int VIDEO_INTERRUPT

	mov si, boot_message

.print_character:
	lodsb
	test al, al
	jz .halt

	; Port 0xe9 is captured by QEMU during automated boot tests.
	out DEBUG_PORT, al
	mov ah, TELETYPE_FUNCTION
	mov bh, 0
	mov bl, TEXT_ATTRIBUTE
	int VIDEO_INTERRUPT
	jmp .print_character

.halt:
	cli

.halt_loop:
	hlt
	jmp .halt_loop

boot_message:
	db 'OrangeS Course Design', 13, 10
	db 'Boot OK', 13, 10, 0

times 510 - ($ - $$) db 0
dw 0xaa55
