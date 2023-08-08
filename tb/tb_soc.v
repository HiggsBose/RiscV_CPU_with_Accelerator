`timescale 1ns/1ns

// for verification
// you can change it to adjust which test code you want to run
`define TEST_TYPE 2
// define the problem size
`define QUICKSORT_SIZE 532

`include "src/riscv_top.v"

module TB_SoC;
    initial begin            
        $dumpfile("wave.vcd");  // generate wave.vcd
        $dumpvars(0, TB_SoC);   // dump all of the TB module data
    end

    reg clk;
    initial clk = 0;
    always #1 clk = ~clk;

    reg rst, debug;

    initial 
    begin
        #0
        rst = 1;
        debug = 0;
    
        #2
        rst = 0;

        if(`TEST_TYPE==0 || `TEST_TYPE==1)
        begin
            #500000
            debug = 1;
        end
        else if(`TEST_TYPE==1)
        begin
            #400000
            debug = 1;
        end
        else if(`TEST_TYPE==2 || `TEST_TYPE==3)
        begin
            #30000
            debug = 1;
        end
        else if(`TEST_TYPE==4)
        begin
            #20000
            debug = 1;
        end
        #2
        debug = 0;
        $finish;

    end

    RISCVSoC riscv_soc(
        .clk(clk), .rst(rst), .debug(debug)
    );

endmodule