`include "src/defines.v"

module ControlUnit (
    input rst,
    input [31:0] instr,
    output reg[4:0] read_addr1,
    output reg[4:0] read_addr2,
    output reg[4:0] write_addr,

    output reg branch,
    output reg jal,
    output reg jalr,
    output reg mem_read,
    output reg mem_write,
    
    output reg alu_src1, alu_src2,
    output reg[3:0] alu_type,
    output reg[1:0] reg_src,

    output reg[2:0] instr_funct3,

    output reg reg_write_enable,

    // for ISA extension
    output reg accelerator_instr_id

);
    reg [31:0] real_instr;
    always @(*) begin
        if(rst)begin
            real_instr = `INST_NOP;
        end
        else real_instr = instr;

        instr_funct3 = real_instr[14:12]; // can be used as instr_funct3, load_type, store_type
        
        case (real_instr[6:0])
            `INST_TYPE_R:begin
                accelerator_instr_id = 1'b0;
                branch      = 1'b0;
                jal         = 0;
                jalr        = 0;
                mem_read    = 0;
                mem_write   = 0;
                alu_src1    = `REG;            // 1 for visiting register_file
                alu_src2    = `REG;
                alu_type    = {real_instr[30],real_instr[14:12]};
                read_addr1  = real_instr[19:15];
                read_addr2  = real_instr[24:20];
                reg_src     = `FROM_ALU;        // from alu 
                reg_write_enable = 1'b1;
            end
            `INST_TYPE_S:begin
                accelerator_instr_id = 1'b0;
                branch      = 0;
                jal         = 0;
                jalr        = 0;
                mem_read    = 0;
                mem_write   = 1;
                alu_src1    = `REG;            // from register_file
                alu_src2    = `IMM;            // from imm number
                alu_type    = `ADD;
                read_addr1  = real_instr[19:15];
                read_addr2  = real_instr[24:20];
                reg_src     = `FROM_ALU;           // no register write 
                reg_write_enable = 0;
            end
            `INST_TYPE_L:begin
                accelerator_instr_id = 1'b0;
                branch      = 0;
                jal         = 0;
                jalr        = 0;
                mem_read    = 1'b1;
                mem_write   = 0;
                alu_src1    = `REG;            // from register file
                alu_src2    = `IMM;            // from immediate number
                alu_type    = `ADD;
                read_addr1  = real_instr[19:15];
                read_addr2  = real_instr[24:20];
                reg_src     = `FROM_MEM;       // from memory
                reg_write_enable = 1'b1;
            end
            `INST_TYPE_B:begin
                accelerator_instr_id = 1'b0;
                branch      = 1'b1;
                jal         = 0;
                jalr        = 0;
                mem_read    = 0;
                mem_write   = 0;
                alu_src1    = `REG;
                alu_src2    = `REG;
                case (instr_funct3)
                    `BEQ, `BNE      :     alu_type = `SUB;
                    `BLT, `BGE      :     alu_type = `SLT;
                    `BLTU, `BGEU    :     alu_type = `SLTU; 
                    default         :     alu_type = `ADD; 
                endcase
                read_addr1  = real_instr[19:15];
                read_addr2  = real_instr[24:20];
                reg_src     = `FROM_ALU;
                reg_write_enable = 0;
            end
            `INST_TYPE_I:begin
                accelerator_instr_id = 1'b0;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                alu_src1    = `REG;
                alu_src2    = `IMM;
                if(real_instr[13:12]==2'b01) alu_type = {real_instr[30],real_instr[14:12]}; // for shift, alu_type is the same as R_type
                else alu_type = {1'b0,real_instr[14:12]}; // for other I type, alu_type should starts with 0   
                read_addr1  = real_instr[19:15];
                read_addr2  = 5'b0;
                reg_src     = `FROM_ALU;
                reg_write_enable = 1'b1;
            end
            `INST_LUI:begin
                accelerator_instr_id = 1'b0;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                alu_src1    = `REG;    // not sure
                alu_src2    = `REG;    // not sure
                alu_type    = `ADD;    // not sure
                read_addr1  = 5'b0;
                read_addr2  = 5'b0;
                reg_src     = `FROM_IMM;
                reg_write_enable = 1;
            end
            `INST_AUIPC:begin
                accelerator_instr_id = 1'b0;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                alu_src1    = `PC;
                alu_src2    = `IMM;
                alu_type    = `ADD;
                read_addr1  = 5'b0;
                read_addr2  = 5'b0;
                reg_src     = `FROM_ALU;
                reg_write_enable = 1;
            end
            `INST_JAL:begin
                accelerator_instr_id = 1'b0;
                branch      = 1'b0;
                jal         = 1'b1;
                jalr        = 1'b0;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                alu_src1    = `PC;  
                alu_src2    = `IMM;   
                alu_type    = `ADD;
                read_addr1  = 5'b0;
                read_addr2  = 5'b0;
                reg_src     = `FROM_PC; // to store pc as the return address
                reg_write_enable = 1;
            end
            `INST_JALR:begin
                accelerator_instr_id = 1'b0;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b1;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                alu_src1    = `REG;
                alu_src2    = `IMM;
                read_addr1  = real_instr[19:15];
                read_addr2  = 5'b0;
                alu_type    = `ADD;
                reg_src     = `FROM_PC;
                reg_write_enable = 1;
            end
            `INST_ACC: begin
                accelerator_instr_id = 1;
                mem_read    = 1'b1;
                mem_write   = 1'b0;
                alu_src1    = `REG;
                alu_src2    = `REG;
                alu_type    = `ADD;
                read_addr1  = real_instr[19:15];
                read_addr2  = real_instr[24:20];
                reg_src     = `FROM_ALU;
                reg_write_enable = 0;
            end

            default:begin
                accelerator_instr_id = 1'b0;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                alu_src1    = `REG;   // not sure
                alu_src2    = `REG;   // not sure
                alu_type    = `ADD;    //not sure
                read_addr1  = 5'b0;
                read_addr2  = 5'b0;
                reg_src     = `FROM_ALU;
                reg_write_enable = 0;
            end
        endcase
        write_addr = (reg_write_enable == 1'b1) ? real_instr[11:7] : 5'b0;
    end
endmodule
