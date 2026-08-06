
# Convert a flat binary (objcopy -O binary) into the 128-bit hex rows main_mem expects:
# 1024 rows, 32 hex chars each = 4 words/row, word 0 rightmost
# usage: python3 bin2hex.py <in.bin> <out.hex> [depth] [width_bytes]
import sys

inp, outp = sys.argv[1], sys.argv[2]
depth = int(sys.argv[3]) if len(sys.argv) > 3 else 1024
width = int(sys.argv[4]) if len(sys.argv) > 4 else 16  

data = open(inp, "rb").read()
data = data.ljust(depth * width, b"\x00")[: depth * width]

with open(outp, "w") as f:
    for i in range(depth):
        row = data[i * width:(i + 1) * width]
        f.write(row[::-1].hex() + "\n")   # reverse bytes -> word0 rightmost
