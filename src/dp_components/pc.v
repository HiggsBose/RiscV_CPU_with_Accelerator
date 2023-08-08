`include "src/defines.v"

module PC (
    input clk,
    input rst,
    input stall, bubble,
    input [31:0] new_pc, pc_plus4,
    input pc_src,

    output reg [31:0] pc
);
    always @(posedge clk) begin
        if(rst)
        begin
            pc <= 32'b0;
        end
        else if(stall)begin
            pc <= pc;   // when instrcution fetch is stalled or a bubble is inserted
            //, the pc should not change and the next clk cycle should fetch the same instruction 
        end
        else begin
            if(pc_src == `NEW_PC) pc <= new_pc;
            else if(pc_src == `PC_PLUS4) pc <= pc_plus4;
            else pc <= 32'hffffffff;
        end
    end
    
endmodule
