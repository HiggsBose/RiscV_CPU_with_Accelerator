`include "src/defines.v"

module RAM #(
    parameter ADDR_LEN = 16
) (
    input clk, debug,
    input write_enable,
    input [31:0] addr,
    input [31:0] data_in,
    output [31:0] data_out
);

    integer out_file;
    parameter LEN = 1 << ADDR_LEN;
    reg [31:0] mem_core [0:LEN-1];

    integer i, j;
    initial 
    begin
        for(i=1; i<=LEN; i+=1)
        begin
            mem_core[i-1] = 0; 
        end


        if(`TEST_TYPE==0)
        begin
            $readmemh("test_codes/0_quicksort/mem_data.hex", mem_core);
            out_file = $fopen("mem0.txt", "w");
        end
        else if(`TEST_TYPE==1)
        begin
            $readmemh("test_codes/1_quicksort_flush/mem_data.hex", mem_core);
            out_file = $fopen("mem1.txt", "w");
        end
        else if(`TEST_TYPE==2)
        begin
            $readmemh("test_codes/2_fc_2_layers/mem_data.hex", mem_core);
            out_file = $fopen("mem2.txt", "w");
        end
        else if(`TEST_TYPE==3)
        begin
            $readmemh("test_codes/3_fc_2_layers_flush/mem_data.hex", mem_core);
            out_file = $fopen("mem3.txt", "w");
        end
        else if(`TEST_TYPE==4)
        begin
            $readmemh("test_codes/4_basic_functionality_test/mem_data.hex", mem_core);
            out_file = $fopen("mem4.txt", "w");
        end
    end

    // output memory data for result verification
    integer ram_index = 0;
    always @(posedge clk) 
    begin
        if(debug)
        begin
            if(`TEST_TYPE==0)
            begin
                for(i=0; i<512; i+=1)
                begin
                    $fwrite(out_file, "%8h\n", mem_core[i]);
                end
            end
            else if(`TEST_TYPE==1)
            begin
                for(i=0; i<512; i+=1)
                begin
                    $fwrite(out_file, "%8h\n", mem_core[i]);
                end
            end
            else if(`TEST_TYPE==2)
            begin
                ram_index = 896;
                $fwrite(out_file, "layer 1 output matrix (size: 32x16)\n");
                for(i=0; i<32; i=i+1)
                begin
                    for(j=0; j<16; j=j+2)
                    begin
                        $fwrite(out_file, "%4h ", mem_core[ram_index][31:16]);
                        $fwrite(out_file, "%4h ", mem_core[ram_index][15:0]);
                        ram_index = ram_index+1;
                    end
                    $fwrite(out_file, "\n");
                end
                $fwrite(out_file, "layer 2 output matrix (size: 32x16)\n");
                for(i=0; i<32; i=i+1)
                begin
                    for(j=0; j<16; j=j+2)
                    begin
                        $fwrite(out_file, "%4h ", mem_core[ram_index][31:16]);
                        $fwrite(out_file, "%4h ", mem_core[ram_index][15:0]);
                        ram_index = ram_index+1;
                    end
                    $fwrite(out_file, "\n");
                end
            end
            else if(`TEST_TYPE==3)
            begin
                ram_index = 896;
                $fwrite(out_file, "layer 1 output matrix (size: 32x16)\n");
                for(i=0; i<32; i=i+1)
                begin
                    for(j=0; j<16; j=j+2)
                    begin
                        $fwrite(out_file, "%4h ", mem_core[ram_index][31:16]);
                        $fwrite(out_file, "%4h ", mem_core[ram_index][15:0]);
                        ram_index = ram_index+1;
                    end
                    $fwrite(out_file, "\n");
                end
                $fwrite(out_file, "layer 2 output matrix (size: 32x16)\n");
                for(i=0; i<32; i=i+1)
                begin
                    for(j=0; j<16; j=j+2)
                    begin
                        $fwrite(out_file, "%4h ", mem_core[ram_index][31:16]);
                        $fwrite(out_file, "%4h ", mem_core[ram_index][15:0]);
                        ram_index = ram_index+1;
                    end
                    $fwrite(out_file, "\n");
                end
            end
            else if(`TEST_TYPE==4)
            begin
                ram_index = 896;
                $fwrite(out_file, "layer 1 output matrix (size: 32*16)\n");
                for(i=0; i<32; i=i+1)
                begin
                    for(j=0; j<16; j=j+2)
                    begin
                        $fwrite(out_file, "%4h ", mem_core[ram_index][31:16]);
                        $fwrite(out_file, "%4h ", mem_core[ram_index][15:0]);
                        ram_index = ram_index+1;
                    end
                    $fwrite(out_file, "\n");
                end
                $fwrite(out_file, "layer 2 output matrix (size: 32*16)\n");
                for(i=0; i<32; i=i+1)
                begin
                    for(j=0; j<16; j=j+2)
                    begin
                        $fwrite(out_file, "%4h ", mem_core[ram_index][31:16]);
                        $fwrite(out_file, "%4h ", mem_core[ram_index][15:0]);
                        ram_index = ram_index+1;
                    end
                    $fwrite(out_file, "\n");
                end
            end
        end    
    end





    // write data to memory
    always @(posedge clk) 
    begin
        if(write_enable)
        begin
            mem_core[addr[ADDR_LEN+1:2]] <= data_in;
        end    
    end

    // read data from memory
    assign data_out = mem_core[addr[ADDR_LEN+1:2]];



endmodule