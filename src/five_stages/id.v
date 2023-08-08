`include "src/dp_components/regfile.v"
`include "src/dp_components/imm_gen.v"
`include "src/dp_components/pc_ex.v"
`include "src/cp_components/control_unit.v"

module ID (
    input clk,
    input rst,

    input [31:0] instr_id,

    input [31:0] pc_id,

    input [31:0] reg_write_data_mem,
    input [31:0] reg_write_data_wb,

    input reg_write_wb,
    input [4:0] rd_wb,

    input [1:0] rs1_fwd_id, rs2_fwd_id,

    output branch_id, jal_id, jalr_id,  //not implemented

    output [2:0] instr_funct3_id,

    output pc_src,
    output [31:0] new_pc,

    output mem_read_id, mem_write_id,

    output alu_src1_id, alu_src2_id,
    output [3:0] alu_type_id,

    output [1:0] reg_src_id,
    output reg_write_id,
    output [4:0] rs1_id, rs2_id, rd_id, //not implemented
    output [31:0] rs1_data_id, rs2_data_id,
    
    output [31:0] imm_id,

    output accelerator_instr_id

);

    wire [4:0] read_addr1, read_addr2, write_addr;
    wire [31:0] real_rs1_data, real_rs2_data;

    
    PCExecute pc_execute(
        .branch(branch_id),
        .jal(jal_id),
        .jalr(jalr_id),
        .branch_type(instr_funct3_id),

        .rs1_data(real_rs1_data),
        .rs2_data(real_rs2_data),
        .imm(imm_id),
        .pc(pc_id),
        .alu_type(alu_type_id),

        .pc_src(pc_src),
        .new_pc(new_pc)
    );

    ControlUnit control_unit(
        .rst(rst),
        .instr(instr_id),

        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .write_addr(write_addr),

        .branch(branch_id),
        .jal(jal_id),
        .jalr(jalr_id),

        .mem_read(mem_read_id),
        .mem_write(mem_write_id),

        .alu_src1(alu_src1_id),
        .alu_src2(alu_src2_id),
        .alu_type(alu_type_id),

        .reg_src(reg_src_id),

        .reg_write_enable(reg_write_id),

        .instr_funct3(instr_funct3_id),

        .accelerator_instr_id(accelerator_instr_id)
    );

    ImmGen immedaite_generator(
        .instr(instr_id),
        .imm(imm_id)
    );

    RegFile register_file(
        .clk(clk),
        .rst(rst),

        .write_enable(reg_write_wb),

        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .write_addr(rd_wb),

        .write_data(reg_write_data_wb),
        .read_data1(rs1_data_id),
        .read_data2(rs2_data_id)
    );

    // choose whether to use the forwarded data for pc_execute
    assign real_rs1_data = (rs1_fwd_id == `FWD_MEM) ? reg_write_data_mem : rs1_data_id;
    assign real_rs2_data = (rs2_fwd_id == `FWD_MEM) ? reg_write_data_mem : rs2_data_id;

    // Potential risks of false hazard!!!! Sometimes the register file won't be used, but it is still read. 
    assign rs1_id = read_addr1;
    assign rs2_id = read_addr2;
    assign rd_id  = write_addr;
endmodule
