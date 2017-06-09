%include "io32.inc"

kloader:
	; setup data selectors and stack
	mov eax, 0x10
	mov ds, eax
	mov es, eax
	mov fs, eax
	mov gs, eax
	mov ss, eax
	mov esp, 0x90000
	
	mov esi, welcome_pmode
	call puts32

	; Initialize serial port COM1
	call sinit32
	mov esi, serial_inited
	call puts32

	; Request kernel image (file 1)
	mov al, 0b00111001	; request file 1, 32-bits mode
	call swrite32

	; Switch to high speed mode
	call shighspeed

	; Test: read 32-bits size field
	call sread3232
	mov edx, eax

	; Load to 1MB mark.
	mov ebx, 0x100000
	call sreadfile32

	mov esi, done
	call puts32

	mov al, byte [0x100000]
	call puthex32

	; quick workaround :D
	; TODO: parse multiboot header
	; TODO: get memory map and size
	mov eax, 0x2BADB002
	mov ebx, multiboot_info
	jmp 0x100420

	hlt

welcome_pmode: db 'PMODE OK. ', 0
serial_inited: db 'COM1 OK. ', 0
done: db 'KERNEL OK. ', 0
bootloader: db 'COMBOOT Boot Loader 0.1', 0

multiboot_info:
	dd 0b1001000001		; 0  meminfo, memory map, boot loader name
	dd 640				; 4  640KB lower memory
	dd 32768			; 8  32 MB upper memory
	dd 0				; 12 boot device
	dd 0				; 16 cmd line
	dd 0				; 20 mods
	dd 0				; 24 mods address
	dd 0				; 28 syms
	dd 0				; 32 syms
	dd 0				; 36 syms
	dd 0				; 40 syms
	dd 20				; 44 mmap length
	dd mmap				; 48 mmap ptr
	dd 0				; 52 drives len
	dd 0				; 56 drives addr
	dd 0				; 60 config table
	dd bootloader		; 64 bootloader

mmap:
	dd 0				; base addr upper
	dd 0x100000			; base addr lower
	dd 0				; size upper
	dd 0x2000000		; size lower
	db 1				; available