`include "src/dp_components/alu.v"
`include "src/defines.v"
`include "src/dp_components/op_sel.v"
`include "src/dp_components/Real_rs_gen.v"

module EX (
    input alu_src1_ex, alu_src2_ex,
    input [3:0] alu_type_ex,
    input [31:0] pc_ex,
    input [31:0] rs1_data_ex, rs2_data_ex,
    input [31:0] imm_ex,
    input [31:0] reg_write_data_wb, reg_write_data_mem,
    input [4:0] rs1_ex, rs2_ex,
    input [1:0] rs1_fwd_ex, rs2_fwd_ex,

    output [31:0] alu_result_ex,
    output [31:0] real_rs2_data_ex,
    output [31:0] real_rs1_data_ex

);

    wire [31:0] op1, op2;
    wire [31:0] real_rs1_data, real_rs2_data;

    ALU alu(
        .alu_type(alu_type_ex),
        .op1(op1),
        .op2(op2),
        .alu_result(alu_result_ex)
    );

    OpSelector operand_selector(
        .alu_src1(alu_src1_ex),
        .alu_src2(alu_src2_ex),
        .pc(pc_ex),
        .imm(imm_ex),
        .rs1_data(real_rs1_data),
        .rs2_data(real_rs2_data),

        .op1(op1),
        .op2(op2)
    );

    Real_rs_Gen real_rs_generator(
        .rs1_fwd_ex(rs1_fwd_ex),
        .rs2_fwd_ex(rs2_fwd_ex),
        .rs1_data(rs1_data_ex),
        .rs2_data(rs2_data_ex),
        .reg_write_data_mem(reg_write_data_mem),
        .reg_write_data_wb(reg_write_data_wb),

        .real_rs1_data(real_rs1_data),
        .real_rs2_data(real_rs2_data)

    );
    
    assign real_rs1_data_ex = real_rs1_data;
    assign real_rs2_data_ex = real_rs2_data;
endmodule