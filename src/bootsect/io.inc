; Print a NULL-terminated string to the screen.
; Input:
;   ESI	- Pointer to the start of the string.
; Output:
;   <none>
puts:
.lp:
	lodsb
    or al, al  ; zero=end of string
    jz .end    ; get out
    call putch
    jmp .lp
.end:
	ret
	
; Writes a byte to the serial port.
; Input:
;   AL - The byte to write.
swrite:
	mov ah, 0x01
	mov dx, PORT
	int 0x14
	ret
	
; Initializes the serial port.
sinit:
	mov ah, 0x00
	mov al, 0b11100011	; 9600 bps, no parity, 1 stop bit, 8 data bits
	mov dx, PORT
	int 0x14			; initialize serial
	ret
	
; Synchronously read a byte from the serial port.
; Output:
;   AL - The read byte.
sread:
	mov ah, 0x02
	mov dx, PORT
	int 0x14
	bt ax, 15
	jc sread
	out 0xE9, al
	ret
	
; Synchronously read a 16-bit integer from the serial port.
; Output:
;   AX - The 16-bit value.
sread16:
	push bx
	
	call sread
	mov bl, al
	call sread
	mov bh, al
	
	mov ax, bx
	pop bx
	ret

; Reads a file from the serial port.
; Input:
;   AX - Length of the file.
;   BX - Address where to load the file.
sreadfile:
	; bx: pointer to buffer
	; cx: countdown of length
	mov cx, ax
.lp:
	call sread
	mov byte [bx], al
	
	pusha
	call puthex
	popa
	
	inc bx
	dec cx
	jnz .lp
	ret

; Print a single ASCII character to the screen.
; Input:
;   AL - The character to print.
putch:
    mov ah, 0x0E
    int 0x10
    ret
	
putnewline:
	mov al, 0x0A
	call putch
	mov al, 0x0D
	call putch
	ret

; Print a hex number to the screen.
; Input:
;   AL - The byte to print.
puthex:
	; Do left nibble.
	and ax, 0xFF
	push ax

	xor bx, bx
	mov bl, al
	shr bl, 4
	and bl, 0x0F
	add bx, Hex

	mov al, [bx]
	call putch

	pop ax
	xor bx, bx
	mov bl, al
	and bl, 0x0F
	add bx, Hex

	mov al, [bx]
	call putch

	ret