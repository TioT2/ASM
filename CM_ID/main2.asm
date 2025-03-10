; MAIN2.ASM

.model tiny
.286

.code
org 100h

locals ??

; 010Bh - set S_ValidLicense
; FFFCh - stack top
; 0197h - string end
; 0D01h

; Main function
start proc
        CLD
        CALL   P_ReadPasswordString
        CALL   P_GetPasswordHash
        CMP    BX, 2ED9h

        MOV    DX, offset S_ValidLicense
        JE     ??end
        MOV    DX, offset S_InvalidLicense

??end:
	; Display license string
        MOV    AH, 09h
        INT    21h

        MOV    AX, 4C00h
        INT    21h
endp

P_ReadPasswordString proc
	; Display greeting
        MOV    DX, offset S_EnterLicenseKey
        MOV    AH, 09h
        INT    21h

	; Bro, it isn't required
        MOV    BX, DS
        MOV    ES, BX

	; WTF II?
        MOV    DI, offset G_InputBuffer
        MOV    AH, 01h
??jmp2:
        INT    21h
        STOSB
        CMP    AL, 0Dh
        JNZ    ??jmp2
        RET
endp


P_GetPasswordHash proc
	; SI = passwd string
        MOV    SI, offset G_InputBuffer

	; b = 0
        XOR    BX, BX

??continue:
	; Load passwd byte
        LODSB

	; HASH = HASH * 107h + CURRENT_CHAR
        MOV    DI, AX
        XCHG   AX, BX
        MOV    CX, 0107h
        MUL    CX
        ADD    BX, AX

	; AX = CURRENT_CHAR_SAVE
        MOV    AX, DI

	; Check if passwd byte == 0Dh (trailing byte is hashed, lol)
        CMP    AL, 0Dh
        JNZ    ??continue
        RET
endp

S_EnterLicenseKey db 'Enter the license key', 0Dh, 0Ah, 24h
S_ValidLicense    db 'You hava a valid license', 0Dh, 0Ah, 24h
S_InvalidLicense  db 'The license is invalid', 0Dh, 0Ah, 24h
; Buffer smwhr here?

G_InputBuffer:
end start
