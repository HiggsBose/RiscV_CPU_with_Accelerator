`include "src/defines.v"

module ADD (
    input[31:0] pc,
    output reg[31:0] pc_plus4
);
    always @(*) begin
        pc_plus4 = pc + 32'd4;
    end
    
endmodule