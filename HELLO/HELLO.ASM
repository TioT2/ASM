; Assembly file
.model tiny

.data

; Build string constasnt
String db "Hello world!!!1!", 0Dh, 0Ah, '$'

.code

org 100h

start:
        ; Write string by DX location
        mov ah, 09h
        mov dx, offset String
        int 21h

        ; Set 13h video mode
        mov ax, 0013h
        int 00h

        ; Set segment pointer
        mov ax, 0a000h
        mov es, ax

        ; Write some color to 00
        mov bx, 00h
        mov byte ptr es:[bx], 0Fh

        ; Exit with 00h code
        mov ax, 4C00h
        int 21h

end start
