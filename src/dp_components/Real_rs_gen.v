`include "src/defines.v"

module Real_rs_Gen (
    input [1:0] rs1_fwd_ex, rs2_fwd_ex,
    input [31:0] rs1_data, rs2_data, reg_write_data_mem, reg_write_data_wb,

    output reg [31:0] real_rs1_data, real_rs2_data
);
    always @(*) begin
        case (rs1_fwd_ex)
            `NO_FWD : real_rs1_data = rs1_data;
            `FWD_MEM : real_rs1_data = reg_write_data_mem;
            `FWD_WB : real_rs1_data = reg_write_data_wb; 
            default: real_rs1_data = rs1_data;
        endcase
        case (rs2_fwd_ex)
            `NO_FWD : real_rs2_data = rs2_data;
            `FWD_MEM : real_rs2_data = reg_write_data_mem;
            `FWD_WB : real_rs2_data = reg_write_data_wb; 
            default: real_rs2_data = rs2_data;
        endcase
    end
    
endmodule
