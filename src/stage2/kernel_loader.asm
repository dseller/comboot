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
	mov al, 0b00110001	; request file 1, 32-bits mode
	call swrite32

	; Switch to high speed mode
	; call shighspeed

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

	hlt

welcome_pmode: db 'PMODE OK. ', 0
serial_inited: db 'COM1 OK. ', 0
done: db 'KERNEL OK. ', 0