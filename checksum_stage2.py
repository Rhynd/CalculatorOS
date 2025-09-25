from zlib import crc32
import sys

FILE_LEN_POS = 2 # information sur la longueur en 4 octets a la position FILE_LEN_POS
CRC32_POS = 6   # ou ecrire le CRC32 en 4 octets a la position CRC32_POS

# args format: stage2.bin

if len(sys.argv) != 3:
    print('Usage: python checksum_stage2.py <stage2.bin> <output.bin> <kernel.bin>')
    sys.exit(1)

file_path = sys.argv[1]
if not file_path.endswith('.bin'):
    print('Error: input file must have .bin extension')
    sys.exit(1)
try:
    with open(file_path, 'rb') as binfile:
        data = bytearray(binfile.read())
        if len(data) < 10:
            print(f'Error: {file_path} is too small to contain required headers')
            sys.exit(1)

        nb_sectors = (len(data) + 511) // 512
        # at the end of the file add
        # kernel_start_lba DD 0, 0 ; kernel block entry point (8 bytes)
        # kernel_size DD 0 ; kernel size in bytes (4 bytes)
        # kernel_size_sectors DD 0 ; kernel size in sectors (4 bytes)

        # lba
        data[-16:-8] = (nb_sectors + 1).to_bytes(8, byteorder='little')




        # Calculate length and CRC32
        file_length = int.from_bytes(data[FILE_LEN_POS:FILE_LEN_POS+4], byteorder='little')
        payload = data[10 : file_length]
        crc = crc32(payload) & 0xFFFFFFFF

        # Write CRC32 (4 bytes, little-endian)
        data[CRC32_POS:CRC32_POS+4] = crc.to_bytes(4, byteorder='little')



        with open(sys.argv[2], 'wb') as outfile:
            outfile.write(data)

    print(f'Updated {file_path} with length {file_length} and CRC32 {crc:08X}')
except FileNotFoundError:
    print(f'Error: {file_path} not found')
    sys.exit(1)
except Exception as e:
    print(f'Error: {e}')
    sys.exit(1)