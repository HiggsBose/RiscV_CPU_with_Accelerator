`include "src/defines.v"
module OpSelector (
    input alu_src1, alu_src2,
    input[31:0] pc, imm, rs1_data, rs2_data,
    output wire[31:0] op1, op2
);
    assign op1 = (alu_src1 == `REG) ? rs1_data : pc;
    assign op2 = (alu_src2 == `REG) ? rs2_data : imm;
    
endmodule