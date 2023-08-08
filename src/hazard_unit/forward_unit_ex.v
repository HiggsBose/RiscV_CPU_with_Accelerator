`include "src/defines.v"

module FWD_EX (
    input reg_write_wb,
    input [4:0] rd_wb,
    input [4:0] rs1_ex, rs2_ex,
    input reg_write_mem,
    input [4:0] rd_mem,

    output reg [1:0] rs1_fwd_ex, rs2_fwd_ex
);
    
    always @(*) begin
        rs1_fwd_ex = `NO_FWD;
        rs2_fwd_ex = `NO_FWD;
        if(reg_write_wb) begin
            if(rs1_ex == rd_wb & rs1_ex != 0) rs1_fwd_ex = `FWD_WB;
            if(rs2_ex == rd_wb & rs2_ex != 0) rs2_fwd_ex = `FWD_WB;
        end

        // when load and write back have the same hazard, the execute stage should choose to use the data
        // that is nearer to the execute stage, that is, the data from the mem stage
        if(reg_write_mem) begin
            if(rs1_ex == rd_mem & rs1_ex != 0) rs1_fwd_ex = `FWD_MEM;
            if(rs2_ex == rd_mem & rs2_ex != 0) rs2_fwd_ex = `FWD_MEM; 
        end
    end

endmodule
