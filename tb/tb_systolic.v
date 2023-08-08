`timescale 1ns/1ns

`include "src/accelerator_components/systolic_array.v"
`include "src/accelerator_components/fifo.v"

`define DATA_WIDTH 16
`define FIFO_BUFFER_SIZE 4
`define ARRAY_SIZE 4

module TB_Systolic;
    initial begin            
        $dumpfile("wave.vcd");  // generate wave.vcd
        $dumpvars(0, TB_Systolic);   // dump all of the TB module data
    end

    reg clk;
    initial clk = 0;
    always #1 clk = ~clk;

    reg rst;
    // for PEs in systolic array
    reg accumulate_enable;
    // for all FIFO buffers
    reg inject;
    // each FIFO's data ports
    reg [`FIFO_BUFFER_SIZE*`DATA_WIDTH-1:0] fifo_input_west0, fifo_input_west1, fifo_input_west2, fifo_input_west3;
    reg [`FIFO_BUFFER_SIZE*`DATA_WIDTH-1:0] fifo_input_north0, fifo_input_north1, fifo_input_north2, fifo_input_north3;
    // each FIFO's pop-out enable signals
    reg bubble_west0, bubble_west1, bubble_west2, bubble_west3;
    reg bubble_north0, bubble_north1, bubble_north2, bubble_north3;
    // connect to systolic array
    wire [`DATA_WIDTH-1:0] systolic_input_west0, systolic_input_west1, systolic_input_west2, systolic_input_west3;
    wire [`DATA_WIDTH-1:0] systolic_input_north0, systolic_input_north1, systolic_input_north2, systolic_input_north3;
    wire [`ARRAY_SIZE*`DATA_WIDTH-1:0] systolic_array_input_west, systolic_array_input_north;

    assign systolic_array_input_west = {systolic_input_west0, systolic_input_west1, systolic_input_west2, systolic_input_west3};
    assign systolic_array_input_north = {systolic_input_north0, systolic_input_north1, systolic_input_north2, systolic_input_north3};

    FIFOBuffer #(.DATA_WIDTH(`DATA_WIDTH), .BUFFER_SIZE(`FIFO_BUFFER_SIZE)) fifo_west0(
        .clk(clk), .rst(rst),
        .inject(inject), .bubble(bubble_west0),
        .buffer_input(fifo_input_west0),
        .buffer_output(systolic_input_west0)
    );
    FIFOBuffer #(.DATA_WIDTH(`DATA_WIDTH), .BUFFER_SIZE(`FIFO_BUFFER_SIZE)) fifo_west1(
        .clk(clk), .rst(rst),
        .inject(inject), .bubble(bubble_west1),
        .buffer_input(fifo_input_west1),
        .buffer_output(systolic_input_west1)
    );
    FIFOBuffer #(.DATA_WIDTH(`DATA_WIDTH), .BUFFER_SIZE(`FIFO_BUFFER_SIZE)) fifo_west2(
        .clk(clk), .rst(rst),
        .inject(inject), .bubble(bubble_west2),
        .buffer_input(fifo_input_west2),
        .buffer_output(systolic_input_west2)
    );
    FIFOBuffer #(.DATA_WIDTH(`DATA_WIDTH), .BUFFER_SIZE(`FIFO_BUFFER_SIZE)) fifo_west3(
        .clk(clk), .rst(rst),
        .inject(inject), .bubble(bubble_west3),
        .buffer_input(fifo_input_west3),
        .buffer_output(systolic_input_west3)
    );

    FIFOBuffer #(.DATA_WIDTH(`DATA_WIDTH), .BUFFER_SIZE(`FIFO_BUFFER_SIZE)) fifo_north0(
        .clk(clk), .rst(rst),
        .inject(inject), .bubble(bubble_north0),
        .buffer_input(fifo_input_north0),
        .buffer_output(systolic_input_north0)
    );
    FIFOBuffer #(.DATA_WIDTH(`DATA_WIDTH), .BUFFER_SIZE(`FIFO_BUFFER_SIZE)) fifo_north1(
        .clk(clk), .rst(rst),
        .inject(inject), .bubble(bubble_north1),
        .buffer_input(fifo_input_north1),
        .buffer_output(systolic_input_north1)
    );
    FIFOBuffer #(.DATA_WIDTH(`DATA_WIDTH), .BUFFER_SIZE(`FIFO_BUFFER_SIZE)) fifo_north2(
        .clk(clk), .rst(rst),
        .inject(inject), .bubble(bubble_north2),
        .buffer_input(fifo_input_north2),
        .buffer_output(systolic_input_north2)
    );
    FIFOBuffer #(.DATA_WIDTH(`DATA_WIDTH), .BUFFER_SIZE(`FIFO_BUFFER_SIZE)) fifo_north3(
        .clk(clk), .rst(rst),
        .inject(inject), .bubble(bubble_north3),
        .buffer_input(fifo_input_north3),
        .buffer_output(systolic_input_north3)
    );

    SystolicArray #(.ARRAY_SIZE(`ARRAY_SIZE), .DATA_WIDTH(`DATA_WIDTH)) systolic_array(
        .clk(clk), .rst(rst),
        .accumulate_enable(accumulate_enable),
        .west_inputs(systolic_array_input_west), .north_inputs(systolic_array_input_north)
    );

    integer out_file;
    integer i, j;
    initial 
    begin
        // reset FIFO buffers and systolic array
        #0
        rst = 1;
        accumulate_enable = 0;
        inject = 0;
        bubble_west0 = 0;
        bubble_west1 = 0;
        bubble_west2 = 0;
        bubble_west3 = 0;
        bubble_north0 = 0;
        bubble_north1 = 0;
        bubble_north2 = 0;
        bubble_north3 = 0;
    
        // inject matrices into FIFO buffers
        // compute mat A * mat B
        // western FIFOs contains matrix A: (recorded in hex)
        // 0022 008d 000c 009e 
        // 009d 00cb 007a 006d 
        // 007d 0034 009b 000b 
        // 00ca 0089 0026 0065 
        // northern FIFos contains matrix B (recorded in hex)
        // 0099 00bd 002a 00a5 
        // 0087 0070 000f 0078 
        // 0055 00bf 006d 0043 
        // 00ad 0091 003c 00e4
        // each western FIFO contains one row in matrix A
        // each northern FIFO contains one column in matrix B
        #2
        rst = 0;
        accumulate_enable = 0;
        inject = 1;
        // western FIFOs
        fifo_input_west0 = 64'h0022008d000c009e;
        fifo_input_west1 = 64'h009d00cb007a006d;
        fifo_input_west2 = 64'h007d0034009b000b;
        fifo_input_west3 = 64'h00ca008900260065;
        // northern FIFOs
        fifo_input_north0 = 64'h00990087005500ad;
        fifo_input_north1 = 64'h00bd007000bf0091;
        fifo_input_north2 = 64'h002a000f006d003c;
        fifo_input_north3 = 64'h00a50078004300e4;

       

        #2
        $display("%h",fifo_north0.buffer_data[0]);
        $display("north: %h, west: %h",systolic_array.debug_processing_element.input_north, systolic_array.debug_processing_element.input_west);
        rst = 0;
        accumulate_enable = 1;
        inject = 0;
        bubble_west0 = 1;
        bubble_north0 = 1;

        #2
        $display("north: %h, west: %h",systolic_array.debug_processing_element.input_north, systolic_array.debug_processing_element.input_west);
        bubble_west1 = 1;
        bubble_north1 = 1;

        #2
        $display("north: %h, west: %h",systolic_array.debug_processing_element.input_north, systolic_array.debug_processing_element.input_west);
        bubble_west2 = 1;
        bubble_north2 = 1;

        #2
        $display("north: %h, west: %h",systolic_array.debug_processing_element.input_north, systolic_array.debug_processing_element.input_west);
        bubble_west3 = 1;
        bubble_north3 = 1;

        #2
        $display("north: %h, west: %h, result: %h",systolic_array.debug_processing_element.input_north, systolic_array.debug_processing_element.input_west, systolic_array.debug_processing_element.result);
        #2
        $display("north: %h, west: %h, result: %h",systolic_array.debug_processing_element.input_north, systolic_array.debug_processing_element.input_west, systolic_array.results_unpacked[0][0]);
        #2
        $display("north: %h, west: %h, result: %h",systolic_array.debug_processing_element.input_north, systolic_array.debug_processing_element.input_west, systolic_array.results_unpacked[0][0]);
        #14 // systolic array need to work 3*ARRAY_SIZE-1 cycles
        rst = 0;
        accumulate_enable = 0;
        inject = 0;
        bubble_west0 = 0;
        bubble_west1 = 0;
        bubble_west2 = 0;
        bubble_west3 = 0;
        bubble_north0 = 0;
        bubble_north1 = 0;
        bubble_north2 = 0;
        bubble_north3 = 0;

        // TA assigned the array's outputs to results_unpacked array
        // the reference result matrix should be:
        // cd6f b93c 37fb e7de 
        // 3b0d 657c 7325 455b 
        // a107 ece9 5c21 9b4e 
        // 11d8 26a1 5105 2650
        out_file = $fopen("array_output.txt", "w");
        for(i=0; i<`ARRAY_SIZE; i=i+1)
        begin
            for(j=0; j<`ARRAY_SIZE; j=j+1)
            begin
                $fwrite(out_file, "%4h ", systolic_array.results_unpacked[i][j]);
            end
            $fwrite(out_file, "\n");
        end
        $finish;

    end

endmodule