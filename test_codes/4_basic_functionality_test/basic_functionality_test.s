# 概述：使用拓展指令集计算两层的全连接层网络
# Author: Leesou
# CECA MASS

.org 0x0
    .global _start
_start:

main:
    xor   a0, x0, x0  # 第一个参数，指代当前tile在数据存储中的起始地址
    xor   a1, x0, x0  # 第二个参数，指代希望把当前tile传输到哪个buffer上，0x000为脉动阵列西侧的input buffer的起始地址，0x200为脉动阵列北侧的weight buffer的起始地址
    nop   # LOAD  a0, a1 # 0000000 01011 01010 000 00000 1111111

    xori  a0, x0, 1024
    add   a0, a0, a0
    xori  a1, x0, 512
    nop   # LOAD a0, a1 # 0000000 01011 01010 000 00000 1111111

    nop   # MATMUL      # 0000000 00000 00000 010 00000 1111111

    xori  a0, x0, 512  # 第一个参数，指代当前tile在数据存储中的起始地址
    xor   a1, x0, x0  # 第二个参数，指代希望把当前tile传输到哪个buffer上，0x000为脉动阵列西侧的input buffer的起始地址，0x200为脉动阵列北侧的weight buffer的起始地址
    nop   # LOAD  a0, a1 # 0000000 01011 01010 000 00000 1111111

    xori  a0, x0, 1024
    add   a0, a0, a0
    addi  a0, a0, 512
    xori  a1, x0, 512
    nop   # LOAD a0, a1 # 0000000 01011 01010 000 00000 1111111

    nop   # MATMUL      # 0000000 00000 00000 010 00000 1111111

    xori  a0, x0, 1024
    addi  a0, a0, 1024
    addi  a0, a0, 1024
    addi  a0, a0, 512
    xori  a1, x0, 1024
    nop   # SAVE a0, a1 # 0000000 01011 01010 001 00000 1111111

    nop   # MOVE        # 0000000 00000 00000 100 00000 1111111
    nop   # RESET a1    # 0000000 01011 00000 011 00000 1111111

    xori  a0, x0, 1024
    addi  a0, a0, 1024
    addi  a0, a0, 1024
    xori  a1, x0, 512
    nop   # LOAD a0, a1 # 0000000 01011 01010 000 00000 1111111

    nop   # MATMUL      # 0000000 00000 00000 010 00000 1111111

    xori  a0, x0, 1024
    addi  a0, a0, 1024
    addi  a0, a0, 1024
    addi  a0, a0, 1024
    addi  a0, a0, 512
    xori  a1, x0, 1024
    nop   # SAVE a0, a1 # 0000000 01011 01010 001 00000 1111111

    jal   zero, program_finish  # 全部运算结束


program_finish:
    # 使用从未访问过的地址段清空所有的cache line，便于检验算法运行结果的正确性
    xor x30, x30, x30
    addi x30, x30, 1008
    slli x31, x30, 8    # base address: 0x3f000 (tag: 0x3f0)
    addi x30, x30, 16
    slli x30, x30, 8    # end address: 0x3ff00 (tag: 0x3ff)
flush_line:
    lw x0, 0(x31)
    lw x0, 32(x31)
    lw x0, 64(x31)
    lw x0, 96(x31)
    lw x0, 128(x31)
    lw x0, 160(x31)
    lw x0, 192(x31)
    lw x0, 224(x31)
    addi x31, x31, 256
    blt x31, x30, flush_line
