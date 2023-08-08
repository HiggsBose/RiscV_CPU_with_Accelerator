`include "src/defines.v"


module ID_EX_REG (
    input clk, rst, stall_ex, bubble_ex,

    input branch_id, jal_id, jalr_id,
    input mem_read_id, mem_write_id,
    input alu_src1_id, alu_src2_id,

    input reg_write_id,
    input [1:0] reg_src_id,
    input [2:0] instr_funct3_id,
    input [3:0] alu_type_id,

    input [4:0] rs1_id, rs2_id, rd_id,
    input [31:0] rs1_data_id, rs2_data_id,

    input [31:0] imm_id,
    input [31:0] pc_id, pc_plus4_id,

    input accelerator_instr_id,

    output mem_read_ex, mem_write_ex,
    output [31:0] imm_ex,
    output reg_write_ex,
    output [2:0] instr_funct3_ex,
    output [1:0] reg_src_ex,
    output [4:0] rd_ex, 

    output [31:0] pc_ex, pc_plus4_ex,

    output alu_src1_ex, alu_src2_ex,
    output [3:0] alu_type_ex,
    
    output [4:0]rs1_ex, rs2_ex,
    output [31:0] rs1_data_ex, rs2_data_ex,

    output accelerator_instr_ex
);

    PipeDff #(.WIDTH(160))a(
        .clk(clk),
        .rst(rst),
        .bubble(bubble_ex),
        .stall(stall_ex),
        .data_in({rs1_data_id, rs2_data_id, imm_id, pc_id, pc_plus4_id}),
        .default_val(160'b0),
        .data_out({rs1_data_ex, rs2_data_ex, imm_ex, pc_ex, pc_plus4_ex})
    );

    PipeDff #(.WIDTH(8)) b(
        .clk(clk),
        .rst(rst),
        .bubble(bubble_ex),
        .stall(stall_ex),
        .data_in({mem_read_id, mem_write_id, reg_write_id, instr_funct3_id, reg_src_id}),
        .default_val(8'b0),
        .data_out({mem_read_ex, mem_write_ex, reg_write_ex, instr_funct3_ex, reg_src_ex})
    );

    PipeDff #(.WIDTH(22)) c(
        .clk(clk),
        .rst(rst),
        .bubble(bubble_ex),
        .stall(stall_ex),
        .data_in({rd_id, alu_src1_id, alu_src2_id, alu_type_id, rs1_id, rs2_id, accelerator_instr_id}),
        .default_val(22'b0),
        .data_out({rd_ex, alu_src1_ex, alu_src2_ex, alu_type_ex, rs1_ex, rs2_ex, accelerator_instr_ex})
    );
endmodule
