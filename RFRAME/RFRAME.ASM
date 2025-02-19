; Displays frame with some text

.model tiny

.code

org 100h
locals ??

start proc
	; Save current cs into cx
	push cs
	pop cx

	xor ax, ax
	mov es, ax

	; Save i08 interrupt handler
	mov ax, es:[08h * 4]
	mov i08_prev_handler_ptr, ax
	mov ax, es:[08h * 4 + 2]
	mov i08_prev_handler_seg, ax

	; Save i09 interrupt handler
	mov ax, es:[09h * 4]
	mov i09_prev_handler_ptr, ax
	mov ax, es:[09h * 4 + 2]
	mov i09_prev_handler_seg, ax

	; Clear Interrupt (disallow interrupt recieving)
	cli ; <-----------------------!!!!!!!!!!!!!!!!!!!!!

	; Write new i08 handler
	mov es:[08h * 4], offset i08_handler
	mov es:[08h * 4 + 2], cx ; cs, actually

	; Write new i09 handler
	mov es:[09h * 4], offset i09_handler
	mov es:[09h * 4 + 2], cx ; cs, actually

	; Set Interrupt (allow interrupt recieving)
	sti ; <-----------------------!!!!!!!!!!!!!!!!!!!!!

	; Make program resident
	mov ax, 3100h
	mov dx, offset program_end
	; Recalculate into paragraph
	shr dx, 4
	inc dx
	int 21h
endp

; Handler
i09_handler proc
	push ax bx

	; Load current key
	in al, 60h

	mov bx, offset i08_key
	mov cs:[bx], al

	cmp al, 58h
	jne ??end

	mov bx, offset i08_enable_frame
	mov al, cs:[bx]
	; not al
	xor al, 01h
	mov cs:[bx], al

??end:
	pop bx ax

	; longjmp
	db 0EAh
	i09_prev_handler_ptr dw 0FFFFh
	i09_prev_handler_seg dw 0FFFFh
endp

; 08 interrupt handler
i08_handler proc
	; Rewrite frame

	push ax bx es di

	; mov al, i08_enable_frame
	; test al, al
	; jz ??handler_end

	; Handler code
	mov ax, 0B800h
	mov es, ax
	mov di, 5*80*2

	mov ah, 4Ch
	mov bx, offset i08_key
	mov al, cs:[bx]

	cld
	stosw

	mov bx, offset i08_enable_frame
	mov al, cs:[bx]
	stosw

??handler_end:
	pop di es bx ax

	; Jump to old 08h handler
	db 0EAh
	i08_prev_handler_ptr dw 0FFFFh
	i08_prev_handler_seg dw 0FFFFh
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

; Palette dw 0F30h, 0F31h, 0F32h, 0F33h, 0F34h, 0F35h, 0F36h, 0F37h, 0F38h, 0F39h
; Palette dw 0FC9h, 0FCDh, 0FBBh,    0FBAh, 0F20h, 0FBAh,    0FC8h, 0FCDh, 0FBCh
Palette dw 0F0C9h, 0F0CDh, 0F0BBh,    0F0BAh, 0F021h, 0F0BAh,    0F0C8h, 0F0CDh, 0F0BCh

; Global variable
i08_key db 00h
i08_enable_frame db 30h

; End of program
program_end:
end start
