// OP codes
`define INST_TYPE_R 7'b0110011
`define INST_TYPE_I 7'b0010011
`define INST_TYPE_L 7'b0000011
`define INST_TYPE_S 7'b0100011
`define INST_TYPE_B 7'b1100011
`define INST_LUI    7'b0110111
`define INST_AUIPC  7'b0010111
`define INST_JAL    7'b1101111
`define INST_JALR   7'b1100111
// ISA extension
`define INST_ACC    7'b1111111

// for ALU control
`define ALU_OP_B    2'b01
`define ALU_OP_R    2'b10
`define ALU_OP_I    2'b11

// operation encoding in ALU
`define ADD   4'b0000
`define SLL   4'b0001
`define SLT   4'b0010
`define SLTU  4'b0011
`define XOR   4'b0100
`define SRL   4'b0101
`define OR    4'b0110
`define AND   4'b0111
`define SUB   4'b1000
`define SRA   4'b1101

// funct3 for arithmetic operations
`define SR_FUNCT3  3'b101
`define SLL_FUNCT3 3'b001

// funct3 for B-Type instructions
`define BEQ  3'b000
`define BNE  3'b001
`define BLT  3'b100
`define BGE  3'b101
`define BLTU 3'b110
`define BGEU 3'b111

// funct3 for L-Type instructions
`define LB  3'b000
`define LH  3'b001
`define LW  3'b010
`define LBU 3'b100
`define LHU 3'b101

// funct3 for S-Type instructions
`define SB 3'b000
`define SH 3'b001
`define SW 3'b010

// funct3 for accelerator ISA extension
`define LOAD   3'b000
`define SAVE   3'b001
`define MATMUL 3'b010
`define RESET  3'b011
`define MOVE   3'b100

// register data's src
`define FROM_ALU 2'b00
`define FROM_MEM 2'b01
`define FROM_IMM 2'b10
`define FROM_PC  2'b11

// default values
`define PC_RST    32'h00000000
`define INST_NOP  32'h00000013 // addi x0, x0, 0
`define ZERO_WORD 32'h00000000
`define ZERO_REG  5'b00000

// forwarding options in EX stage
`define NO_FWD  2'b00
`define FWD_MEM 2'b01
`define FWD_WB  2'b10

// definitions for base addresses of bus slaves
`define INSTR_MEM_BASE_ADDR       32'h00000000
`define DATA_MEM_BASE_ADDR        32'h10000000
`define ACCELERATOR_MEM_BASE_ADDR 32'h20000000

// definitions for systolic array accelerator
`define INPUT_FIFO_BASE_ADDR    32'h00000000
`define WEIGHT_FIFO_BASE_ADDR   32'h00000200
`define OUTPUT_BUFFER_BASE_ADDR 32'h00000400
`define MOVE_ADDR               32'h00000600


// for pc control
`define PC_PLUS4 1'b0
`define NEW_PC   1'b1 

// alu operands' source
`define REG 1'b0
`define IMM 1'b1
`define PC  1'b1 
