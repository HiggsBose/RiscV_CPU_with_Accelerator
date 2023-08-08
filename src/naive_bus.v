module NaiveBus #(
    parameter BUS_WIDTH=256
) (
    input clk, rst,

    // master 0: PC instruction interface
    input [31:0] master0_addr,
    input [BUS_WIDTH-1:0] master0_write_data,
    input master0_write_request, master0_read_request,
    output master0_request_finish,
    output [BUS_WIDTH-1:0] master0_read_data,

    // master 1: memory data interface
    input [31:0] master1_addr,
    input [BUS_WIDTH-1:0] master1_write_data,
    input master1_write_request, master1_read_request,
    output master1_request_finish,
    output [BUS_WIDTH-1:0] master1_read_data,

    // master 2:
    input [31:0] master2_addr,
    input [BUS_WIDTH-1:0] master2_write_data,
    input master2_write_request, master2_read_request,
    output master2_request_finish,
    output [BUS_WIDTH-1:0] master2_read_data,

    // master 3:
    input [31:0] master3_addr,
    input [BUS_WIDTH-1:0] master3_write_data,
    input master3_write_request, master3_read_request,
    output master3_request_finish,
    output [BUS_WIDTH-1:0] master3_read_data,

    // slave 0: instruction memory
    input slave0_request_finish,
    input [BUS_WIDTH-1:0] slave0_read_data,
    output slave0_write_request, slave0_read_request,
    output [31:0] slave0_addr,
    output [BUS_WIDTH-1:0] slave0_write_data,

    // slave 1: main memory
    input slave1_request_finish,
    input [BUS_WIDTH-1:0] slave1_read_data,
    output slave1_write_request, slave1_read_request,
    output [31:0] slave1_addr,
    output [BUS_WIDTH-1:0] slave1_write_data,

    // slave 2
    input slave2_request_finish,
    input [BUS_WIDTH-1:0] slave2_read_data,
    output slave2_write_request, slave2_read_request,
    output [31:0] slave2_addr,
    output [BUS_WIDTH-1:0] slave2_write_data,

    // slave 3
    input slave3_request_finish,
    input [BUS_WIDTH-1:0] slave3_read_data,
    output slave3_write_request, slave3_read_request,
    output [31:0] slave3_addr,
    output [BUS_WIDTH-1:0] slave3_write_data
);
    // parameters for slave's address space partition
    // we use the highest 4 bits of address to indicate different slave devices
    // In this way, we can support at most 16 slave devices
    parameter [3:0] slave0 = 4'b0000;
    parameter [3:0] slave1 = 4'b0001;
    parameter [3:0] slave2 = 4'b0010;
    parameter [3:0] slave3 = 4'b0011;
    // parameters for master's grant decision
    // we use 3 bits in total, which means we can support at most 8 masters
    parameter [2:0] grant0 = 3'b000;
    parameter [2:0] grant1 = 3'b001;
    parameter [2:0] grant2 = 3'b010;
    parameter [2:0] grant3 = 3'b011;

    // arbitration logic to decide which master's request should be responsed
    // priority: main memory's request > instruction ROM's request
    wire [2:0] grant = (master1_read_request || master1_write_request) ? grant1 :
                       (master0_read_request || master0_write_request) ? grant0 :
                       (master2_read_request || master2_write_request) ? grant2 :
                       (master3_read_request || master3_write_request) ? grant3 :
                       3'b111;
    wire write_request = (grant == grant0) ? master0_write_request :
                         (grant == grant1) ? master1_write_request :
                         (grant == grant2) ? master2_write_request :
                         (grant == grant3) ? master3_write_request :
                         1'b0;
    wire read_request = (grant == grant0) ? master0_read_request :
                        (grant == grant1) ? master1_read_request :
                        (grant == grant2) ? master2_read_request :
                        (grant == grant3) ? master3_read_request :
                        1'b0;
    wire [BUS_WIDTH-1:0] data_to_slave = (grant == grant0) ? master0_write_data :
                                         (grant == grant1) ? master1_write_data :
                                         (grant == grant2) ? master2_write_data :
                                         (grant == grant3) ? master3_write_data :
                                         0;
    wire [31:0] address_to_slave = (grant == grant0) ? master0_addr :
                                   (grant == grant1) ? master1_addr :
                                   (grant == grant2) ? master2_addr :
                                   (grant == grant3) ? master3_addr :
                                   32'h00000000;

    // select slave and corresponding data
    wire [3:0] slave_select = address_to_slave[31:28];
    wire slave_request_finish = (slave_select == slave0) ? slave0_request_finish :
                                (slave_select == slave1) ? slave1_request_finish :
                                (slave_select == slave2) ? slave2_request_finish :
                                (slave_select == slave3) ? slave3_request_finish :
                                1'b0;
    wire [BUS_WIDTH-1:0] data_from_slave = (slave_select == slave0) ? slave0_read_data :
                                           (slave_select == slave1) ? slave1_read_data :
                                           (slave_select == slave2) ? slave2_read_data :
                                           (slave_select == slave3) ? slave3_read_data :
                                           0;
    
    // data interaction among masters and slaves
    // master
    // request finish signal
    assign master0_request_finish = (grant == grant0) ? slave_request_finish : 1'b0;
    assign master1_request_finish = (grant == grant1) ? slave_request_finish : 1'b0;
    assign master2_request_finish = (grant == grant2) ? slave_request_finish : 1'b0;
    assign master3_request_finish = (grant == grant3) ? slave_request_finish : 1'b0;
    // read data
    assign master0_read_data = (grant == grant0) ? data_from_slave : 0;
    assign master1_read_data = (grant == grant1) ? data_from_slave : 0;
    assign master2_read_data = (grant == grant2) ? data_from_slave : 0;
    assign master3_read_data = (grant == grant3) ? data_from_slave : 0;
    // slave
    // read request signal
    assign slave0_read_request = (slave_select == slave0) ? read_request : 1'b0;
    assign slave1_read_request = (slave_select == slave1) ? read_request : 1'b0;
    assign slave2_read_request = (slave_select == slave2) ? read_request : 1'b0;
    assign slave3_read_request = (slave_select == slave3) ? read_request : 1'b0;
    // write request signal
    assign slave0_write_request = (slave_select == slave0) ? write_request : 1'b0;
    assign slave1_write_request = (slave_select == slave1) ? write_request : 1'b0;
    assign slave2_write_request = (slave_select == slave2) ? write_request : 1'b0;
    assign slave3_write_request = (slave_select == slave3) ? write_request : 1'b0;
    // address
    assign slave0_addr = (slave_select == slave0) ? {4'b0000, address_to_slave[27:0]} : 32'h00000000;
    assign slave1_addr = (slave_select == slave1) ? {4'b0000, address_to_slave[27:0]} : 32'h00000000;
    assign slave2_addr = (slave_select == slave2) ? {4'b0000, address_to_slave[27:0]} : 32'h00000000;
    assign slave3_addr = (slave_select == slave3) ? {4'b0000, address_to_slave[27:0]} : 32'h00000000;
    // data to slave
    assign slave0_write_data = (slave_select == slave0) ? data_to_slave : 0;
    assign slave1_write_data = (slave_select == slave1) ? data_to_slave : 0;
    assign slave2_write_data = (slave_select == slave2) ? data_to_slave : 0;
    assign slave3_write_data = (slave_select == slave3) ? data_to_slave : 0;
    
endmodule