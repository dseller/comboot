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

	hlt

welcome_pmode: db 'Entered protected mode.', 0
