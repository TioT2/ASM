; CRACKME .ASM

.model tiny
.286

.code

locals ??
org 100h

; Start function
start proc
	call login

	; Exit with 00h code
	mov ax, 4C00h
	int 21h
	ret
endp

; Login function
login proc
	; Input to password buffer
	mov di, offset password_buffer
	call input_password

	; Find password string end
	mov si, offset password_buffer
	call find_string_end
	sub si, offset password_buffer
	dec si
	mov bx, si
	mov si, offset password_buffer
	call get_password_hash

	; UUGH, shitcode
	mov bx, offset correct_password_hash
	mov bx, [bx]
	cmp cx, bx
	jne ??deny

	mov bx, offset correct_password_hash + 2
	mov bx, [bx]
	cmp dx, bx
	jne ??deny

??allow:
	call print_allowed
	jmp ??end
??deny:
	call print_denied

??end:
	ret

	password_buffer db "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"
	correct_password_hash dw 028Dh, 08BBh, 07EBh, 0C95h
endp

; Find pointer to end character in string
; IN:
;	string ptr - DS:SI
; OUT:
;	DS:SI - string end ptr
; USES:
;	AL (= '$')
;	SI (RET)
find_string_end proc
??continue:
	lodsb
	cmp al, 24h
	jne ??continue
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

	; Write '$' instead of 0Dh
	dec di
	mov al, 24h
	stosb
	ret
endp

; Allowed
; USES:
;	AH
;	DX
print_allowed proc
	mov ah, 09h
	mov dx, offset string_access_allowed
	int 21h
	ret

	string_access_allowed db "access allowed)$"
endp

; Denied
; USES:
;	AH
;	DX
print_denied proc
	mov ah, 09h
	mov dx, offset string_access_denied
	int 21h
	ret

	string_access_denied db "access denied($"
endp

end start

; crackme.asm
