[org 0x7E00]
use16
%define PORT 		0

	; Print a stage2 welcome message.
	call putnewline
	call putnewline
	mov esi, stage2_welcome
	call puts

	; 1. enable A20 line
	call do_a20
	call check_a20
	cmp ax, 1
	je a20ok
	mov esi, a20_failed
	call puts
	cli
	hlt
a20ok:
	mov esi, a20_enabled
	call puts

	; 2. load GDT
	call do_gdt

	; 3. enable PMode and jump to protected code
	cli
	mov eax, cr0
	or al, 1
	mov cr0, eax
	jmp 0x08:kloader

do_gdt:
	lgdt [gdtr]
	mov esi, gdt_loaded
	call puts
	ret

do_a20:
	; enable A20 line (using the easy shortcut method ;-))
	; see also: https://www.win.tue.nl/~aeb/linux/kbd/A20.html
	in al, 0x92
	test al, 2
	jnz a20_end
	or al, 2
	and al, 0xFE
	out 0x92, al
	a20_end:
	ret

check_a20:
    pushf
    push ds
    push es
    push di
    push si
    cli
    xor ax, ax ; ax = 0
    mov es, ax
    not ax ; ax = 0xFFFF
    mov ds, ax
    mov di, 0x0500
    mov si, 0x0510
    mov al, byte [es:di]
    push ax
    mov al, byte [ds:si]
    push ax
    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF
    cmp byte [es:di], 0xFF
    pop ax
    mov byte [ds:si], al
    pop ax
    mov byte [es:di], al
    mov ax, 0
    je check_a20__exit
    mov ax, 1
check_a20__exit:
    pop si
    pop di
    pop es
    pop ds
    popf
    ret

a20_enabled: db ' * A20 OK', 0x0a, 0x0d, 0x00
a20_failed: db ' * A20 FAIL', 0x0a, 0x0d, 0x00
gdt_loaded:  db ' * GDT OK', 0x0a, 0x0d, 0x00
stage2_welcome: db 'Welcome to COMBOOT stage2!', 0x0a, 0x0d, 0x00
Hex: db '0123456789ABCDEF'
%include "../bootsect/io.inc"

; ---------- 32 bits code starts here -------------
use32

gdtr:
	dw (gdt_end-gdt)+1
	dd gdt

gdt:
	; NULL descriptor
	dq 0

	; default code descriptor
	dw 0xFFFF		; limit 0xFFFF
	dw 0x0000		; base lo 0x0000
	db 0x00			; base mid 0x00
	db 0b10011010   ; present, ring0, executable, non-conforming, readable
	db 0b11001111	; 4KB granularity, 32-bits, upper nibble for limit
	db 0x00			; base hi 0x00

	; default data descriptor
	dw 0xFFFF		; limit 0xFFFF
	dw 0x0000		; base lo 0x0000
	db 0x00			; base mid 0x00
	db 0b10010010	; present, ring0, data, growing, writable
	db 0b11001111	; 4KB granularity, 32-bits, upper nibble for limit
	db 0x00			; base hi 0x00
gdt_end:

%include "kernel_loader.asm"