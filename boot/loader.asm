bits 16
org 0x0100

LOADER_PHYSICAL_BASE equ 0x90000
KERNEL_SEGMENT       equ 0x1000
KERNEL_OFFSET        equ 0x0000
KERNEL_ADDRESS       equ 0x10000
FAT_BUFFER_SEG       equ 0x7000
ROOT_DIR_START       equ 19
ROOT_DIR_SECTORS     equ 14
FAT_START            equ 1
DATA_SECTOR_DELTA    equ 31
CODE_SELECTOR        equ 0x08
DATA_SELECTOR        equ 0x10
DEBUG_PORT           equ 0xe9
EXIT_PORT            equ 0xf4

start:
	cli
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x0100
	sti
	cld
	mov [boot_drive], dl

	mov si, loader_message
	call print_string

	mov word [current_sector], ROOT_DIR_START
	mov cx, ROOT_DIR_SECTORS

.search_root_sector:
	push cx
	mov ax, FAT_BUFFER_SEG
	mov es, ax
	xor bx, bx
	mov ax, [current_sector]
	call read_sector

	xor di, di
	mov dx, 16

.search_entry:
	mov si, kernel_filename
	mov cx, 11
	push di
	repe cmpsb
	pop di
	je .kernel_found
	add di, 32
	dec dx
	jnz .search_entry

	inc word [current_sector]
	pop cx
	loop .search_root_sector
	jmp kernel_missing

.kernel_found:
	pop cx
	mov ax, [es:di + 26]
	mov [current_cluster], ax
	mov ax, KERNEL_SEGMENT
	mov es, ax
	xor bx, bx

.load_cluster:
	mov ax, [current_cluster]
	add ax, DATA_SECTOR_DELTA
	call read_sector
	add bx, 512

	mov ax, [current_cluster]
	call get_fat_entry
	cmp ax, 0xff7
	je disk_error
	cmp ax, 0xff8
	jae .kernel_ready
	cmp ax, 2
	jb disk_error
	mov [current_cluster], ax
	jmp .load_cluster

.kernel_ready:
	mov dx, 0x03f2
	xor al, al
	out dx, al

	cli
	in al, 0x92
	or al, 0x02
	and al, 0xfe
	out 0x92, al

	lgdt [gdt_descriptor]
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp dword CODE_SELECTOR:(LOADER_PHYSICAL_BASE + protected_mode)

kernel_missing:
	mov si, kernel_missing_message
	call print_string
	mov al, 0x12
	out EXIT_PORT, al
	jmp halt

disk_error:
	mov si, disk_error_message
	call print_string
	mov al, 0x13
	out EXIT_PORT, al

halt:
	cli
.loop:
	hlt
	jmp .loop

read_sector:
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push bp
	mov di, ax
	mov bp, bx
	mov si, 3

.retry:
	mov ax, di
	xor dx, dx
	mov cx, 18
	div cx
	inc dl
	mov cl, dl
	xor dx, dx
	mov bx, 2
	div bx
	mov dh, dl
	mov ch, al
	mov dl, [boot_drive]
	mov bx, bp
	mov ax, 0x0201
	int 0x13
	jnc .done

	mov dl, [boot_drive]
	xor ah, ah
	int 0x13
	dec si
	jnz .retry
	jmp disk_error

.done:
	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

get_fat_entry:
	push bx
	push cx
	push dx
	push es
	mov bx, 3
	mul bx
	mov bx, 2
	div bx
	push dx
	xor dx, dx
	mov bx, 512
	div bx
	push dx
	add ax, FAT_START
	mov bx, FAT_BUFFER_SEG
	mov es, bx
	xor bx, bx
	call read_sector
	inc ax
	mov bx, 512
	call read_sector
	pop bx
	mov ax, [es:bx]
	pop dx
	test dl, 1
	jz .even
	shr ax, 4
.even:
	and ax, 0x0fff
	pop es
	pop dx
	pop cx
	pop bx
	ret

print_string:
	push ax
	push bx
.next:
	lodsb
	test al, al
	jz .done
	out DEBUG_PORT, al
	mov ah, 0x0e
	xor bh, bh
	mov bl, 0x07
	int 0x10
	jmp .next
.done:
	pop bx
	pop ax
	ret

align 8
gdt_start:
	dq 0
gdt_code:
	dw 0xffff, 0x0000
	db 0x00, 0x9a, 0xcf, 0x00
gdt_data:
	dw 0xffff, 0x0000
	db 0x00, 0x92, 0xcf, 0x00
gdt_end:

gdt_descriptor:
	dw gdt_end - gdt_start - 1
	dd LOADER_PHYSICAL_BASE + gdt_start

kernel_filename:        db 'KERNEL  BIN'
loader_message:         db 'Loader OK', 13, 10, 0
kernel_missing_message: db 'Kernel Missing', 13, 10, 0
disk_error_message:     db 'Disk Error', 13, 10, 0
protected_message:      db 'Protected Mode OK', 0
boot_drive:             db 0
current_sector:         dw 0
current_cluster:        dw 0

bits 32
protected_mode:
	mov ax, DATA_SELECTOR
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x9f000
	cld

	mov esi, LOADER_PHYSICAL_BASE + protected_message
	mov edi, 0xb8000 + (3 * 80 * 2)
	call print_protected_string
	mov al, 13
	out DEBUG_PORT, al
	mov al, 10
	out DEBUG_PORT, al

	jmp dword CODE_SELECTOR:KERNEL_ADDRESS

print_protected_string:
	mov ah, 0x0a
.next:
	lodsb
	test al, al
	jz .done
	out DEBUG_PORT, al
	mov [edi], ax
	add edi, 2
	jmp .next
.done:
	ret
