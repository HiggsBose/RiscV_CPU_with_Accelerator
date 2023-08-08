`include "src/defines.v"

module WB (
    input [1:0] reg_src_wb,
    input [31:0] alu_result_wb,
    input [31:0] mem2reg_data_wb,
    input [31:0] imm_wb,
    input [31:0] nxpc_wb,

    output reg [31:0] reg_write_data_wb
);
    
    always @(*) begin
        case (reg_src_wb)
            `FROM_ALU : reg_write_data_wb = alu_result_wb;
            `FROM_IMM : reg_write_data_wb = imm_wb;
            `FROM_MEM : reg_write_data_wb = mem2reg_data_wb;
            `FROM_PC  : reg_write_data_wb = nxpc_wb; 
            default: reg_write_data_wb = 'b0; 
        endcase
    end

endmodule
