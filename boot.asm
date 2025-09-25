org 0x7C00

MOV AX, 0
MOV DS, AX
MOV ES, AX
MOV SS, AX
MOV [boot_drive], DL
MOV SP, 0x7E00

; load stage 2 and jump
MOV AH, 0x02
MOV AL, 1
MOV CH, 0
MOV CL, 2
MOV DH, 0
MOV BX, 0x1000
MOV DL, [boot_drive]
INT 0x13
JC stage_bad_read
MOV AX, [0x1000] ; read signature
CMP AX, 0xABCD
JNE stage_invalide_signature
MOV AX, [0x1002] ; read size 1/2
MOV DX, [0x1004] ; read size 2/2
MOV BX, 512
DIV BX
CMP DX, 0
JE no_extra_sector
ADD AX, 1
no_extra_sector:
CMP AX, 0
JE stage_bad_size
SUB AX, 1 ; remove the first sector already read
CMP AX, 0
JE check_crc32_stage2
MOV AL, AL
MOV AH, 0x02
MOV CH, 0
MOV CL, 3 ; start reading from sector 3
MOV DH, 0
MOV BX, 0x1000+512 ; load after the first stage
MOV DL, [boot_drive]
INT 0x13
JC stage_bad_read
check_crc32_stage2:
PUSH 0x100A
MOV EAX, [0x1002]
SUB EAX, 10 ; size - 10 (signature + size + crc32)
PUSH EAX
CALL CRC32 ; EAX is the CRC32
MOV EBX, [0x1006]
CMP EAX, EBX
JNE stage_bad_CRC32
MOV DL, [boot_drive]; store boot drive for stage 2
JMP 0x0000:0x100A

CRC32:
    PUSH BP
    MOV BP, SP
    MOV EBX, [BP+4] ; size
    MOV SI, [BP+8] ; pointer to data
    MOV EAX, 0xFFFFFFFF

    CRC32_loop:
        MOV DL, [SI]
        ADD SI, 1
        XOR AL, DL
        MOV CX, 8
        CRC32_bit_a_bit_loop:
            SHR EAX,1
            JNC no_xor
            XOR EAX,0xEDB88320
            no_xor:
                LOOP CRC32_bit_a_bit_loop

        DEC EBX
        JNE CRC32_loop

    XOR EAX, 0xFFFFFFFF
    POP BP
    RET 6

stage_bad_CRC32:
    MOV SI, stage_bad_CRC32_msg
    JMP print
stage_invalide_signature:
    MOV SI, stage_invalide_signature_msg
    JMP print
stage_bad_size:
    MOV SI, stage_bad_size_msg
    JMP print
stage_bad_read:
    MOV SI, stage_bad_read_msg
    JMP print

print:
    MOV AH, 0x0E
loop:
    MOV AL, [SI]
    CMP AL, 0
    JE end
    INT 0x10
    ADD SI, 1
    JMP loop
end:
    JMP $


stage_bad_read_msg db "Read of the second stage failed!", 0
stage_invalide_signature_msg db "The Second Stage as an invalid signature!", 0
stage_bad_size_msg db "The Second Stage has an invalid size!", 0
stage_bad_CRC32_msg db "The Second Stage has an invalid CRC32 checksum!", 0
boot_drive db 0
crc_temp DW 0, 0
times 510-($-$$) db 0
dw 0xAA55