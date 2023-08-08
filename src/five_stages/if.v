`include "src/dp_components/pc.v"
`include "src/dp_components/add.v"

module IF #(parameter WIDTH = 32)
    (
    input clk, rst,
    input stall_if, bubble_if,
    input pc_src,
    input [WIDTH-1:0] pc_new,
    output [WIDTH-1:0] pc_if, pc_plus4_if,
    output [WIDTH-1:0] instr_addr 
);
    wire [WIDTH-1:0] pc, pc_plus4;
    
    ADD adder(
        .pc(pc),
        .pc_plus4(pc_plus4)
    );

    PC program_counter(
        .clk(clk),
        .rst(rst),
        .new_pc(pc_new),
        .pc_plus4(pc_plus4),
        .pc_src(pc_src),
        .pc(pc),
        .stall(stall_if),
        .bubble(bubble_if)
    );

    

    assign pc_plus4_if = pc_plus4;
    assign pc_if = pc;
    assign instr_addr = pc;

endmodule
