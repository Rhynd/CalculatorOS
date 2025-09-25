ORG 0x1000
DW 0xABCD ; signature
DD endfile - $$ ; size of this stage in bytes
DD 0x0 ; crc32 checksum (calculated by build script)


;clears screen
MOV AX, 0600h       ; Function 06h (scroll up) with 00h lines to scroll (clears screen)
MOV BH, 07h         ; Color attribute: 07h is light grey on a black background
MOV CX, 0000h       ; Top-left corner of the scroll area (Row 0, Col 0)
MOV DX, 184Fh       ; Bottom-right corner (Row 24, Col 79)
INT 10h             ; Call the BIOS video services interrupt




MOV SI, text
MOV AX, 0
CALL print
MOV SI, newline
MOV AX, 0
CALL print
CALL main


print:
    MOV AH, 0eh
    MOV AL, [SI]
    CMP AL, 0
    JE stop
    
    INT 10h
    
    ADD SI, 1
    JMP print
    
stop:
    RET
    
    
printchar:
    PUSH AX
    MOV AX, 0
    MOV AH, 0eh
    INT 10h
    POP AX
    RET


keyboard:
    MOV AH, 00h
    INT 16h
    RET


createnumber:
    MOV BX, 10
    MUL BX
    MOV BH, 0
    MOV BL, AL
    ADD AX, BX
    
    RET
    
    
notnumber:
    CMP AL, 0Dh
    JE calc
    
    CMP AL, '+'
    JE isoperator
    CMP AL, '-'
    JE isoperator
    CMP AL, '*'
    JE isoperator
    CMP AL, '/'
    JE isoperator
    
    JMP main


isoperator:
    CALL printchar
    JMP main


main:
    CALL keyboard
    CMP AL, '0'
    JL notnumber
    CMP AL, '9'
    JG notnumber
    
    CALL printchar
    CALL createnumber
    JMP main
    
    
calc:
    RET
    






JMP $

text db "This is a calculator", 0
newline db 13, 10, 0







times 1025 db 0
endfile: