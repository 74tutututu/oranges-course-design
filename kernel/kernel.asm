bits 32

section .text

extern kernel_main
extern irq_dispatch
extern exception_dispatch
extern p_proc_ready

global kernel_entry
global start_first_process
global exception_stub_table
global irq_stub_table

kernel_entry:
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x9f000
	cld
	call kernel_main

.idle:
	hlt
	jmp .idle

; Enter the first task from a pre-built interrupt-return frame.
start_first_process:
	mov eax, [p_proc_ready]
	mov esp, [eax]
	pop gs
	pop fs
	pop es
	pop ds
	popad
	add esp, 4
	iretd

%macro EXCEPTION_NO_ERROR 1
global exception%1
exception%1:
	push dword %1
	jmp exception_common_no_error
%endmacro

%macro EXCEPTION_WITH_ERROR 1
global exception%1
exception%1:
	push dword %1
	jmp exception_common_with_error
%endmacro

exception_common_no_error:
	cld
	pushad
	push dword [esp + 32]
	call exception_dispatch
	add esp, 4
	popad
	add esp, 4
	iretd

exception_common_with_error:
	cld
	pushad
	push dword [esp + 32]
	call exception_dispatch
	add esp, 4
	popad
	add esp, 8
	iretd

EXCEPTION_NO_ERROR 0
EXCEPTION_NO_ERROR 1
EXCEPTION_NO_ERROR 2
EXCEPTION_NO_ERROR 3
EXCEPTION_NO_ERROR 4
EXCEPTION_NO_ERROR 5
EXCEPTION_NO_ERROR 6
EXCEPTION_NO_ERROR 7
EXCEPTION_WITH_ERROR 8
EXCEPTION_NO_ERROR 9
EXCEPTION_WITH_ERROR 10
EXCEPTION_WITH_ERROR 11
EXCEPTION_WITH_ERROR 12
EXCEPTION_WITH_ERROR 13
EXCEPTION_WITH_ERROR 14
EXCEPTION_NO_ERROR 15
EXCEPTION_NO_ERROR 16
EXCEPTION_WITH_ERROR 17
EXCEPTION_NO_ERROR 18
EXCEPTION_NO_ERROR 19
EXCEPTION_NO_ERROR 20
EXCEPTION_NO_ERROR 21
EXCEPTION_NO_ERROR 22
EXCEPTION_NO_ERROR 23
EXCEPTION_NO_ERROR 24
EXCEPTION_NO_ERROR 25
EXCEPTION_NO_ERROR 26
EXCEPTION_NO_ERROR 27
EXCEPTION_NO_ERROR 28
EXCEPTION_NO_ERROR 29
EXCEPTION_WITH_ERROR 30
EXCEPTION_NO_ERROR 31

global irq0
irq0:
	push dword 0
	jmp irq_common

global irq1
irq1:
	push dword 1
	jmp irq_common

global irq_default
irq_default:
	push dword 0xff

irq_common:
	cld
	pushad
	xor eax, eax
	mov ax, ds
	push eax
	xor eax, eax
	mov ax, es
	push eax
	xor eax, eax
	mov ax, fs
	push eax
	xor eax, eax
	mov ax, gs
	push eax
	mov eax, [p_proc_ready]
	mov [eax], esp
	push dword [esp + 48]
	call irq_dispatch
	add esp, 4
	mov ecx, [esp + 48]
	cmp ecx, 8
	jb .master_eoi
	mov al, 0x20
	out 0xa0, al
.master_eoi:
	mov al, 0x20
	out 0x20, al
	mov eax, [p_proc_ready]
	mov esp, [eax]
	pop gs
	pop fs
	pop es
	pop ds
	popad
	add esp, 4
	iretd

section .data

exception_stub_table:
	dd exception0, exception1, exception2, exception3
	dd exception4, exception5, exception6, exception7
	dd exception8, exception9, exception10, exception11
	dd exception12, exception13, exception14, exception15
	dd exception16, exception17, exception18, exception19
	dd exception20, exception21, exception22, exception23
	dd exception24, exception25, exception26, exception27
	dd exception28, exception29, exception30, exception31

irq_stub_table:
	dd irq0, irq1, irq_default, irq_default
	dd irq_default, irq_default, irq_default, irq_default
	dd irq_default, irq_default, irq_default, irq_default
	dd irq_default, irq_default, irq_default, irq_default

section .note.GNU-stack noalloc noexec nowrite progbits
