`include "src/defines.v"

module HazardDetect (
    input clk,
    input rst,
    input pc_src_id, jal_id, jalr_id, branch_id,
    input [4:0] rs1_id, rs2_id,
    input mem_read_ex,
    input [4:0] rd_ex,
    input [4:0] rd_mem,
    input mem_read_mem,
    input request_finish,
    input stall_flag,

    output reg stall_if, bubble_if,
    output reg stall_id, bubble_id,
    output reg stall_ex, bubble_ex,
    output reg stall_mem, bubble_mem,
    output reg stall_wb, bubble_wb
);
    // structural hazard is never raised, because we seperate the two memory 
    // and the register file visit is seperated

    // normal read before write hazard is avoided by adding forwarding paths

    // Load-Use hazard is raised when the following instruction need the register in the execution stage
    always @(*) begin
        {stall_if, bubble_if, stall_id, bubble_id, stall_ex, bubble_ex, 
        stall_mem, bubble_mem, stall_wb, bubble_wb} = 10'b0;
        if (rst) begin
            {stall_if, bubble_if, stall_id, bubble_id, stall_ex, bubble_ex, 
        stall_mem, bubble_mem, stall_wb, bubble_wb} = 10'b0;
        end
        else begin
            if(stall_flag & ~request_finish)begin
                stall_if = 1'b1;
                stall_id = 1'b1;
                stall_ex = 1'b1;
                stall_mem = 1'b1;
                stall_wb = 1'b1;
            end

            // when branch or jump happens, flush the instruction fetch stage
            else if(branch_id | jal_id | jalr_id) begin
                if(pc_src_id == `NEW_PC) bubble_if = 1'b1;
                if((rd_ex == rs1_id | rd_ex == rs2_id) & rd_ex != 5'b0) begin
                    stall_if = 1'b1;  // IDN
                    bubble_if = 1'b0;
                    stall_id = 1'b1;
                    bubble_ex <= 1'b1;
                end

            end
        end 
        
    end
    
endmodule
