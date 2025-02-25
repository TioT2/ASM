; CRACKME .ASM

.model tiny
.286

.code

locals ??
org 100h

; Start function
start proc
	; Input to password buffer
	mov di, offset password_buffer
	call input_password

	; Print password string
	mov ah, 09h
	mov dx, offset password_buffer
	int 21h

	; Calculate password hash

	; bx = password length
	mov bx, di
	sub bx, offset password_buffer + 1
	mov si, offset password_buffer
	call get_password_hash


	mov ax, word ptr [offset password_hash]
	cmp cx, ax
	jne ??deny

	mov ax, word ptr [offset password_hash + 2]
	cmp dx, ax
	jne ??deny

??allow:
	mov ah, 09h
	mov dx, offset string_access_undenied
	int 21h
	jmp ??end

??deny:
	; Print 'access denied('
	mov ah, 09h
	mov dx, offset string_access_denied
	int 21h
	jmp ??end

??end:
	; Exit with 00h code
	mov ax, 4C00h
	int 21h
	ret
endp

; Input password from cmd
; IN:
;	password dst - ES:DI
; USES:
;	AX
;	DI (=[password end ptr])
input_password proc
??continue:
	mov ah, 01h
	int 21h
	stosb
	cmp al, 0Dh
	jne ??continue

	; Write '$' instead of
	dec di
	mov al, 24h
	stosb 
	ret
endp

; Calculate password hash
; IN:
;	password ptr    - DS:SI
;	password length - BX
; OUT:
;	CX, DX - hash.
; USES:
;	AX
;	BX (= 0)
;	CX (RET)
;	DX (RET)
get_password_hash proc
	; Initialize CX with 1 and DX with 0
	xor cx, cx
	inc cx
	xor dx, dx

	xor ax, ax

	jmp ??test
??continue:
	; decrement bx
	dec bx

	; S1 - CX
	; S2 - DX

	lodsb

	; cx = (cx + ax)
	; if cx > 65521: cx -= 65521;
	add cx, ax
	cmp cx, 65521
	jb ??cx_sub
	sub cx, 65521
??cx_sub:

	add dx, cx
	cmp dx, 65521
	jb ??dx_sub
	sub dx, 65521
??dx_sub:

??test:
	test bx, bx
	jnz ??continue

	; End execution
	ret
endp

password_buffer db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
password_hash dw 028Dh, 08BBh
string_access_denied db "access denied($"
string_access_undenied db "access undenied)$"

end start

; crackme.asm