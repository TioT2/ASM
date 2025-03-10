; MAIN2.ASM

.model tiny
.286

.code
org 100h

locals ??

; Main function
Main proc
        CLD                                                                                                        
        CALL   Proc0
        CALL   Proc1
        CMP    BX, 2ED9h

        MOV    DX, offset S_ValidLicense                                                                                           
        JZ     ??end
        MOV    DX, offset S_InvalidLicense

??end:
	; Display license string
        MOV    AH, 09h                                                                                             
        INT    21h

        MOV    AX, 4c00h                                                                                           
        INT    21h        ;Exit                                                                                    
endp

; Probably something input-related, though
Proc0 proc
         MOV    DX, offset S_EnterLicenseKey
         MOV    AH, 09h                                                                                             
         INT    21h        ;"Enter the license k"                                                                   
         MOV    BX, DS                                                                                              
         MOV    ES, BX                                                                                              
         MOV    DI, offset G_InputBuffer
         MOV    AH, 01h                                                                                             
??jmp2:                                                                                                               
         INT    21h        ;Get kbd char in AL                                                                      
         STOSB                                                                                                      
         CMP    AL, 0dh                                                                                             
         JNZ    ??jmp2
         RET
endp

; Hash function?
Proc1 proc
         MOV    SI, offset G_InputBuffer
         XOR    BX, BX
??jmp1:
         LODSB                                                                                                      
         MOV    DI, AX
         XCHG   AX, BX
         MOV    CX, 0107h
         MUL    CX
         ADD    BX, AX
         MOV    AX, DI
         CMP    AL, 0Dh
         JNZ    ??jmp1
         RET
endp

S_EnterLicenseKey db 'Enter the license key', 0dh, 0ah, 24h
S_ValidLicense    db 'You hava a valid license', 0Dh, 0Ah, 24h
S_InvalidLicense  db 'The license is invalid', 0Dh, 0Ah, 24h
; Buffer smwhr here?

G_InputBuffer:
end Main
