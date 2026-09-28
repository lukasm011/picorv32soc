.PHONY: firmware

firmware: crt0.asm uart.c fw_test.c customsections.lds
	riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -c fw_test.c -o main.o
	riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -c -static-libgcc -lgcc uart.c -o uart.o
	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o assembly.o crt0.asm
	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o divsi3.o divsi3.asm
	riscv64-unknown-elf-ld -m elf32lriscv -T customsections.lds -o firmware.elf main.o assembly.o uart.o divsi3.o
	riscv64-unknown-elf-objcopy -O binary firmware.elf firmware.bin
	~/venvs/cocotb-venv/bin/python3 firmwarehexer.py
	riscv64-unknown-elf-objdump -d firmware.elf 