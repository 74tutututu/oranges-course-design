bits 16
org 0x7c00

jmp short start
nop

; Standard 1.44 MB FAT12 BIOS Parameter Block.
bpb_oem_name:             db 'ORANGES '
bpb_bytes_per_sector:     dw 512
bpb_sectors_per_cluster:  db 1
bpb_reserved_sectors:     dw 1
bpb_fat_count:            db 2
bpb_root_entries:         dw 224
bpb_total_sectors:        dw 2880
bpb_media:                db 0xf0
bpb_sectors_per_fat:      dw 9
bpb_sectors_per_track:    dw 18
bpb_head_count:           dw 2
bpb_hidden_sectors:       dd 0
bpb_large_sector_count:   dd 0
boot_drive:               db 0
                           db 0
                           db 0x29
                           dd 0x20260818
                           db 'ORANGES M2 '
                           db 'FAT12   '

LOADER_SEGMENT  equ 0x9000
LOADER_OFFSET   equ 0x0100
FAT_BUFFER_SEG  equ 0x8000
ROOT_DIR_START  equ 19
ROOT_DIR_SECTORS equ 14
FAT_START       equ 1
DATA_SECTOR_DELTA equ 31
DEBUG_PORT      equ 0xe9
EXIT_PORT       equ 0xf4

start:
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00
	sti
	cld
	mov [boot_drive], dl

	mov ax, 0x0003
	int 0x10
	mov si, boot_message
	call print_string

	mov dl, [boot_drive]
	xor ah, ah
	int 0x13

	mov word [current_sector], ROOT_DIR_START
	mov cx, ROOT_DIR_SECTORS

.search_root_sector:
	push cx
	mov ax, LOADER_SEGMENT
	mov es, ax
	mov bx, LOADER_OFFSET
	mov ax, [current_sector]
	call read_sector

	mov di, LOADER_OFFSET
	mov dx, 16

.search_entry:
	mov si, loader_filename
	mov cx, 11
	push di
	repe cmpsb
	pop di
	je .loader_found
	add di, 32
	dec dx
	jnz .search_entry

	inc word [current_sector]
	pop cx
	loop .search_root_sector
	jmp loader_missing

.loader_found:
	pop cx
	mov ax, [es:di + 26]
	mov [current_cluster], ax
	mov ax, LOADER_SEGMENT
	mov es, ax
	mov bx, LOADER_OFFSET

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
	jae .loader_ready
	cmp ax, 2
	jb disk_error
	mov [current_cluster], ax
	jmp .load_cluster

.loader_ready:
	mov dl, [boot_drive]
	jmp LOADER_SEGMENT:LOADER_OFFSET

loader_missing:
	mov si, loader_missing_message
	call print_string
	mov al, 0x11
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

; Read LBA AX into ES:BX using the floppy CHS geometry.
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

; Return the 12-bit FAT entry for cluster AX in AX.
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

loader_filename:       db 'LOADER  BIN'
boot_message:          db 'OrangeS Course Design', 13, 10, 'Boot OK', 13, 10, 0
loader_missing_message: db 'Loader Missing', 13, 10, 0
disk_error_message:    db 'Disk Error', 13, 10, 0
current_sector:        dw 0
current_cluster:       dw 0

times 510 - ($ - $$) db 0
dw 0xaa55
