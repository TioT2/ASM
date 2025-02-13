; Displays frame with some text

.model tiny

.data

; Build string constasnt
String db "Hello world!!!1!", '$'

; Palette dw 0F30h, 0F31h, 0F32h, 0F33h, 0F34h, 0F35h, 0F36h, 0F37h, 0F38h, 0F39h
; Palette dw 0FC9h, 0FCDh, 0FBBh,    0FBAh, 0F20h, 0FBAh,    0FC8h, 0FCDh, 0FBCh
Palette dw 0F0C9h, 0F0CDh, 0F0BBh,    0F0BAh, 0F021h, 0F0BAh,    0F0C8h, 0F0CDh, 0F0BCh

.code

org 100h
locals ??

start:
        ; Initialize segment pointer
        mov ax, 0b800h
        mov es, ax

        ; Calculate message length

        mov di, 328            ; destination
        mov si, offset Palette ; palette
        mov bx, 4              ; height
        mov cx, 8              ; width
        call write_box

        ; mov bx, offset Palette
        ; mov cx, offset String
        ; mov si, 328
        ; call write_message_box

	; Wait
        ; mov ah, 86h
        ; mov cx, 2Fh
        ; int 15h

        ; Exit with 0 code.
        mov ax, 4C00h
        int 21h
        ret

        ; ; Load palette value
        ; mov ax, word ptr [offset Palette + 02h]

        ; ; Write palette element by address
        ; mov bx, 00h
        ; mov word ptr es:[bx], ax

; Calculate message length
; IN:
;	message - ES:DI
; OUT:
;	length - CX
; USES:
;	AX
;	CX (RESULT)
;	DI (= DI_ + CX)
get_message_len proc
	; cx = -1
	xor cx, cx
	dec cx

	; Write string end character
	mov al, 24h

	; Find end character
	repnz scasb

	neg cx
	dec cx

	ret
endp

; Write line by palette segment (e.g. single frame element)
; IN:
; 	destination - ES:DI
;	palette     - DS:SI
;	length      - CX
; USES:
;	AX
;	CX (= 0)
;	DI (= DI_ + CX_ * 2 + 4)
;	SI (= SI_ + 6)
; NOTE:
;	This function IS NOT expected to be called from ANY function, except write_box
write_line proc
	; Load from [si] to ax
	; Store palette entry to [di]
	lodsw
	stosw

	; Load next palette entry
	; Write center
	lodsw
	rep stosw

	; Load from [si] to ax
	; Store palette entry to [di]
	lodsw
	stosw

	ret
endp

; Write box
; IN:
;	destination - di
;	palette     - si
;	height      - bx
;	width       - cx
; USES:
;	AX, BX, CX, DX, DI, SI
write_box proc
	cld

	mov dx, cx

	call write_line

	mov cx, dx

	; Restore DI
	sub di, cx
	sub di, cx
	sub di, 4

	; DX = height
	; BX = width
	mov dx, bx
	inc dx
	mov bx, cx

	; ax - USED
	; bx - frame width
	; cx - write_line input parameter
	; dx - loop counter
	; si - palette ptr
	; di - character ptr

	jmp ??loop_test

??loop:
	; cx = height
	mov cx, bx

	call write_line

	; Restore SI value
	sub si, 6

	; Restore DI value
	; di -= bx * 2 + 4
	sub di, bx
	sub di, bx
	sub di, 4

??loop_test:
	add di, 0A0h
	dec dx
	jnz ??loop

	; Write last line
	add si, 6
	mov cx, bx
	call write_line

??end:
	ret
endp

; Write string
; IN:
;	string        - ES:DI
;	location      - DS:SI
;	string length - CX
;	text color    - AH
; USES:
; 	AL
;	CX (= 0)
;	DI (= DX_ + CX_ * 2)
;	SI (= SI_ + CX_)
write_str proc
	cld

??loop:
	; stosb is used to save pixel color
	lodsb
	stosw
	loop ??loop

	ret
endp

; Parse decimal string
; IN:
;	string - ES:DI
; OUT:
;	value - CX
; USES:
;	DI
; NOTE:
;	Function assumes, that input string is valid decimal string. If it's not, resulting value isn't defined.
parse_string_dec proc
	cld
	xor ax, ax
	xor cx, cx

	jmp ??loop_end
??loop:
	mul 0Ah
	add ax, al

??loop_end:
	mov cl, byte ptr [di]
	inc di
	sub cl, 30h
	jb ??loop

	ret
endp

end start
