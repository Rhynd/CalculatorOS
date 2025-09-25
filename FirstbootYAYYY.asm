org 0x7c00

MOV SI, text
CALL print

print:
    MOV AH, 0eh
    MOV AL, [SI]
    CMP AL, 0
    JE jean
    
    INT 10h
    
    ADD SI, 1
    JMP print

jean:
RET






text db "Assembling boot sector", 0



































































times 510 - ($-$$) db 0
dw 0xAA55