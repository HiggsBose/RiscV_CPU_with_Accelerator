`include "src/defines.v"

module IF_ID_REG #(
    parameter WIDTH = 32
) (
    input stall_id, bubble_id, clk, rst,
    input [WIDTH-1:0] instr_if, pc_if, pc_plus4_if,
    output [WIDTH-1:0] instr_id, pc_id, pc_plus4_id
);
    PipeDff instr(
        .clk(clk),
        .rst(rst),
        .bubble(bubble_id),
        .stall(stall_id),
        .data_in(instr_if),
        .default_val(`INST_NOP), //don't know default value
        .data_out(instr_id)
    );

    PipeDff pc(
        .clk(clk),
        .rst(rst),
        .bubble(bubble_id),
        .stall(stall_id),
        .data_in(pc_if),
        .default_val(`PC_RST), //don't know default value
        .data_out(pc_id)
    );

    PipeDff pc_plus4(
        .clk(clk),
        .rst(rst),
        .bubble(bubble_id),
        .stall(stall_id),
        .data_in(pc_plus4_if),
        .data_out(pc_plus4_id),
        .default_val(`PC_RST)  //don't know default value
    );
endmodule
