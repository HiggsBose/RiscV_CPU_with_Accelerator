`include "src/defines.v"

module EX_MEM_REG (
    input clk, rst, stall_mem, bubble_mem,

    input mem_read_ex, mem_write_ex, reg_write_ex,  
    input [31:0] imm_ex,
    input [2:0] instr_funct3_ex,
    input [1:0] reg_src_ex,
    input [4:0] rd_ex,
    input [31:0] pc_plus4_ex,
    input [31:0] rs2_data_ex, alu_result_ex,

    input accelerator_instr_ex,
    input [31:0] rs1_data_ex,

    output reg_write_mem,
    output [1:0] reg_src_mem,
    output [4:0] rd_mem, 
    output [31:0] alu_result_mem, imm_mem, pc_plus4_mem,

    output mem_read_mem, mem_write_mem,
    output [2:0] instr_funct3_mem,
    output [31:0] rs2_data_mem,

    output  accelerator_instr_mem,
    output [31:0] rs1_data_mem

);

    PipeDff #(.WIDTH(128)) a (
        .clk(clk),
        .rst(rst),
        .stall(stall_mem),
        .bubble(bubble_mem),

        .data_in({alu_result_ex, imm_ex, pc_plus4_ex, rs2_data_ex}),
        .default_val(128'b0),
        .data_out({alu_result_mem, imm_mem, pc_plus4_mem, rs2_data_mem})
    );

    PipeDff #(.WIDTH(14)) b (
        .clk(clk),
        .rst(rst),
        .stall(stall_mem),
        .bubble(bubble_mem),

        .data_in({reg_write_ex, reg_src_ex, rd_ex, mem_read_ex, mem_write_ex, instr_funct3_ex, accelerator_instr_ex}),
        .default_val(14'b0),
        .data_out({reg_write_mem, reg_src_mem, rd_mem, mem_read_mem, mem_write_mem, instr_funct3_mem, accelerator_instr_mem})
    );

    PipeDff #(.WIDTH(32)) c(
        .clk(clk),
        .rst(rst),
        .stall(stall_mem),
        .bubble(bubble_mem),

        .data_in(rs1_data_ex),
        .default_val(32'b0),
        .data_out(rs1_data_mem)
    );


endmodule
