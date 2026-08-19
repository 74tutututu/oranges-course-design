bits 32

section .text

global out_byte
global in_byte
global enable_int
global disable_int

out_byte:
	mov edx, [esp + 4]
	mov eax, [esp + 8]
	out dx, al
	ret

in_byte:
	mov edx, [esp + 4]
	xor eax, eax
	in al, dx
	ret

enable_int:
	sti
	ret

disable_int:
	cli
	ret

section .note.GNU-stack noalloc noexec nowrite progbits
