    .section .text
    .globl _start

    # Định nghĩa địa chỉ các thanh ghi memory-mapped
    .equ FIFO1_STATUS, 0x30000000
    .equ FIFO1_POP,    0x30000004
    .equ FIFO2_PUSH,   0x30000008
    .equ CTRL_REG,     0x30000010
    .equ RAM_BASE,     0x00000400

_start:
    # x5 = FIFO1_STATUS base
    lui x5, %hi(FIFO1_STATUS)
    addi x5, x5, %lo(FIFO1_STATUS)

wait_full:
    lw   x6, 0(x5)        # read status
    andi x7, x6, 1        # check fifo1_full bit
    beqz x7, wait_full    # loop until full (đợi FIFO có 2 từ)

    # x8 = RAM_BASE
    lui x8, %hi(RAM_BASE)
    addi x8, x8, %lo(RAM_BASE)

    # x9 = FIFO1_POP
    lui x9, %hi(FIFO1_POP)
    addi x9, x9, %lo(FIFO1_POP)

    addi x10, x0, 0       # i = 0
read_loop:
    lw   x11, 0(x9)       # read fifo1 data
    slli x12, x10, 0x2    # offset = i*4
    add  x13, x8, x12     # addr = RAM_BASE + offset
    sw   x11, 0(x13)      # store to RAM
    addi x10, x10, 1
    li   x14, 1023          # chỉ đọc 2 từ
    blt  x10, x14, read_loop

    # Write to CTRL_REG: start
    lui x15, %hi(CTRL_REG)
    addi x15, x15, %lo(CTRL_REG)
    li   x16, 1
    sw   x16, 0(x15)

    # Push loop
    addi x10, x0, 0       # i = 0
push_loop:
    slli x12, x10, 0x2
    add  x13, x8, x12
    lw   x11, 0(x13)      # đọc dữ liệu từ RAM[i]

    # ==== THAY ĐỔI ở đây ====
    beq  x10, x0, skip_push   # nếu i == 0 thì bỏ qua không push
    # ========================

    lui  x17, %hi(FIFO2_PUSH)
    addi x17, x17, %lo(FIFO2_PUSH)
    sw   x11, 0(x17)      # ghi dữ liệu vào FIFO2

skip_push:
    addi x10, x10, 1
    li   x14, 1022           # chỉ push 2 từ (có thể sửa thành 2)
    blt  x10, x14, push_loop

    # clear CTRL_REG
    sw   x0, 0(x15)

hang:
    j hang