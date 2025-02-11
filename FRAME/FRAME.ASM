; Displays frame with some text

.model tiny

.data

; Build string constasnt
String db "Hello world!!!1!", '$'

; Message box palette
; Palette dw 0F30h, 0F31h, 0F32h, 0F33h, 0F34h, 0F35h, 0F36h, 0F37h, 0F38h, 0F39h
Palette dw 0FC9h, 0FCDh, 0FBBh,    0FBAh, 0F20h, 0FBAh,    0FC8h, 0FCDh, 0FBCh

.code

org 100h
locals ??

start:
        ; Initialize segment pointer
        mov ax, 0b800h
        mov es, ax

        mov bx, offset Palette
        mov cx, offset String
        mov si, 328

        call write_message_box

        mov ah, 86h
        mov cx, 2Fh
        int 15h

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
;	message - bx
; OUT:
;	length - ax
; USES:
;	ax, bx, dx
get_message_len proc
	xor ax, ax

	jmp ??test

??continue:
	inc ax
	inc bx

??test:
	mov dl, byte ptr [bx]
	cmp dl, 24h
	jne ??continue

	ret
endp

; Write line by palette segment (e.g. single frame element)
; IN:
; 	destination - si 
;	palette     - bx
;	end         - cx
; USES:
;	si, dx
write_line proc
	; First character
	mov dx, word ptr [bx]
	mov word ptr es:[si], dx
	add si, 2

	stosw 

??start:
	cmp si, cx
	je ??end

	; Put pixel
	mov dx, word ptr [bx + 2]
	mov word ptr es:[si], dx
	add si, 2

	jmp ??start

??end:
	mov  dx, word ptr [bx + 4]
	mov word ptr es:[si], dx
	ret
endp

; Write message box
;  IN:
;	palette - bx
;	message - cx
;	offset  - si
; USES:
;	??? (all registers)
write_message_box proc
	; Save string contents
	push cx

	; Calculate length
	xchg bx, cx
	call get_message_len
	xchg bx, cx

	inc ax
	shl ax, 1

	; Write first line
	lea cx, [si + 4]
	add cx, ax
	push si
	call write_line
	pop si

	add bx, 6

	; Write intermediate characters
	lea di, [si + 160 * 4]
	jmp ??cmp

??start:
	lea cx, [si + 4]
	add cx, ax
	push si
	call write_line
	pop si

??cmp:
	add si, 160
	cmp si, di
	jl ??start

	add bx, 6

	; Write last line
	lea cx, [si + 4]
	add cx, ax
	push si
	call write_line
	pop si

	; Restore string contents into bx
	pop bx

	; Move cursor
	sub si, 316
	jmp ??str_cmp

??str_start:
	; Write current character to screen
	mov byte ptr es:[si], dl
	add si, 2
	inc bx

??str_cmp:
	; Load current character and check if it is not '$'
	mov dl, byte ptr [bx]
	cmp dl, 24h
	jne ??str_start

	ret
endp

end start
