`include "src/defines.v"

module ALU (
    input [3:0] alu_type,
    input [31:0] op1, op2,
    output reg [31:0] alu_result
);
    always @(*) begin
        case (alu_type)
            `ADD    :  alu_result = op1 + op2;
            `SUB    :  alu_result = $signed(op1) - $signed(op2);
            `SLL    :  alu_result = op1 << op2;      
            `SLT    :  alu_result = $signed(op1) < $signed (op2);             
            `SLTU   :  alu_result = op1 < op2;            
            `XOR    :  alu_result = op1 ^ op2;            
            `SRL    :  alu_result = op1 >> op2;            
            `OR     :  alu_result = op1 | op2;            
            `AND    :  alu_result = op1 & op2;            
            `SRA    :  alu_result = $signed(op1) >>> op2;
            default :  alu_result = 32'b0;
        endcase 
    end

endmodule