; ACE.ASM

.model tiny
.286

.code
org 100h

locals ??

; Main function
start proc
	; Write arbitrary code itself
	mov dx, offset arbitrary_string + 97h
        mov ah, 09h
        int 21h

	; Exit
	mov ax, 4C00h
	int 21h

	; Local constants
	arbitrary_string db "Arbitrary code executed)$"
endp

end start
