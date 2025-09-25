import sys

data_final = b''

files = sys.argv[1:]
if len(files) < 2:
    print('Usage: python buildimg.py <bootsector.bin> [<file1.bin> <file2.bin> ...] <output.img>')
    sys.exit(1)
if files[-1].endswith('.img'):
    output_file = files.pop()
else:
    print('Error: output file must have .img extension')
    sys.exit(1)

first_file = True
for f in files:
    # check if .bin file exists
    if not f.endswith('.bin'):
        print(f'Error: {f} is not a .bin file')
        sys.exit(1)
    try:
        with open(f, 'rb') as binfile:
            data = binfile.read()
            if first_file:
                # check if size is 512o and finish with 0xAA55
                if len(data) != 512 or data[510:512] != b'\x55\xAA':
                    print(f'Error: {f} is not a valid boot sector (must be 512 bytes and end with 0xAA55)')
                    sys.exit(1)
                first_file = False
            if len(data) % 512 != 0:
                # pad with 0x00 to next multiple of 512o
                data += b'\x00' * (512 - (len(data) % 512))

            data_final += data
    except FileNotFoundError:
        print(f'Error: {f} not found')
        sys.exit(1)

if len(data_final) > 1474560: # 1.44MB
    print('Error: final image size exceeds 1.44MB')
    sys.exit(1)

# write to output file
with open(output_file, 'wb') as outfile:
    outfile.write(data_final)
print(f'Image {output_file} created successfully with size {len(data_final)} bytes')