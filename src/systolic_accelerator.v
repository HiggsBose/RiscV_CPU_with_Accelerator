`include "src/accelerator_components/controller.v"
`include "src/accelerator_components/fifo.v"
`include "src/accelerator_components/systolic_array.v"

module SystolicAccelerator #(
    parameter ARRAY_SIZE=16,
    parameter DATA_WIDTH=16,
    parameter FIFO_BUFFER_SIZE=16,
    parameter BUS_PACKET_WIDTH=256

) (
    input clk, rst, debug,
    // slave ports on bus
    input [BUS_PACKET_WIDTH-1:0] bus_slave_input,
    input [31:0] bus_slave_addr,
    input bus_slave_read_request, bus_slave_write_request,
    output bus_slave_request_finish,
    output [BUS_PACKET_WIDTH-1:0] bus_slave_output
);
    
    // FIFO interface
    wire [ARRAY_SIZE-1:0] north_fifo_rsts, north_fifo_injects, north_fifo_bubbles;
    wire [ARRAY_SIZE-1:0] west_fifo_rsts, west_fifo_injects, west_fifo_bubbles;
    wire [FIFO_BUFFER_SIZE*DATA_WIDTH-1:0] west_fifo_input_data, north_fifo_input_data;

    // FIFO inputs to systolic array
    wire [ARRAY_SIZE*DATA_WIDTH-1:0] west_inputs, north_inputs;

    // systolic
    wire [31:0] systolic_row_index;
    wire [ARRAY_SIZE*DATA_WIDTH-1:0] systolic_row_results;

    // controller instantiation
    Controller Systolic_Control (
        .clk(clk),
        .rst(rst),

        .bus_slave_input(bus_slave_input),
        .bus_slave_addr(bus_slave_addr),
        .bus_slave_read_request(bus_slave_read_request),
        .bus_slave_write_request(bus_slave_write_request),
        .bus_slave_request_finish(bus_slave_request_finish),
        .bus_slave_output(bus_slave_output),

        .north_fifo_rsts(north_fifo_rsts),
        .north_fifo_injects(north_fifo_injects),
        .north_fifo_bubbles(north_fifo_bubbles),
        .west_fifo_rsts(west_fifo_rsts),
        .west_fifo_injects(west_fifo_injects),
        .west_fifo_bubbles(west_fifo_bubbles),
        .west_fifo_input_data(west_fifo_input_data),
        .north_fifo_input_data(north_fifo_input_data),

        .systolic_rst(systolic_rst),
        .systolic_accumulate_enable(systolic_accumulate_enable),
        .systolic_read_enable(systolic_read_enable),
        .systolic_row_index(systolic_row_index),
        .systolic_row_results(systolic_row_results)
    );

    // weight and input FIFO instantiation
    genvar iCol, iRow;
    generate
        for(iCol=0;iCol<ARRAY_SIZE;iCol=iCol+1) begin
            FIFOBuffer weight_buffer(
                .clk(clk),
                .rst(north_fifo_rsts[iCol]),

                .inject(north_fifo_injects[iCol]),
                .bubble(north_fifo_bubbles[iCol]),
                .buffer_input(north_fifo_input_data),
                // .buffer_output(north_inputs[(iCol+1)*DATA_WIDTH-1:iCol*DATA_WIDTH])
                .buffer_output(north_inputs[(ARRAY_SIZE-iCol)*DATA_WIDTH-1:(ARRAY_SIZE-iCol-1)*DATA_WIDTH])
            );

        end

        for(iRow=0; iRow<ARRAY_SIZE; iRow=iRow+1) begin
            FIFOBuffer input_buffer(
                .clk(clk),
                .rst(west_fifo_rsts[iRow]),

                .inject(west_fifo_injects[iRow]),
                .bubble(west_fifo_bubbles[iRow]),
                .buffer_input(west_fifo_input_data),
                // .buffer_output(west_inputs[(iRow+1)*DATA_WIDTH-1:iRow*DATA_WIDTH])
                .buffer_output(west_inputs[(ARRAY_SIZE-iRow)*DATA_WIDTH-1:(ARRAY_SIZE-iRow-1)*DATA_WIDTH])
            );
        end
    endgenerate

    // systolic array instantiation
    SystolicArray systolic_array(
        .clk(clk),
        .rst(systolic_rst),

        .accumulate_enable(systolic_accumulate_enable),
        .read_enable(systolic_read_enable),

        .west_inputs(west_inputs),
        .north_inputs(north_inputs),
        .row_index(systolic_row_index),
        .results(systolic_row_results)
    );




    // used for output. save systolic array's results
    // DO NOT CHANGE↓
    integer out_file;
    initial 
        begin
            if(`TEST_TYPE==0)
            begin 
                out_file = $fopen("systolic_output0.txt", "w");    
            end
            else if(`TEST_TYPE==1)
            begin 
                out_file = $fopen("systolic_output1.txt", "w");    
            end
            else if(`TEST_TYPE==2)
            begin 
                out_file = $fopen("systolic_output2.txt", "w");    
            end
            else if(`TEST_TYPE==3)
            begin 
                out_file = $fopen("systolic_output3.txt", "w");    
            end
            else if(`TEST_TYPE==4)
            begin 
                out_file = $fopen("systolic_output4.txt", "w");    
            end
        end

    integer x, y;
    always @(posedge clk) 
    begin
        if(debug)
        begin
            for(x=0; x<ARRAY_SIZE; x=x+1)
            begin
                for(y=0; y<ARRAY_SIZE; y=y+1)
                begin
                    $fwrite(out_file, "%4h ", systolic_array.results_unpacked[x][y]);
                end
                $fwrite(out_file, "\n");
            end
        end    
    end

    
endmodule