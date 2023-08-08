`include "src/defines.v"

module ImmGen (
    input [31:0] instr,
    output reg [31:0] imm
);
    always @(*) begin
        case (instr[6:0])
            `INST_TYPE_R    :   imm = 32'b0;
            `INST_TYPE_B    :   imm = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};
            `INST_TYPE_I    :   begin
                if(instr[13:12]==2'b01) imm = {27'b0,instr[24:20]}; // shift amount
                else imm = {{20{instr[31]}},instr[31:20]};
            end //for shift, not sure
            `INST_TYPE_L    :   imm = {{20{instr[31]}},instr[31:20]};
            `INST_TYPE_S    :   imm = {{20{instr[31]}},instr[31:25],instr[11:8],instr[7]};
            `INST_AUIPC     :   imm = {instr[31:12],12'b0};
            `INST_JAL       :   imm = {{12{instr[31]}},instr[19:12],instr[20],instr[30:25],instr[24:21],1'b0};
            `INST_JALR      :   imm = {{20{instr[31]}},instr[31:20]};
            `INST_LUI       :   imm = {instr[31:12],12'b0};
            default: imm = 32'b0;
        endcase
    end    
endmodule
