[org 0x7C00]

%define NEWLINE 	0x0A
%define PORT 		0
%define MEM_START 	0x7E00	; Starting address of where to put the kernel.

_entry:
	xor ax, ax
	mov ds, ax

	mov al, NEWLINE
	call putch
	call putch
	mov si, welcome
	call puts
	
	; initialize serial port
	call sinit
	
	; write id packet
	mov al, 0b00010001	; opcode 1, no hi-mem
	call swrite
	
	; read server id packet
	call sread
	
	; see if it is opcode 1 (0b00010000)
	and al, 0b00010000
	jz unexpected_pkt
	
	; read id string
	xor bx, bx
.lp:
	call sread
	mov byte [bx+srv_id], al
	inc bx
	cmp bx, 8
	jl .lp
	
	mov esi, srv_id
	call puts
	call putnewline
	
	; request stage 2
	mov al, 0b00100000	; request file, 16-bits mode, ID 0
	call swrite
	
	; read the file length, and then read the file into RAM
	call sread16
	mov bx, MEM_START
	call sreadfile
	
	jmp MEM_START
		
	; should not reach this
	; panic with error FF when reaching here.
	mov al, 0xFF
	call panic
	
unexpected_pkt:
	mov al, 0x02
	call panic

; Panics the system.
; Input:
;   AL - Error code.
; Error codes:
;   01 - Error in packet transfer.
;   FF - Boot loader ended prematurely.
panic:
	mov bl, al
	call putnewline
	call putnewline
	mov esi, panictxt
	call puts
	mov al, bl
	call puthex
	cli
	hlt	

%include "io.inc"
	
welcome: db 'hi! ',0
panictxt: db 'panic: ',0
srv_id: times 9 db 0
Hex: db '0123456789ABCDEF'

; boot sector signature
times 510-($-$$) db 0
db 0x55
db 0xAA
