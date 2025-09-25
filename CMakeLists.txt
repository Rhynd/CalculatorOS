cmake_minimum_required(VERSION 3.31)
project(CalculatorOS)

set(NASM_EXE nasm)
set(QEMU_EXE qemu-system-i386)
set(IMG_FILE ${CMAKE_BINARY_DIR}/floppy.img)
set(BOOT_BIN ${CMAKE_BINARY_DIR}/boot.bin)
set(STAGE2_BIN ${CMAKE_BINARY_DIR}/stage2.bin)
set(STAGE2_TEMP ${CMAKE_BINARY_DIR}/stage2_temp.bin)
find_package(Python3 REQUIRED COMPONENTS Interpreter)

# Commande pour assembler en binaire brut
add_custom_command(
        OUTPUT ${BOOT_BIN}
        COMMAND ${NASM_EXE} -f bin ${CMAKE_SOURCE_DIR}/boot.asm -o ${BOOT_BIN}
        DEPENDS ${CMAKE_SOURCE_DIR}/boot.asm
        COMMENT "Assembling boot sector -> boot.bin"
)

add_custom_command(
        OUTPUT ${STAGE2_TEMP}
        COMMAND ${NASM_EXE} -f bin ${CMAKE_SOURCE_DIR}/stage2.asm -o ${STAGE2_TEMP}
        DEPENDS ${CMAKE_SOURCE_DIR}/stage2.asm
        COMMENT "Assembling stage2 -> stage2.bin"
)

add_custom_command(
        OUTPUT ${STAGE2_BIN}
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/checksum_stage2.py ${STAGE2_TEMP} ${STAGE2_BIN}
        DEPENDS ${STAGE2_TEMP} ${CMAKE_SOURCE_DIR}/checksum_stage2.py
        COMMENT "Calculating and embedding checksum into stage2.bin + kernel info"
)

add_custom_target(build_bins ALL
        DEPENDS ${BOOT_BIN} ${STAGE2_BIN}
)


# lunch buildimg.py boot.bin [file.bin ...] floppy.img
add_custom_command(
    OUTPUT ${IMG_FILE}
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/buildimg.py ${BOOT_BIN} ${STAGE2_BIN} ${IMG_FILE}
    DEPENDS ${BOOT_BIN} ${STAGE2_BIN}
    COMMENT "Creating floppy image -> floppy.img"
)

add_custom_target(build_img ALL
    DEPENDS ${IMG_FILE}
)

# Cible pour lancer QEMU
add_custom_target(run
        COMMAND ${QEMU_EXE} -drive format=raw,file=${IMG_FILE} -serial stdio
        DEPENDS ${IMG_FILE}
        COMMENT "Running bootloader in QEMU"
)

add_custom_target(os ALL
        DEPENDS build_bins build_img
        COMMENT "Building the full OS (boot + stage2 + floppy.img)"
)