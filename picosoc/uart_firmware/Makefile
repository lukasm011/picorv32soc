.PHONY: firmware

SHELL := /bin/bash

C_SRCS := uart.c fw_test.c
C_OBJS := $(patsubst %.c,%.o,$(C_SRCS))
ASM_SRCS := crt0.asm divsi3.asm
ASM_OBJS := $(patsubst %.asm,%.o,$(ASM_SRCS))

firmware: firmware.hex
	riscv64-unknown-elf-objdump -d firmware.elf > firmware_dis.txt

clean:
	rm -f firmware.{hex,bin,elf} $(C_OBJS) $(ASM_OBJS)

$(ASM_OBJS): %.o: %.asm
	riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o $@ $<

$(C_OBJS): %.o: %.c
	riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -c $< -o $@

firmware.elf: $(C_OBJS) $(ASM_OBJS)
	riscv64-unknown-elf-ld -m elf32lriscv -T customsections.lds -o $@ $^

firmware.hex: firmware.elf
	riscv64-unknown-elf-objcopy -O binary $< firmware.bin
	~/venvs/cocotb-venv/bin/python3 firmwarehexer.py