`include "src/defines.v"

module MEM_MODULE (
    input mem_read_mem, mem_write_mem,
    input [2:0] instr_funct3_mem,
    input [31:0] rs2_data_mem,
    input [31:0] alu_result_mem,
    input [31:0] mem_read_data,
    input [1:0] reg_src_mem,
    input [31:0] imm_mem, pc_plus4_mem,

    output mem_write,
    output [2:0] write_type,
    output [31:0] mem_addr,
    output [31:0] write_data,
    output reg [31:0] mem2reg_data,
    output reg [31:0] reg_write_data_mem,
    output stall_flag
);
    // when there is memory access, then the flag should be 1, in case there is a 
    assign stall_flag = (mem_read_mem | mem_write_mem);     

    always @(*) begin
        if(mem_read_mem)begin
            case (instr_funct3_mem)
            `LW     :   mem2reg_data = mem_read_data;
            `LB     :   mem2reg_data = {{24{mem_read_data[7]}}, mem_read_data[7:0]};
            `LBU    :   mem2reg_data = {24'b0, mem_read_data[7:0]};
            `LH     :   mem2reg_data = {{16{mem_read_data[15]}}, mem_read_data[15:0]};
            `LHU    :   mem2reg_data = {16'b0, mem_read_data[15:0]};
            default :   mem2reg_data = 32'b0; 
        endcase
        end
       
        case (reg_src_mem)
            `FROM_ALU : reg_write_data_mem = alu_result_mem;
            `FROM_IMM : reg_write_data_mem = imm_mem;
            `FROM_MEM : reg_write_data_mem = mem2reg_data;
            `FROM_PC  : reg_write_data_mem = pc_plus4_mem; 
            default: reg_write_data_mem = 'b0; 
        endcase
    end
    
    assign mem_write = mem_write_mem;
    assign write_type = instr_funct3_mem;
    assign mem_addr = alu_result_mem;
    assign write_data = rs2_data_mem;
    
    

endmodule
