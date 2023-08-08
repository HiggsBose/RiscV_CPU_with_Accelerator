`include "src/defines.v"

module PCExecute (
    input branch, jal, jalr,
    input [2:0] branch_type,
    input [31:0] rs1_data, rs2_data, imm, pc,
    input [3:0] alu_type,

    output reg pc_src,
    output reg[31:0] new_pc
);

    reg zero, less_than;
    reg [31:0] branch_execute_result;

    always @(*) begin
        pc_src = `PC_PLUS4;
        new_pc = 32'b0;
        

        if(jal) begin
            new_pc = pc + imm;    // JAL and JALr is using current PC/register_data to add immediate number to generate the next pc 
            pc_src = `NEW_PC;
        end
        else if(jalr)begin
            new_pc = rs1_data + imm;
            pc_src = `NEW_PC;
        end
        else if(branch) begin
            
            // branch forwarding, to exexute some alu operations in advance when having a branch instr to avoid control hazards.
            case (alu_type)
                `SUB : begin
                branch_execute_result = $signed(rs1_data) - $signed(rs2_data);
                zero = (branch_execute_result == 0) ? 1 : 0;
                less_than = 1'b0;
                end 

                `SLT : begin
                branch_execute_result = $signed(rs1_data) < $signed (rs2_data);
                zero = 1'b0;
                less_than = branch_execute_result ? 1'b1 : 1'b0;
                end 

                `SLTU : begin
                branch_execute_result = rs1_data < rs2_data;
                zero = 1'b0;
                less_than = (branch_execute_result) ? 1'b1 : 1'b0;
                end

                default: begin
                    less_than = 1'b0;
                    zero = 1'b0;
                end
            endcase
            case (branch_type)
                `BEQ: begin
                    if(zero) begin
                        pc_src = `NEW_PC;
                        new_pc = pc + imm;
                    end
                end 
                `BNE: begin
                    if(~zero) begin
                        pc_src = `NEW_PC;
                        new_pc = pc + imm;
                    end
                end
                `BGEU, `BGE: begin
                    if(~less_than) begin
                        pc_src = `NEW_PC;
                        new_pc = pc + imm;
                    end
                end
                `BLTU, `BLT: begin
                    if(less_than) begin
                        pc_src = `NEW_PC;
                        new_pc = pc + imm;
                    end
                end
                default: begin
                    pc_src = `NEW_PC;
                    new_pc = 32'h00000000;
                end 
            endcase
        end

        else begin
            pc_src = `PC_PLUS4;
            new_pc = 32'h00000000;
        end

    end
endmodule
