`include "src/riscv.v"
`include "src/inst_mem.v"
// add main memory in Lab 5
`include "src/main_memory_wrapper.v"
// add on-chip bus in Lab 6
`include "src/naive_bus.v"
// add systolic array accelerator in Lab 6
`include "src/systolic_accelerator.v"

module RISCVSoC (
    input clk, rst, debug
);
    parameter LINE_ADDR_LEN = 3;
    parameter SYSTOLIC_ARRAY_SIZE = 16;
    parameter SYSTOLIC_DATA_WIDTH = 16;
    parameter SYSTOLIC_BUFFER_SIZE = 16;
    localparam BUS_DATA_WIDTH = (32*(1<<LINE_ADDR_LEN));
    
    // CPU to instr rom's master ports
    wire [31:0] instr, instr_addr;
    wire [BUS_DATA_WIDTH-1:0] instr_read_data_master;
    wire instr_request_finish_master;
    // bus to instr rom's slave ports
    wire [31:0] instr_slave, instr_addr_slave;
    wire instr_read_request_slave, instr_write_request_slave;
    wire [BUS_DATA_WIDTH-1:0] instr_read_data_slave;
    wire [BUS_DATA_WIDTH-1:0] instr_write_data_slave;

    // CPU to main memory's master ports
    wire mem_read_request, mem_write_request, mem_request_finish;
    wire [31:0] mem_addr;
    wire [BUS_DATA_WIDTH-1:0] mem_read_data;
    wire [BUS_DATA_WIDTH-1:0] mem_write_data;
    // bus to main memory's slave ports
    wire mem_read_request_slave, mem_write_request_slave, mem_request_finish_slave;
    wire [31:0] mem_addr_slave;
    wire [BUS_DATA_WIDTH-1:0] mem_read_data_slave;
    wire [BUS_DATA_WIDTH-1:0] mem_write_data_slave;

    // accelerator's slave ports
    wire systolic_slave_request_finish;
    wire [BUS_DATA_WIDTH-1:0] systolic_slave_read_data;
    wire systolic_slave_read_request, systolic_slave_write_request;
    wire [31:0] systolic_slave_addr;
    wire [BUS_DATA_WIDTH-1:0] systolic_slave_write_data;

    // for filling useless ports
    wire [BUS_DATA_WIDTH-1:0] zeros = 0;


    // CPU
    RISCVPipeline #(.LINE_ADDR_LEN(LINE_ADDR_LEN)) riscv(
        .clk(clk), .rst(rst), .debug(debug),
        // for instr rom
        .instr(instr),
        .instr_addr(instr_addr),
        // for main memory
        .data_bus_read_request(mem_read_request), .data_bus_write_request(mem_write_request),
        .data_bus_write_data(mem_write_data),
        .data_bus_addr(mem_addr),
        .data_bus_request_finish(mem_request_finish),
        .data_bus_read_data(mem_read_data)
    );
    assign instr = instr_read_data_master[31:0];


    // bus
    NaiveBus #(.BUS_WIDTH(BUS_DATA_WIDTH)) bus(
        .clk(clk), .rst(rst),

        // master0: CPU's instruction fetching ports
        .master0_addr(instr_addr),
        .master0_write_data(zeros),
        .master0_read_request(1'b1), .master0_write_request(1'b0),
        .master0_request_finish(instr_request_finish_master),
        .master0_read_data(instr_read_data_master),

        // master1: CPU's main memory access ports
        .master1_addr(mem_addr),
        .master1_write_data(mem_write_data),
        .master1_read_request(mem_read_request), .master1_write_request(mem_write_request),
        .master1_request_finish(mem_request_finish),
        .master1_read_data(mem_read_data),

        // slave0: instruction memory
        .slave0_request_finish(1'b1),
        .slave0_read_data(instr_read_data_slave),
        .slave0_write_request(instr_write_request_slave), .slave0_read_request(instr_read_request_slave),
        .slave0_addr(instr_addr_slave),
        .slave0_write_data(instr_write_data_slave),

        // slave1: main memory
        .slave1_request_finish(mem_request_finish_slave),
        .slave1_read_data(mem_read_data_slave),
        .slave1_read_request(mem_read_request_slave), .slave1_write_request(mem_write_request_slave),
        .slave1_addr(mem_addr_slave),
        .slave1_write_data(mem_write_data_slave),

        // slave2: systolic array
        .slave2_request_finish(systolic_slave_request_finish),
        .slave2_read_data(systolic_slave_read_data),
        .slave2_read_request(systolic_slave_read_request), .slave2_write_request(systolic_slave_write_request),
        .slave2_addr(systolic_slave_addr),
        .slave2_write_data(systolic_slave_write_data)
    );

    // instruction memory and data memory
    ROM instr_rom(
        .clk(clk),
        .addr(instr_addr_slave),
        .data_out(instr_slave)
    );
    assign instr_read_data_slave = {zeros[BUS_DATA_WIDTH-1:32], instr_slave};

    MainMemoryWrapper #(.LINE_ADDR_LEN(LINE_ADDR_LEN)) main_memory(
        .clk(clk), .rst(rst), .debug(debug),
        .read_request(mem_read_request_slave), .write_request(mem_write_request_slave),
        .write_data(mem_write_data_slave),
        .addr(mem_addr_slave),
        .request_finish(mem_request_finish_slave),
        .read_data(mem_read_data_slave)
    );

    // accelerator
    SystolicAccelerator #(
        .ARRAY_SIZE(SYSTOLIC_ARRAY_SIZE), 
        .DATA_WIDTH(SYSTOLIC_DATA_WIDTH),
        .FIFO_BUFFER_SIZE(SYSTOLIC_BUFFER_SIZE),
        .BUS_PACKET_WIDTH(BUS_DATA_WIDTH)
    ) systolic_accelerator(
        .clk(clk), .rst(rst), .debug(debug),
        
        .bus_slave_input(systolic_slave_write_data),
        .bus_slave_addr(systolic_slave_addr),
        .bus_slave_read_request(systolic_slave_read_request), .bus_slave_write_request(systolic_slave_write_request),
        .bus_slave_request_finish(systolic_slave_request_finish),
        .bus_slave_output(systolic_slave_read_data)
    );

endmodule