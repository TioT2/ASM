; Comment
'''asm
.model tiny

; .186 - allow numeric push. It was impossible on .086 architecture.

.data
String db "Hello world!!!1!$"

.code
org 100h

VIDEOSEG equ 0b800h


; Inputs:
;	bx - pixel location
; Uses:
;	ax, bx, es
EnCh: proc
	mov ax, VIDEOSEG
	mov es, ax

	mov byte ptr es:[bx], 0Fh

	ret
endp

Start:
	; Set 13 video mode
	mov ax, 0013h
	int 10h

	mov bx, 0
	call EnCh
	ret

end Start