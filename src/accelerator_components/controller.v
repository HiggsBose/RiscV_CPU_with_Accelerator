`include "src/defines.v"

module Controller #(
    parameter DATA_WIDTH = 16,
    parameter PACKET_WIDTH = 256,
    parameter ARRAY_SIZE = 16,
    parameter FIFO_BUFFER_SIZE = 16
) (
    input clk, rst,
    // bus interface
    // bus slave --- communicate with CPU
    input [PACKET_WIDTH-1:0] bus_slave_input,
    input [31:0] bus_slave_addr,
    input bus_slave_read_request, bus_slave_write_request,
    output bus_slave_request_finish,
    output [PACKET_WIDTH-1:0] bus_slave_output,
    // FIFO interface
    output [ARRAY_SIZE-1:0] north_fifo_rsts, north_fifo_injects, north_fifo_bubbles,
    output [ARRAY_SIZE-1:0] west_fifo_rsts, west_fifo_injects, west_fifo_bubbles,
    output [FIFO_BUFFER_SIZE*DATA_WIDTH-1:0] west_fifo_input_data, north_fifo_input_data,
    // systolic array interface
    output systolic_rst, systolic_accumulate_enable, systolic_read_enable,
    output [31:0] systolic_row_index,
    input [ARRAY_SIZE*DATA_WIDTH-1:0] systolic_row_results
    // output-input activation transfer interface
);
    // systolic array timing parameters
    localparam SYSTOLIC_CYCLE_CNT = 3*ARRAY_SIZE-1;
    parameter INTRA_ROW_BIT = 5;
    parameter ROW_INDEX_BIT = 4;
    // controller states
    parameter[1:0] READY        = 2'b00;
    parameter[1:0] MATMUL       = 2'b01;
    parameter[1:0] MOVE         = 2'b10;

    wire [ARRAY_SIZE*DATA_WIDTH-1:0] zeros = 0;

    // controller's inner registers
    reg [1:0] state; // controller state
    // controller's registers for all operations
    reg matmul_finish, move_finish;
    reg [31:0] tmp_row_idx, tmp_matmul_cycle;


    // judge which request has been sent to accelerator
    wire load_request = ((!bus_slave_read_request && bus_slave_write_request) && (bus_slave_addr < `OUTPUT_BUFFER_BASE_ADDR));
    wire save_request = (bus_slave_read_request && !bus_slave_write_request);
    wire matmul_request = ((!bus_slave_read_request && bus_slave_write_request) && (bus_slave_addr >= `OUTPUT_BUFFER_BASE_ADDR));
    wire reset_request =  ((bus_slave_read_request && bus_slave_write_request) && (bus_slave_addr < `MOVE_ADDR));
    wire move_request = ((bus_slave_read_request && bus_slave_write_request) && (bus_slave_addr == `MOVE_ADDR));


    // judge whether to send finish signal to the CPU
    assign bus_slave_request_finish = load_request ? (state==READY) :
                                      save_request ? (state==READY) :
                                      matmul_request ? ((state==READY && matmul_finish)) :
                                      reset_request ? (state==READY) :
                                      move_request ? ((state==READY) && move_finish) :
                                      1'b0;
    assign bus_slave_output = save_request ? systolic_row_results : 0;


    // judge which buffer to load data into
    wire load_to_west_fifo = (load_request && (bus_slave_addr>=`INPUT_FIFO_BASE_ADDR && bus_slave_addr<`WEIGHT_FIFO_BASE_ADDR));
    wire load_to_north_fifo = (load_request && (bus_slave_addr>=`WEIGHT_FIFO_BASE_ADDR && bus_slave_addr<`OUTPUT_BUFFER_BASE_ADDR));
    wire [31:0] west_fifo_load_dst = load_to_west_fifo ? {zeros[31:ROW_INDEX_BIT], bus_slave_addr[ROW_INDEX_BIT+INTRA_ROW_BIT-1:INTRA_ROW_BIT]} : 32'hffffffff;
    wire [31:0] north_fifo_load_dst = load_to_north_fifo ? {zeros[31:ROW_INDEX_BIT], bus_slave_addr[ROW_INDEX_BIT+INTRA_ROW_BIT-1:INTRA_ROW_BIT]} : 32'hffffffff;
    // select the row to read result from
    wire [31:0] systolic_row_save_src = save_request ? {zeros[31:ROW_INDEX_BIT], bus_slave_addr[ROW_INDEX_BIT+INTRA_ROW_BIT-1:INTRA_ROW_BIT]} : 32'hffffffff;


    // wires interacting between controller and buffers
    // Part 1: wires for FIFO buffers: write data from memory to FIFO buffers
    genvar i;
    generate
        for(i=0; i<ARRAY_SIZE; i=i+1)
        begin
            assign west_fifo_rsts[i] = rst || (reset_request && (bus_slave_addr == `INPUT_FIFO_BASE_ADDR));
            assign west_fifo_injects[i] = (state == READY) ? (west_fifo_load_dst == i) :
                                          (state == MOVE) ? (tmp_row_idx == i) : 
                                          1'b0;
            assign west_fifo_bubbles[i] = (state == MATMUL) && (tmp_matmul_cycle >= i);

            assign north_fifo_rsts[i] = rst || (reset_request && (bus_slave_addr == `WEIGHT_FIFO_BASE_ADDR));
            assign north_fifo_injects[i] = (state == READY) ? (north_fifo_load_dst == i) : 1'b0;
            assign north_fifo_bubbles[i] = (state == MATMUL) && (tmp_matmul_cycle >= i);
        end
    endgenerate
    assign west_fifo_input_data = ((state == READY) && load_to_west_fifo) ? bus_slave_input :
                                  (state == MOVE) ? systolic_row_results :
                                  0;
    assign north_fifo_input_data = ((state == READY) && load_to_north_fifo) ? bus_slave_input : 0;
    
    // Part 2: wires for systolic array output registers
    assign systolic_rst = rst || (reset_request && (bus_slave_addr == `OUTPUT_BUFFER_BASE_ADDR));
    assign systolic_read_enable = (state == READY) ? save_request :
                                  (state == MOVE) ? 1'b1 : 
                                  1'b0;
    assign systolic_accumulate_enable = (state == MATMUL);
    assign systolic_row_index = (state == READY) ? systolic_row_save_src :
                                (state == MOVE) ? tmp_row_idx : 
                                0;

    // controller state machine
    always @(posedge clk)
    begin
        if(rst)
        begin
            // init registers
            state <= READY;
            matmul_finish <= 1'b0; move_finish <= 1'b0;
            tmp_row_idx <= 0; tmp_matmul_cycle <= 0;
        end

        else
        begin
            case (state)
                READY:
                begin
                    if(matmul_request)
                    begin
                        if(!matmul_finish)
                        begin
                            state <= MATMUL;
                            matmul_finish <= 1'b0;
                            tmp_matmul_cycle <= 0;
                        end
                        else
                        begin
                            matmul_finish <= 1'b0;
                            tmp_matmul_cycle <= 0;
                        end
                    end

                    else if(move_request)
                    begin
                        if(!move_finish)
                        begin
                            state <= MOVE;
                            move_finish <= 1'b0;
                            tmp_row_idx <= 0;
                        end
                        else
                        begin
                            move_finish <= 1'b0;
                            tmp_row_idx <= 0;
                        end
                    end
                end 

                MATMUL:
                begin
                    if(tmp_matmul_cycle >= SYSTOLIC_CYCLE_CNT)
                    begin
                        state <= READY;
                        matmul_finish <= 1'b1;
                    end
                    else
                    begin
                        tmp_matmul_cycle <= tmp_matmul_cycle + 1;
                    end
                end

                MOVE:
                begin
                    if(tmp_row_idx >= ARRAY_SIZE)
                    begin
                        state <= READY;
                        move_finish <= 1'b1;
                    end
                    else
                    begin
                        tmp_row_idx <= tmp_row_idx + 1;
                    end
                end

            endcase
        end
    end

endmodule