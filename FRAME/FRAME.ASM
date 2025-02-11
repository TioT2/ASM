; Displays frame with some text

.model tiny

.data

; Build string constasnt
String db "Hello world!!!1!", '$'

; Palette dw 0F30h, 0F31h, 0F32h, 0F33h, 0F34h, 0F35h, 0F36h, 0F37h, 0F38h, 0F39h
; Palette dw 0FC9h, 0FCDh, 0FBBh,    0FBAh, 0F20h, 0FBAh,    0FC8h, 0FCDh, 0FBCh
Palette dw 0F0C9h, 0F0CDh, 0F0BBh,    0F0BAh, 0F020h, 0F0BAh,    0F0C8h, 0F0CDh, 0F0BCh

.code

org 100h
locals ??

start:
        ; Initialize segment pointer
        mov ax, 0b800h
        mov es, ax

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
;	message - di
; OUT:
;	length - cx
; USES:
;	ax, cx, di
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
;	SI, DI, CX, AX
; NOTE:
;	Function adds exactly 6 to initial SI register value.
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
write_box proc
	push cx
	; Save di into dx
	mov dx, di
	call write_line
	mov di, dx
	pop cx

	; cx - height, bx - width now
	xchg cx, bx

	; DX = initial destination value
	mov dx, di

	jmp ??loop_test

??loop:
	push cx

	; cx = height
	mov cx, bx
	mov di, dx

	call write_line

	; Restore SI value
	sub si, 6

	pop cx

??loop_test:
	add dx, 0A0h
	; Does test instruction usage worth it?
	loop ??loop

	; Write last line
	add si, 6
	mov di, dx
	mov cx, bx
	call write_line

??end:
	ret
endp

end start
