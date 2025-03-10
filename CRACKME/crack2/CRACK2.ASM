; CRACK2.ASM

.model tiny
.286

.code

locals ??
org 100h

; Start function
start proc

	push cs
	pop ax
	mov bx, 016Fh
	mov [bx], ax

	db 09Ah
	dst_ptr dw 019Dh
	dst_seg dw 0000h

	mov ax, 4C00h
	int 21h
	ret
endp

end start

; CRACK2.ASM
