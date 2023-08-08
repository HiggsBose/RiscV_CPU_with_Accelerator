`include "src/defines.v"

module MEM_WB_REG (
    input clk, rst, bubble_wb, stall_wb, 

    input [31:0] mem2reg_data,
    
    input reg_write_mem, 
    input [1:0] reg_src_mem,
    input [4:0] rd_mem,
    input [31:0] alu_result_mem,
    input [31:0] imm_mem,
    input [31:0] pc_plus4_mem,

    output [1:0] reg_src_wb,
    output [31:0] alu_result_wb,
    output [31:0] mem2reg_data_wb,
    output [31:0] imm_wb,
    output [31:0] nxpc_wb,
    output reg_write_wb,
    output [4:0] rd_wb
);
    PipeDff #(.WIDTH(128))abc(
        .clk(clk),
        .rst(rst),
        .bubble(bubble_wb),
        .stall(stall_wb),
        .data_in({mem2reg_data, alu_result_mem, imm_mem, pc_plus4_mem}),
        .default_val(128'b0),
        .data_out({mem2reg_data_wb, alu_result_wb, imm_wb, nxpc_wb})
    );

    PipeDff #(.WIDTH (8)) a(
        .clk(clk),
        .rst(rst),
        .bubble(bubble_wb),
        .stall(stall_wb),
        .data_in({reg_write_mem, reg_src_mem, rd_mem}),
        .default_val(8'b0),
        .data_out({reg_write_wb, reg_src_wb, rd_wb})
    );
    
endmodule
