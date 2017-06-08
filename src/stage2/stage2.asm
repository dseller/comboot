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

; 2. load GDT
call do_gdt

; 3. enable PMode and jump to protected code
cli
mov eax, cr0
or al, 1
mov cr0, eax
jmp 0x08:pmode

; Don't CLI because we want interrupts to ctrl-alt-del.
idle:
	hlt
	jmp idle

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
	mov esi, a20_enabled
	call puts
	ret

a20_enabled: db ' * A20 OK', 0x0a, 0x0d, 0x00
gdt_loaded:  db ' * GDT OK', 0x0a, 0x0d, 0x00
stage2_welcome: db 'Welcome to COMBOOT stage2!', 0x0a, 0x0d, 0x00
Hex: db '0123456789ABCDEF'
%include "../bootsect/io.inc"

; ---------- 32 bits code starts here -------------
use32

dd 0xCAFEBABE
dd 0xCAFEBABE
dd 0xCAFEBABE

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
	db 0x4F			; 4KB granularity, 32-bits, upper nibble for limit
	db 0x00			; base hi 0x00

	; default data descriptor
	dw 0xFFFF		; limit 0xFFFF
	dw 0x0000		; base lo 0x0000
	db 0x00			; base mid 0x00
	db 0b10010010	; present, ring0, data, growing, writable
	db 0x4F			; 4KB granularity, 32-bits, upper nibble for limit
	db 0x00			; base hi 0x00
gdt_end:

pmode:
	; setup data selectors and stack
	mov eax, 0x10
	mov ds, eax
	mov es, eax
	mov fs, eax
	mov gs, eax
	mov ss, eax
	mov esp, 0x90000
	
	mov eax, 0xb8000
	mov byte [eax], 'A'

	hlt
