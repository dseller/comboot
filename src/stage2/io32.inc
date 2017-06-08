%define VGA_BASE 0xB8000
%define VGA_COLOR 0b00000010

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
	jmp .lp
.end:
	; update the 'cur' variable.
	mov dword [vga_ptr], ebx
	ret