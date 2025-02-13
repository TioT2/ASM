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

	xor ax, ax
	mov es, ax

	; bx = addr of 09h interrupt
	mov bx, 09h * 4

	; Clear Interrupt (disallow interrupt recieving)
	cli ; <-----------------------!!!!!!!!!!!!!!!!!!!!!

	mov es:[bx], offset input_int_handler

	; User cannot use mov with CS
	push cs
	pop ax
	mov es:[bx+2], ax

	; Set Interrupt (allow interrupt recieving)
	sti ; <-----------------------!!!!!!!!!!!!!!!!!!!!!

	; Make program resident
	mov ax, 3100h
	mov dx, offset program_end ; End Of Program, rename
	; Recalculate into paragraph
	shr dx, 4
	inc dx
	int 21h

	; Debug Into: ALT+F7
	int 09h

	mov ax, 4C00h
	int 21h

	ret ; ?


; Handler
input_int_handler proc
	; akhujet, TASM tak mozhet
	push ax di es

	; Handler code

	mov ax, 0B800h
	mov es, ax
	mov ah, 4Ch
	mov di, 5*80*2

	; It's OK to change flag register, it's saved during interrupt call
	cld

	; Read from 60 port
	in al, 60h
	stosw

	; Make keyboard controller happy - write flag that keydown interrupt is handled.
	; It's called 'blink' by highest(?) bit. It's probably ok to write 0 to port.
	; This is called 'EOI' signal - End Of Interrupt.
	in al, 61h
	mov ah, al
	or al, 80h
	out 61h, al
	mov al, ah
	out 61h, al

	; Constant cannot be directly written to port.
	mov al, 20h
	out 20h, al

	pop es di ax

	; Return from interrupt call
	; If you use default RET, it will not read flags and segment - return address only.
	iret ; Interrupt RETurn
endp

; End of program, referenced
program_end:
end start
