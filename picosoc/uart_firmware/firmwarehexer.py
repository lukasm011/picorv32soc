import argparse

parser = argparse.ArgumentParser(description="hexer script parser")
parser.add_argument('--startaddr', action="store", dest='startaddr', default=0x10)
parser.add_argument('--input', action="store", dest='filename', default="firmware.bin")
args=parser.parse_args()
with open(args.filename, "rb") as f, open("firmware.hex", "w") as out:
    data = f.read()
    i = 0
    while (i < args.startaddr//4):
        out.write(f"{0:08x}\n")
        i+=1
    for i in range(len(data)//4):
        word = data[i*4 : (i+1)*4].ljust(4, b'\x00')
        val = int.from_bytes(word, byteorder="little")
        out.write(f"{val:08x}\n")
    