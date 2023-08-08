`include "src/defines.v"

module FWD_ID (
    input reg_write_mem,
    input [4:0] rd_mem,
    input branch_id, jal_id, jalr_id,
    input [4:0] rs1_id, rs2_id,

    output reg [1:0] rs1_fwd_id, rs2_fwd_id
);
    // used for forwarding to PC_execute
    always @(*) begin
        rs1_fwd_id = `NO_FWD;
        rs2_fwd_id = `NO_FWD;

        if(reg_write_mem)begin
            if(branch_id | jalr_id) begin
                rs1_fwd_id = (rs1_id == rd_mem & rs1_id != 0) ? `FWD_MEM : `NO_FWD;
                rs2_fwd_id = (rs2_id == rd_mem & rs2_id != 0) ? `FWD_MEM : `NO_FWD;
            end
        end
        
    end  
endmodule
