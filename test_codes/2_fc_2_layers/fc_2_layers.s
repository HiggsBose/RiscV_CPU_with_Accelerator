# 概述：使用拓展指令集计算两层的全连接层网络
# Author: Leesou
# CECA MASS

.org 0x0
    .global _start
_start:

main:
    xori  t0, zero, 0     # 使用t0指代第一层输入矩阵当前tile行的第一个tile的起始地址
    xori  t1, zero, 1024
    addi  t1, t1, 1024    # 使用t1指代第一层输入矩阵的结束地址（开区间）
    xori  t2, zero, 1024
    addi  t2, t2, 1024
    addi  t2, t2, 1024
    addi  t2, t2, 512     # 使用t2指代第一层结果矩阵当前tile行的起始地址
    xori  t3, zero, 1024
    addi  t3, t3, 1024
    addi  t3, t3, 1024
    addi  t3, t3, 1024
    addi  t3, t3, 512     # 使用t3指代第二层结果矩阵当前tile行的起始地址
compute_half_results:
    # 将第一层输入矩阵的(0, 0)或(1, 0) tile加载到systolic array中
    xor   a0, zero, t0    # 第一个参数，指代当前tile在数据存储中的起始地址
    xori  a1, zero, 0     # 第二个参数，指代希望把当前tile传输到哪个buffer上，0x000为脉动阵列西侧的input buffer的起始地址，0x200为脉动阵列北侧的weight buffer的起始地址
    xori  a2, zero, 512   # 第三个参数，指代加速器片上的数据搬运的地址边界
    jal   ra, init_fifo_buffer
    # 将对应位置的权重矩阵加载到systolic array中，
    xori  a0, zero, 1024
    addi  a0, a0, 1024    # 第一层权重矩阵的tile (0, 0)的起始地址是2048
    xori  a1, zero, 512 
    xori  a2, zero, 1024     
    jal   ra, init_fifo_buffer
    # 计算对应的部分和
    nop   # MATMUL        # 0000000 00000 00000 010 00000 1111111, line 22, 0000207f

    # 将第一层输入矩阵的(0, 1)或(1, 1) tile加载到systolic array中
    # 注意到这两个tile计算的是相同位置的部分和，因此可以不读取结果，直接累加
    xor   a0, zero, t0
    addi  a0, a0, 512     # 每块tile大小为512字节
    xori  a1, zero, 0 
    xori  a2, zero, 512     
    jal   ra, init_fifo_buffer
    # 将对应位置的权重矩阵加载到systolic array中
    xori  a0, zero, 1024
    addi  a0, a0, 1024
    addi  a0, a0, 512     # 第一层权重矩阵的tile (1, 0)的起始地址是2048+512
    xori  a1, zero, 512 
    xori  a2, zero, 1024     
    jal   ra, init_fifo_buffer
    # 计算对应的部分和
    nop   # MATMUL        # 0000000 00000 00000 010 00000 1111111, line 34, 0000207f

    # 把第一层当前的输出矩阵tile的结果储存回内存中
    xor   a0, zero, t2
    xori  a1, zero, 1024
    xori  a2, zero, 1536
    jal   ra, save_matmul_outputs
    # 把第一层的这个输出结果的tile搬运到输入buffer中，准备计算第二层对应的结果
    nop   # MOVE          # 0000000 00000 00000 100 00000 1111111, line 39, 0000407f
    # 此时需要把sysolic array的output registers全部清零掉
    xori  a1, zero, 1024
    nop   # RESET a1      # 0000000 01011 00000 011 00000 1111111, line 41, 00b0307f

    # 加载第二层的权重到weight buffer上
    xori  a0, zero, 1024
    addi  a0, a0, 1024
    addi  a0, a0, 1024    # 第二层权重矩阵的tile (0, 0)的起始地址是3072
    xori  a1, zero, 512 
    xori  a2, zero, 1024     
    jal   ra, init_fifo_buffer
    # 计算对应的部分和，由于第二层权重只有一个tile，因此计算得到的就是一部分最终结果
    nop   # MATMUL        # 0000000 00000 00000 010 00000 1111111, line 48, 0000207f

    # 把当前输出矩阵的tile的结果储存回内存中
    xor   a0, zero, t3
    xori  a1, zero, 1024
    xori  a2, zero, 1536
    jal   ra, save_matmul_outputs
    # 此时需要把sysolic array的output registers全部清零掉
    xori  a1, zero, 1024
    nop   # RESET a1      # 0000000 01011 00000 011 00000 1111111, line 54, 00b0307f
 
    # 如果还有tile行没算完，那么跳转回前面的tag再运算一遍
    addi  t0, t0, 1024
    addi  t2, t2, 512
    addi  t3, t3, 512
    blt   t0, t1, compute_half_results

    jal   zero, program_finish  # 全部运算结束


init_fifo_buffer:
        nop    # LOAD  a0, a1 # 0000000 01011 01010 000 00000 1111111, line 60, 00b5007f
        addi   a0, a0, 32
        addi   a1, a1, 32
        blt    a1, a2, init_fifo_buffer
        jalr   zero, ra, 0 # 返回


save_matmul_outputs:
        nop    # SAVE  a0, a1 # 0000000 01011 01010 001 00000 1111111, line 65, 00b5107f
        addi   a0, a0, 32
        addi   a1, a1, 32
        blt    a1, a2, save_matmul_outputs
        jalr   zero, ra, 0 # 返回


program_finish:
    nop
