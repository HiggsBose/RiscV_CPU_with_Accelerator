`include "src/defines.v"

module ROM (
    input clk,
    input [31:0] addr,
    output [31:0] data_out
);
    parameter LEN = 65536;
    reg [31:0] mem_core [0:LEN-1];

    integer i;
    initial 
    begin
        for(i=1; i<=LEN; i+=1)
        begin
            mem_core[i-1] = 0; 
        end

        if(`TEST_TYPE==0)
        begin
            $readmemh("test_codes/0_quicksort/inst_data.hex", mem_core);
        end
        else if(`TEST_TYPE==1)
        begin
            $readmemh("test_codes/1_quicksort_flush/inst_data.hex", mem_core);
        end
        else if(`TEST_TYPE==2)
        begin
            $readmemh("test_codes/2_fc_2_layers/inst_data.hex", mem_core);
        end
        else if(`TEST_TYPE==3)
        begin
            $readmemh("test_codes/3_fc_2_layers_flush/inst_data.hex", mem_core);
        end
        else if(`TEST_TYPE==4)
        begin
            $readmemh("test_codes/4_basic_functionality_test/inst_data.hex", mem_core);
        end
    end

    assign data_out = mem_core[addr>>2];

endmodule