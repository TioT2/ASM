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

	push bx ds si di

	; Switch frame rendering flag
	mov bx, offset i08_enable_frame
	mov al, cs:[bx]
	not al
	mov cs:[bx], al

	test al, al
	jnz ??case_end

	; Display background buffer if handling is disabled
	mov bx, offset display_background_buffer_callback
	call iter_screen_buffers

	; Sync background buffer and display it
	; mov bx, offset sync_background_buffer_callback
	; call iter_screen_buffers
	; mov bx, offset display_background_buffer_callback
	; call iter_screen_buffers

??case_end:

	pop di si ds bx
??end:
	pop ax

	; longjmp
	db 0EAh
	i09_prev_handler_ptr dw 0FFFFh
	i09_prev_handler_seg dw 0FFFFh
endp

; Write character
m_write_register_string MACRO off, char, reg
	mov si, offset i08_regname_string
	mov byte ptr cs:[si], char ; 'B'
	mov di, off
	call write_string
	mov bx, offset i08_register_storage + reg
	mov bx, cs:[bx]
	call write_register
ENDM

; 08 interrupt handler
i08_handler proc
	; Rewrite frame

	push bx

	mov bx, offset i08_enable_frame
	mov bl, cs:[bx]
	test bl, bl
	jz ??handler_middle

	; Save registers

	mov bx, offset i08_register_storage

	; Save ax
	mov cs:[bx + 0], ax

	; Load BX from stack and save it
	pop ax
	mov cs:[bx + 2], ax
	push ax

	; Save cx, dx, sp, bp registers
	mov cs:[bx + 4], cx
	mov cs:[bx + 6], dx
	mov cs:[bx + 8], sp
	mov cs:[bx + 10], bp

	; Push reality
	push ax cx dx es si ds di

	; Update background buffer
	; Render new foreground buffer
	; Display foreground buffer

	; Sync current background buffer
	mov bx, offset sync_background_buffer_callback
	call iter_screen_buffers

	; Render
	; ds:si = cs:palette
	push cs
	pop ds
	mov si, offset i08_frame_palette

	mov ax, 0B800h
	mov es, ax
	mov di, 0

	mov bx, 06h
	mov cx, 0Bh

	; call write_box

; Extend jump
	jmp ??handler_continue
??handler_middle:
	jmp ??handler_end	
??handler_continue:

	; Write X character
	mov si, offset i08_regname_string
	mov byte ptr cs:[si + 1], 58h ; 'X'

	; Display ax..dx registers
	; m_write_register_string 00A4h, 41h, 0
	; m_write_register_string 0144h, 42h, 2
	; m_write_register_string 01E4h, 43h, 4
	; m_write_register_string 0284h, 44h, 6

	; Write P character
	mov si, offset i08_regname_string
	mov byte ptr cs:[si + 1], 50h ; 'P'

	; Display sp and bp registers.
	; m_write_register_string 0324h, 53h, 8
	; m_write_register_string 03C4h, 42h, 10

	; Display rendered buffer contents
	mov bx, offset display_render_buffer_callback
	call iter_screen_buffers
	
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
	; di += 160
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


; Read background buffer from screen
read_background_buffer_callback proc
	mov ax, ds:[si]
	mov cs:[di + offset i08_background_buffer], ax
	ret
endp

display_background_buffer_callback proc
	; Load value from render buffer and store it to DS:SI
	mov ax, cs:[di + offset i08_background_buffer]
	mov ds:[si], ax
	ret
endp

display_render_buffer_callback proc
	mov ax, cs:[di + offset i08_render_buffer]
	mov ds:[si], ax
	ret
endp

sync_background_buffer_callback proc
	; AX = pixel color
	mov ax, ds:[si]

	; Skip writing background buffer if value is same with value in render buffer (e.g. external code doesn't modified pixel value)
	cmp ax, cs:[di + offset i08_render_buffer]
	je ??end

	; Write new pixel color to background buffer
	mov cs:[di + offset i08_background_buffer], ax

??end:
	ret
endp

; Update background buffer contents
; IN:
;	per-pixel callback pointer - bx
; USES:
;	AX
;	DS (= B800)
;	SI
;	DI
; NOTE:
;	callback pointer signature:
;	IN:
;		buffer offset - DI
;		pixel pointer - DS:SI
;	USES:
;		DI (= _DI)
;		DS (= _DS)
;		SI (= _SI)
iter_screen_buffers proc
	; DS:SI = B800:0000 (screen ptr)
	mov ax, 0B800h
	mov ds, ax
	xor si, si

	; DI = 0
	xor di, di

	; jmp ??y_loop_cmp

??y_loop_start:

??x_loop_start:

	; Call function
	call bx

??x_loop_cmp:
	; si += 2; di += 2;

	inc si
	inc si
	inc di
	inc di

	; if di % 32 < 26: goto x_loop_start
	mov ax, di
	and ax, 1Fh
	cmp ax, 1Ah
	jb ??x_loop_start

??y_loop_cmp:
	; si = si - 13 * 2 + 80 * 2
	add si, 134

	; di = di - 13 * 2 + 16 * 2
	add di, 6

	cmp si, 8 * 160 + 0 ; check if si points to (0, 25) pixel
	jb ??y_loop_start

	ret
endp

; Palette dw 0F30h, 0F31h, 0F32h, 0F33h, 0F34h, 0F35h, 0F36h, 0F37h, 0F38h, 0F39h
; Palette dw 0FC9h, 0FCDh, 0FBBh,    0FBAh, 0F20h, 0FBAh,    0FC8h, 0FCDh, 0FBCh
i08_frame_palette dw 01EC9h, 01ECDh, 01EBBh,    01EBAh, 01E20h, 01EBAh,    01EC8h, 01ECDh, 01EBCh

; Global variable
i08_enable_frame db 00h

; Register storage
i08_register_storage dw 0FFFFh, 0FFFFh, 0FFFFh, 0FFFFh, 0FFFFh, 0FFFFh

; Register name string
i08_regname_string db 'QQ = $'

; Rendering destination
i08_render_buffer dw 256 dup (?)

; Previous background
i08_background_buffer dw 256 dup (?)

; End of program
program_end:
end start
