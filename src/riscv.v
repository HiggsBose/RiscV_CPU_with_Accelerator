`include "src/defines.v"
`include "src/five_stages/if.v"
`include "src/five_stages/id.v"
`include "src/five_stages/ex.v"
`include "src/five_stages/mem.v"
`include "src/five_stages/wb.v"
`include "src/templates/pipe_dff.v"
`include "src/pipe_regs/if_id.v"
`include "src/pipe_regs/id_ex.v"
`include "src/pipe_regs/ex_mem.v"
`include "src/pipe_regs/mem_wb.v"
`include "src/hazard_unit/forward_unit_id.v"
`include "src/hazard_unit/forward_unit_ex.v"
`include "src/hazard_unit/hazard_detect_unit.v"
// add cache in Lab 5
`include "src/dp_components/data_cache.v"

// Your RISCVPipeline Module Here:
module RISCVPipeline #(
    parameter LINE_ADDR_LEN = 3
)(
    input clk, rst, debug,
    // for instr rom
    input [31:0] instr,
    output [31:0] instr_addr,
    // for main memory
    output data_bus_read_request, data_bus_write_request,
    output [(32*(1<<LINE_ADDR_LEN)-1):0] data_bus_write_data,
    output [31:0] data_bus_addr,
    input data_bus_request_finish,
    input [(32*(1<<LINE_ADDR_LEN)-1):0] data_bus_read_data
);
    wire [31:0] pc_if, pc_plus4_if, pc_id, pc_plus4_id, pc_ex, pc_plus4_ex, pc_plus4_mem, nxpc_wb;
    wire [31:0] instr_if, instr_id;
    wire [1:0] reg_src_id, reg_src_ex, reg_src_mem, reg_src_wb;
    wire [2:0] instr_funct3_id, instr_funct3_ex, instr_funct3_mem;
    wire [3:0] alu_type_id, alu_type_ex;

    wire [4:0] rs1_id, rs2_id, rs1_ex, rs2_ex;
    wire [4:0] rd_id, rd_ex, rd_mem, rd_wb;
    wire [31:0] rs1_data_id, rs2_data_id, rs1_data_ex, rs2_data_ex, real_rs2_data_ex, real_rs1_data_ex, rs2_data_mem, rs1_data_mem; 
    wire [31:0] imm_id, imm_ex, imm_mem, imm_wb; 

    wire [31:0] reg_write_data_mem, reg_write_data_wb;

    wire [31:0] alu_result_ex, alu_result_mem, alu_result_wb;

    wire [31:0] mem2reg_data, mem2reg_data_wb;

    wire [31:0] new_pc;

    wire [1:0] rs1_fwd_ex, rs1_fwd_id, rs2_fwd_ex, rs2_fwd_id;

    wire [31:0] cache_write_data;
    wire [31:0] addr;
    wire [31:0] read_data;
    wire [2:0] write_type;

    // original CPU interface with main memory
    wire mem_read_request, mem_write_request;
    wire [(32*(1<<LINE_ADDR_LEN)-1):0] mem_write_data;
    wire [31:0] mem_addr;
    wire mem_request_finish;
    wire [(32*(1<<LINE_ADDR_LEN)-1):0] mem_read_data;

    // additional interface for accelerator ISA extension
     // instruction indication signal
    wire accelerator_instr_id, accelerator_instr_ex, accelerator_instr_mem;
    // wires for signal muxing between accelerator instruction and RISC-V memory instruction
    // accelerator bus wires
    reg accelerator_bus_read_request, accelerator_bus_write_request;
    reg [31:0] accelerator_bus_addr;
    wire [(32*(1<<LINE_ADDR_LEN)-1):0] accelerator_bus_write_data; 
    reg [(32*(1<<LINE_ADDR_LEN)-1):0] accelerator_bus_read_data;
    // accelerator cache wires
    wire accelerator_cache_read_request, accelerator_cache_write_request;
    wire [(32*(1<<LINE_ADDR_LEN)-1):0] accelerator_cache_write_data, accelerator_cache_read_data;
    // // cache wires, need to be muxed between accelerator and memory
    // wire cache_read_request, cache_write_request, cache_request_from_accelerator;
    // wire [(32*(1<<LINE_ADDR_LEN)-1):0] cache_write_line_data, cache_read_line_data;
    // wire [2:0] cache_write_type;
    // wire [31:0] cache_write_data;


    IF instrcution_fetch_stage(
        .clk(clk),
        .rst(rst),
        .stall_if(stall_if),
        .bubble_if(bubble_if),
        .pc_src(pc_src_id),
        .pc_new(new_pc),
        .pc_if(pc_if),
        .pc_plus4_if(pc_plus4_if),
        .instr_addr(instr_addr)
    );

    IF_ID_REG if_id_register(
        .stall_id(stall_id),
        .bubble_id(bubble_id),
        .clk(clk),
        .instr_if(instr_if),
        .pc_if(pc_if),
        .pc_plus4_if(pc_plus4_if),
        .instr_id(instr_id),   
        .pc_id(pc_id),      
        .pc_plus4_id(pc_plus4_id)
    );

    assign instr_if = (bubble_if) ? `INST_NOP : instr; 

    ID instruction_decode_stage(
        .clk(clk),
        .rst(rst),
        .instr_id(instr_id),
        .pc_id(pc_id),
        .reg_write_wb(reg_write_wb),
        .rd_wb(rd_wb),

        .reg_write_data_mem(reg_write_data_mem),
        .reg_write_data_wb(reg_write_data_wb),

        .rs1_fwd_id(rs1_fwd_id),
        .rs2_fwd_id(rs2_fwd_id),

        .branch_id(branch_id),
        .jal_id(jal_id),
        .jalr_id(jalr_id),

        .instr_funct3_id(instr_funct3_id),
        .pc_src(pc_src_id),
        .new_pc(new_pc),

        .mem_read_id(mem_read_id),
        .mem_write_id(mem_write_id),

        .alu_src1_id(alu_src1_id),
        .alu_src2_id(alu_src2_id),
        .alu_type_id(alu_type_id),

        .reg_src_id(reg_src_id),
        .reg_write_id(reg_write_id),
        
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rd_id(rd_id),

        .rs1_data_id(rs1_data_id),
        .rs2_data_id(rs2_data_id),

        .imm_id(imm_id),

        .accelerator_instr_id(accelerator_instr_id)
    );

    ID_EX_REG id_ex_register(
        .clk(clk),
        .rst(rst),
        .stall_ex(stall_ex),
        .bubble_ex(bubble_ex),

        .branch_id(branch_id),
        .jal_id(jal_id),
        .jalr_id(jalr_id),
        .mem_read_id(mem_read_id),
        .mem_write_id(mem_write_id),
        .alu_src1_id(alu_src1_id),
        .alu_src2_id(alu_src2_id),

        .reg_write_id(reg_write_id),
        .reg_src_id(reg_src_id),
        .instr_funct3_id(instr_funct3_id),
        .alu_type_id(alu_type_id),

        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rd_id(rd_id),
        .rs1_data_id(rs1_data_id),
        .rs2_data_id(rs2_data_id),
        
        .imm_id(imm_id),
        .pc_id(pc_id),
        .pc_plus4_id(pc_plus4_id),

        .accelerator_instr_id(accelerator_instr_id),

        .mem_read_ex(mem_read_ex),
        .mem_write_ex(mem_write_ex),

        .imm_ex(imm_ex),
        .reg_write_ex(reg_write_ex),
        .instr_funct3_ex(instr_funct3_ex),
        .reg_src_ex(reg_src_ex),
        .rd_ex(rd_ex),

        .pc_ex(pc_ex),
        .pc_plus4_ex(pc_plus4_ex),

        .alu_src1_ex(alu_src1_ex),
        .alu_src2_ex(alu_src2_ex),
        .alu_type_ex(alu_type_ex),

        .rs1_ex(rs1_ex),
        .rs2_ex(rs2_ex),

        .rs1_data_ex(rs1_data_ex),
        .rs2_data_ex(rs2_data_ex),

        .accelerator_instr_ex(accelerator_instr_ex)

    );

    EX exexute_stage(
        .alu_src1_ex(alu_src1_ex),
        .alu_src2_ex(alu_src2_ex),
        .alu_type_ex(alu_type_ex),
        .pc_ex(pc_ex),
        .rs1_data_ex(rs1_data_ex),
        .rs2_data_ex(rs2_data_ex),
        .imm_ex(imm_ex),
        .reg_write_data_wb(reg_write_data_wb),
        .reg_write_data_mem(reg_write_data_mem),
        .rs1_ex(rs1_ex),
        .rs2_ex(rs2_ex),
        .rs1_fwd_ex(rs1_fwd_ex),
        .rs2_fwd_ex(rs2_fwd_ex),

        .alu_result_ex(alu_result_ex),
        .real_rs2_data_ex(real_rs2_data_ex),
        .real_rs1_data_ex(real_rs1_data_ex)
    );

    EX_MEM_REG ex_mem_register(
        .clk(clk),
        .rst(rst),
        .stall_mem(stall_mem),
        .bubble_mem(bubble_mem),

        .mem_read_ex(mem_read_ex),
        .mem_write_ex(mem_write_ex),
        .reg_write_ex(reg_write_ex),
        .imm_ex(imm_ex),
        .instr_funct3_ex(instr_funct3_ex),
        .reg_src_ex(reg_src_ex),
        .rd_ex(rd_ex),
        .pc_plus4_ex(pc_plus4_ex),
        .rs2_data_ex(real_rs2_data_ex),
        .alu_result_ex(alu_result_ex),

        .accelerator_instr_ex(accelerator_instr_ex),
        .rs1_data_ex(real_rs1_data_ex),

        .reg_write_mem(reg_write_mem),
        .reg_src_mem(reg_src_mem),
        .rd_mem(rd_mem),
        .alu_result_mem(alu_result_mem),
        .imm_mem(imm_mem),
        .pc_plus4_mem(pc_plus4_mem),

        .mem_read_mem(mem_read_mem),
        .mem_write_mem(mem_write_mem),
        .instr_funct3_mem(instr_funct3_mem),
        .rs2_data_mem(rs2_data_mem),

        .accelerator_instr_mem(accelerator_instr_mem),
        .rs1_data_mem(rs1_data_mem)
    );

    MEM_MODULE memory_stage(
        .mem_read_mem(mem_read_mem),
        .mem_write_mem(mem_write_mem),
        .instr_funct3_mem(instr_funct3_mem),
        .rs2_data_mem(rs2_data_mem),
        .alu_result_mem(alu_result_mem),
        .mem_read_data(read_data),
        .reg_src_mem(reg_src_mem),
        .imm_mem(imm_mem),
        .pc_plus4_mem(pc_plus4_mem),

        .mem_write(ram_write),
        .write_type(write_type),
        .mem_addr(addr),
        .write_data(cache_write_data),
        .mem2reg_data(mem2reg_data),
        .reg_write_data_mem(reg_write_data_mem),

        .stall_flag(stall_flag)
    );

    // maintain the state register of accelerator request finish
    reg accelerator_bus_request_finish, accelerator_cache_request_finish;
    reg accelerator_request_finish;
    always @(*) begin
        accelerator_request_finish = accelerator_cache_request_finish & accelerator_bus_request_finish;
        // accelerator_request_finish = (accelerator_take_up_bus) ? (data_bus_request_finish) : 1'b0;
    end

    always @(posedge clk) begin
        if(accelerator_request_finish) begin
            accelerator_bus_request_finish <= 1'b0;
            accelerator_cache_request_finish <= 1'b0;
        end
        if(accelerator_instr_mem) begin
            case (instr_funct3_mem)
                `LOAD: begin
                    if(!accelerator_bus_request_finish & !accelerator_cache_request_finish) begin
                        accelerator_cache_request_finish <= cache_request_finish;
                        accelerator_bus_request_finish <= 1'b0;
                    end
                    else if(accelerator_cache_request_finish && !accelerator_bus_request_finish) begin
                        accelerator_bus_request_finish <= data_bus_request_finish;
                        accelerator_cache_request_finish <= 1'b1;
                    end
                end 
                `SAVE: begin
                    if(!accelerator_bus_request_finish & !accelerator_cache_request_finish) begin
                        accelerator_cache_request_finish <= 1'b0;
                        accelerator_bus_request_finish <= 1'b1;
                    end
                    else if(!accelerator_cache_request_finish && accelerator_bus_request_finish) begin
                        accelerator_bus_request_finish <= 1'b1;
                        accelerator_cache_request_finish <= cache_request_finish;
                    end
                end
                default: begin
                    accelerator_cache_request_finish <= 1'b1;
                    accelerator_bus_request_finish <= data_bus_request_finish;
                end
            endcase
        end
        else begin
            accelerator_bus_request_finish = 1'b0;
            accelerator_cache_request_finish = 1'b0;
        end
    end

    assign bus_induced_stall_flag = stall_flag || accelerator_instr_mem;
 
  
    // logic for accelerator ISA extension
    // judge whether to take up the bus for the accelerator
    reg accelerator_take_up_bus;
    always @(*) begin
        if(accelerator_instr_mem) begin
            case (instr_funct3_mem)
                `LOAD: begin
                    accelerator_take_up_bus = accelerator_cache_request_finish & !accelerator_bus_request_finish;
                end 
                `SAVE: begin
                    accelerator_take_up_bus = !accelerator_bus_request_finish & !accelerator_cache_request_finish;
                end
                default: 
                    accelerator_take_up_bus = !accelerator_request_finish; 
            endcase
        end
        else begin
            accelerator_take_up_bus = 1'b0;
        end
    end
    
    

    // muxing between accelerator and cache
    assign data_bus_read_request = accelerator_take_up_bus ? accelerator_bus_read_request : mem_read_request;
    assign data_bus_write_request = accelerator_take_up_bus ? accelerator_bus_write_request : mem_write_request;
    assign data_bus_write_data = accelerator_take_up_bus ? accelerator_bus_write_data : mem_write_data;
    assign data_bus_addr = accelerator_take_up_bus ? accelerator_bus_addr : mem_addr;
        
    // ISA extension substitutions for the cache signal addr and mem_read_mem
    wire [31:0] addr1;
    reg mem_read_flag, mem_write_flag;

    // extension for hazard detect
    wire all_request_finish = (accelerator_instr_mem) ? accelerator_request_finish : cache_request_finish;

    assign addr1 = (accelerator_instr_mem) ? rs1_data_mem : addr;
    // assign addr1 = (accelerator_instr_mem) ? rs1_data_mem + `DATA_MEM_BASE_ADDR : addr + `DATA_MEM_BASE_ADDR;
    wire mem_read_mem1 = (accelerator_instr_mem) ? mem_read_flag : mem_read_mem;
    wire cache_write = (accelerator_instr_mem) ? mem_write_flag : ram_write;
    
    reg test;
    always @(*) begin
        test = 1'b0;
        if(accelerator_instr_mem) begin
            
            case (instr_funct3_mem)
                `LOAD: begin
                    accelerator_bus_write_request = 1'b1; // write data into the accelerator
                    accelerator_bus_read_request = 1'b0;  // read data from the accelerator
                    accelerator_bus_addr = rs2_data_mem + `ACCELERATOR_MEM_BASE_ADDR;
                    if(!accelerator_take_up_bus)begin
                        mem_read_flag = 1'b1;
                        mem_write_flag = 1'b0;
                    end
                    test = 1'b0;
                    
                end 
                `SAVE: begin
                    accelerator_bus_read_request = 1'b1;
                    accelerator_bus_write_request = 1'b0;
                    accelerator_bus_addr = rs2_data_mem + `ACCELERATOR_MEM_BASE_ADDR;
                    if(!accelerator_take_up_bus)begin
                        mem_read_flag = 1'b0;
                        mem_write_flag = 1'b1;
                    end
                    test = 1'b1;
                end
                `MATMUL: begin
                    accelerator_bus_read_request = 1'b0;
                    accelerator_bus_write_request = 1'b1;
                    mem_read_flag = 1'b0;
                    mem_write_flag = 1'b0;
                    accelerator_bus_addr = `OUTPUT_BUFFER_BASE_ADDR + `ACCELERATOR_MEM_BASE_ADDR;
                    test = 1'b0;
                end
                `RESET: begin
                    accelerator_bus_read_request = 1'b1;
                    accelerator_bus_write_request = 1'b1;
                    accelerator_bus_addr = rs2_data_mem + `ACCELERATOR_MEM_BASE_ADDR;
                    mem_read_flag = 1'b0;
                    mem_write_flag = 1'b0;
                end
                `MOVE: begin
                    accelerator_bus_read_request = 1'b1;
                    accelerator_bus_write_request = 1'b1;
                    accelerator_bus_addr = `MOVE_ADDR + `ACCELERATOR_MEM_BASE_ADDR;
                    mem_read_flag = 1'b0;
                    mem_write_flag = 1'b0;
                    test = 1'b0;
                end
                default: begin
                    accelerator_bus_read_request = 1'b0;
                    accelerator_bus_write_request = 1'b0;
                    accelerator_bus_addr = 32'b0;
                    mem_read_flag = 1'b0;
                    mem_write_flag = 1'b0;
                end
                
            endcase
        end
        else begin
            accelerator_bus_read_request = 1'b0;
            accelerator_bus_write_request = 1'b0;
        end
    end
    
    assign mem_request_finish = (accelerator_take_up_bus) ? 1'b0 : data_bus_request_finish;
    assign mem_read_data = (accelerator_take_up_bus) ? (accelerator_bus_read_request & mem_read_flag) ? data_bus_read_data : 'b0 : data_bus_read_data;
    
    // to handle the cache write into the 
    always @(posedge clk) begin
        if(accelerator_take_up_bus)begin
            accelerator_bus_read_data <= data_bus_read_data;
        end
    end

    DataCache #(
        .LINE_ADDR_LEN(LINE_ADDR_LEN),
        .SET_ADDR_LEN(3),
        .TAG_ADDR_LEN(10),
        .WAY_CNT(16)
    ) data_cache(
        .clk(clk),
        .rst(rst),
        .debug(debug),

        // ports between memory and CPU
        .read_request(mem_read_mem1),
        .write_request(cache_write),
        .write_type(write_type),
        .addr(addr1),
        .write_data(cache_write_data),
        .request_finish(cache_request_finish),
        .read_data(read_data),

        //ports between cache and main memory
        .mem_read_request(mem_read_request),
        .mem_write_request(mem_write_request),
        .mem_write_data(mem_write_data),
        .mem_addr(mem_addr),
        .mem_request_finish(mem_request_finish),
        .mem_read_data(mem_read_data),

        // ports that interact with accelerator
        .if_accelerator_read(accelerator_bus_write_request),
        .if_accelerator_write(accelerator_bus_read_request),
        .accelerator_read_data(accelerator_bus_write_data),
        .accelerator_write_data(accelerator_bus_read_data)

    );

    MEM_WB_REG mem_wb_register(
        .clk(clk),
        .bubble_wb(bubble_wb),
        .stall_wb(stall_wb),

        .mem2reg_data(mem2reg_data),

        .reg_write_mem(reg_write_mem),

        .reg_src_mem(reg_src_mem),
        .rd_mem(rd_mem),
        .alu_result_mem(alu_result_mem),
        .imm_mem(imm_mem),
        .pc_plus4_mem(pc_plus4_mem),

        .reg_src_wb(reg_src_wb),
        .alu_result_wb(alu_result_wb),
        .mem2reg_data_wb(mem2reg_data_wb),
        .imm_wb(imm_wb),
        .nxpc_wb(nxpc_wb),
        .reg_write_wb(reg_write_wb),
        .rd_wb(rd_wb)
    );


    WB write_back_stage(
        .reg_src_wb(reg_src_wb),
        .alu_result_wb(alu_result_wb),
        .mem2reg_data_wb(mem2reg_data_wb),
        .imm_wb(imm_wb),
        .nxpc_wb(nxpc_wb),

        .reg_write_data_wb(reg_write_data_wb)
    );

    FWD_EX forward_unit_ex(
        .reg_write_wb(reg_write_wb),
        .rd_wb(rd_wb),
        .rs1_ex(rs1_ex),
        .rs2_ex(rs2_ex),

        .reg_write_mem(reg_write_mem),
        .rd_mem(rd_mem),

        .rs1_fwd_ex(rs1_fwd_ex),
        .rs2_fwd_ex(rs2_fwd_ex)
    );

    FWD_ID forward_unit_id(
        .reg_write_mem(reg_write_mem),
        .rd_mem(rd_mem),
        .branch_id(branch_id),
        .jal_id(jal_id),
        .jalr_id(jalr_id),

        .rs1_id(rs1_id),
        .rs2_id(rs2_id),

        .rs1_fwd_id(rs1_fwd_id),
        .rs2_fwd_id(rs2_fwd_id)
    );

    HazardDetect hazard_detect_unit(
        .clk(clk),
        .rst(rst),
        .pc_src_id(pc_src_id),
        .jal_id(jal_id),
        .jalr_id(jalr_id),
        .branch_id(branch_id),
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .mem_read_ex(mem_read_ex),
        .rd_ex(rd_ex),
        .rd_mem(rd_mem),
        .mem_read_mem(mem_read_mem),
        .stall_flag(bus_induced_stall_flag),
        .request_finish(all_request_finish),

        .stall_if(stall_if),
        .stall_id(stall_id),
        .stall_ex(stall_ex), 
        .stall_mem(stall_mem),
        .stall_wb(stall_wb),
        
        .bubble_if(bubble_if),
        .bubble_id(bubble_id),
        .bubble_ex(bubble_ex),
        .bubble_mem(bubble_mem),
        .bubble_wb(bubble_wb)
    );
endmodule