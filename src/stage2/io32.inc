%define VGA_BASE	0xB8000
%define VGA_END		VGA_BASE + (80*25*2)
%define VGA_COLOR	0b00000010
%define COM_PORT	0x3F8

vga_ptr: dd VGA_BASE

; Writes a NULL-terminated string to the screen.
; Input
;   ESI - Pointer to string.
puts32:
	mov ebx, dword [vga_ptr]
.lp:
	lodsb
	mov byte [ebx], al
	mov byte [ebx+1], VGA_COLOR
	inc ebx
	inc ebx
	or al, al
	jz .end

	cmp ebx, VGA_END
	jl .lp
	; we have crossed the boundary!
	mov ebx, VGA_BASE
	jmp .lp
.end:
	; update the 'cur' variable.
	mov dword [vga_ptr], ebx
	ret

; Writes a character to the screen.
; Input
;   AL - The character.
putch32:
	mov ebx, dword [vga_ptr]
	mov byte [ebx], al
	mov byte [ebx+1], VGA_COLOR
	inc ebx
	inc ebx
	cmp ebx, VGA_END
	jl .end
	mov ebx, VGA_BASE
.end:
	mov dword [vga_ptr], ebx
	ret

; Initializes the serial port (COM1).
sinit32:
	; Disable interrupts
	mov al, 0x00
	mov dx, COM_PORT+1
	out dx, al

	; Set 9600 bauds.
	call snormalspeed

	; 8 bits, no parity, 1 stop bit
	mov al, 0x03
	mov dx, COM_PORT+3
	out dx, al

	; Enable FIFO
	mov al, 0xC7
	mov dx, COM_PORT+2
	out dx, al

	ret

; Switch the serial port to high-speed (115200 bauds).
shighspeed:
	; Wait until THR is empty and line is idle.
	mov dx, COM_PORT+5
.lp:
	in al, dx
	and al, 0b01000000
	jz .lp

	; Set baud rate divisor to 115200 baud (divisor 1)
	mov al, 0x80
	mov dx, COM_PORT+3
	out dx, al
	mov al, 0x01
	mov dx, COM_PORT+0
	out dx, al
	mov al, 0x00
	mov dx, COM_PORT+1
	out dx, al
	ret

; Switch the serial port to normal speed (9600 bauds).
snormalspeed:
	; Set baud rate divisor to 9600 baud (divisor 12)
	mov al, 0x80
	mov dx, COM_PORT+3
	out dx, al
	mov al, 0x0C
	mov dx, COM_PORT+0
	out dx, al
	mov al, 0x00
	mov dx, COM_PORT+1
	out dx, al
	ret

; Write a byte to the serial port (COM1).
; Input:
;   AL - The byte to write.
swrite32:
	; Wait until it is ready to write.
	mov cl, al
	mov dx, COM_PORT+5
.lp:
	in al, dx
	and al, 0x20
	jz .lp
	
	mov dx, COM_PORT
	mov al, cl
	out dx, al

	ret

; Read a byte from the serial port (COM1).
; Output:
;  AL - The byte.
sread32:
	; Wait until data is available.
	mov dx, COM_PORT+5
.lp:
	in al, dx
	and al, 0x01
	jz .lp

	mov dx, COM_PORT
	in al, dx

	ret

; Read a 32-bit integer from the serial port (COM1).
; Output:
;   EAX - The value.
sread3232:
	xor eax, eax
	xor ecx, ecx

	call sread32
	mov cl, al
	
	xor eax, eax
	call sread32
	shl eax, 8
	or ecx, eax

	xor eax, eax
	call sread32
	shl eax, 16
	or ecx, eax

	xor eax, eax
	call sread32
	shl eax, 24
	or ecx, eax

	mov eax, ecx
	ret

; Reads a file from the serial port.
; Input:
;   EAX - Length of the file.
;   EBX - Address where to load the file.
sreadfile32:
	; ebx: pointer to buffer
	; ecx: countdown of length
	mov ecx, eax
.lp:
	call sread32
	mov byte [ebx], al
	
	pusha
	call puthex32
	popa
	
	inc ebx
	dec ecx
	jnz .lp
	ret

; Print a hex number to the screen.
; Input:
;   AL - The byte to print.
puthex32:
	; Do left nibble.
	and ax, 0xFF
	push ax

	xor bx, bx
	mov bl, al
	shr bl, 4
	and bl, 0x0F
	add bx, Hex

	mov al, [bx]
	call putch32

	pop ax
	xor bx, bx
	mov bl, al
	and bl, 0x0F
	add bx, Hex

	mov al, [bx]
	call putch32

	ret

puthex3232:
	