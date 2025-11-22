# Makefile cho project RISC-V 32-bit Assembly

# Tên chương trình
TARGET = prog

# Compiler và các tool RISC-V
CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy

# Cờ biên dịch
CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -T link.ld

# Mặc định: build tất cả
all: $(TARGET).elf $(TARGET).bin $(TARGET)_mem.hex

# Bước 1: biên dịch file assembly -> ELF
$(TARGET).elf: $(TARGET).s link.ld
	$(CC) $(CFLAGS) -o $@ $<

# Bước 2: xuất file ELF -> binary
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# Bước 3: chuyển binary -> hex (với byte order đảo ngược)
prog.hex: $(TARGET).bin
	xxd -e -g4 -c4 $< > $@

# Bước 4: lọc lấy cột dữ liệu cần thiết -> prog_mem.hex
$(TARGET)_mem.hex: prog.hex
	cat $< | awk '{print $$2}' > $@

# Lệnh dọn dẹp file tạm
clean:
	rm -f $(TARGET).elf $(TARGET).bin prog.hex $(TARGET)_mem.hex
