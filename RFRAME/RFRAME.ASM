; Displays frame with some text

.model tiny

.286

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
	push ax

	; Load current key
	in al, 60h
	cmp al, 58h
	jne ??end

	push bx

	mov bx, offset i08_enable_frame
	mov al, cs:[bx]
	not al
	mov cs:[bx], al

	pop bx
??end:
	pop ax

	; longjmp
	db 0EAh
	i09_prev_handler_ptr dw 0FFFFh
	i09_prev_handler_seg dw 0FFFFh
endp

; 08 interrupt handler
i08_handler proc
	; Rewrite frame

	push bx

	mov bx, offset i08_enable_frame
	mov bl, cs:[bx]
	test bl, bl
	jz ??handler_middle

	; Save ax, bx, cx, dx
	mov bx, offset i08_register_storage

	; Save ax
	mov cs:[bx + 0], ax

	; Load old bx into ax and save it
	pop ax
	mov cs:[bx + 2], ax
	push ax

	; Save cx
	mov cs:[bx + 4], cx

	; Save dx
	mov cs:[bx + 6], dx

	; Push reality
	push ax cx dx es si ds di

	; ds:si = cs:palette
	push cs
	pop ds
	mov si, offset i08_frame_palette

	; es:di = 0B800h:0
	mov ax, 0B800h
	mov es, ax
	mov di, 0

	mov bx, 04h
	mov cx, 0Bh

	call write_box

	; Write register names
	mov si, offset i08_regname_string
	mov byte ptr cs:[si], 41h ; 'A'
	mov di, 160 * 1 + 4
	call write_string
	mov bx, offset i08_register_storage + 0
	mov bx, cs:[bx]
	call write_register

	mov si, offset i08_regname_string
	mov byte ptr cs:[si], 42h ; 'B'
	mov di, 160 * 2 + 4
	call write_string
	mov bx, offset i08_register_storage + 2
	mov bx, cs:[bx]
	call write_register

; Extend jump
	jmp ??handler_continue
??handler_middle:
	jmp ??handler_end	
??handler_continue:

	mov si, offset i08_regname_string
	mov byte ptr cs:[si], 43h ; 'C'
	mov di, 160 * 3 + 4
	call write_string
	mov bx, offset i08_register_storage + 4
	mov bx, cs:[bx]
	call write_register

	mov si, offset i08_regname_string
	mov byte ptr cs:[si], 44h ; 'D'
	mov di, 160 * 4 + 4
	call write_string
	mov bx, offset i08_register_storage + 6
	mov bx, cs:[bx]
	call write_register

	; Pop reality
	pop di ds si es dx cx ax
??handler_end:
	pop bx

	; Jump to old 08h handler
	db 0EAh
	i08_prev_handler_ptr dw 0FFFFh
	i08_prev_handler_seg dw 0FFFFh
endp

; Parse hex digit in al into corresponding number
; IN:
;	number to parse - ax
; OUT:
;	number as hex digit - ax
digit_to_char proc
	add al, 30h
	cmp al, 3Ah
	jb ??end
	add al, 07h
??end:
	ret
endp

; Write register at some destination
; IN:
;	destination - ES:DI
;	register    - bx
; USES:
;	AX
;	DI (= DI_ + 8)
write_register proc
	cld

	mov ax, bx
	shr ax, 12
	call digit_to_char
	stosb
	inc di

	mov ax, bx
	shr ax, 8
	and ax, 0Fh
	call digit_to_char
	stosb
	inc di

	mov ax, bx
	shr ax, 4
	and ax, 0Fh
	call digit_to_char
	stosb
	inc di

	mov ax, bx
	and ax, 0Fh
	call digit_to_char
	stosb
	inc di

	ret
endp

; Write string to certain location
; IN:
;	string      - DS:SI
;	destination - ES:DI
; USES:
;	AX
write_string proc
	jmp ??loop_cmp

??loop_start:
	stosb
	inc di

??loop_cmp:
	lodsb
	cmp al, 24h
	jne ??loop_start

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
	; Load from es:[si] to ax
	; Store palette entry to es:[di]
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
;	destination - ES:DI
;	palette     - DS:SI
;	height      - BX
;	width       - CX
; USES:
;	AX
;	BX
;	CX
;	DX
;	DI
;	SI
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
i08_frame_palette dw 01EC9h, 01ECDh, 01EBBh,    01EBAh, 01E20h, 01EBAh,    01EC8h, 01ECDh, 01EBCh

; Global variable
i08_enable_frame db 00h

; Register storage
i08_register_storage dw 0FFFFh, 0FFFFh, 0FFFFh, 0FFFFh

; Register name string
i08_regname_string db 'QX = $'

; End of program
program_end:
end start
