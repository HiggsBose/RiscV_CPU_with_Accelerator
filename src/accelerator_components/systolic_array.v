`include "src/accelerator_components/pe.v"

module SystolicArray #(
    parameter ARRAY_SIZE=16, // this systolic array is organized as ARRAY_SIZE*ARRAY_SIZE
    parameter DATA_WIDTH=16 // data width of inputs
) (
    input clk, rst,
    input accumulate_enable, read_enable,
    input [ARRAY_SIZE*DATA_WIDTH-1:0] west_inputs, north_inputs,
    input [31:0] row_index,
    output [ARRAY_SIZE*DATA_WIDTH-1:0] results
);


    // receive each PE's output
    wire [DATA_WIDTH-1:0] results_unpacked[0:ARRAY_SIZE-1][0:ARRAY_SIZE-1];
    // pack the outputs of selected row
    genvar i, j;
    generate
        for(j=0; j<ARRAY_SIZE; j=j+1)
        begin
            assign results[(ARRAY_SIZE-j)*DATA_WIDTH-1 : (ARRAY_SIZE-j-1)*DATA_WIDTH] = (read_enable && (row_index<ARRAY_SIZE)) ? results_unpacked[row_index][j] : 0;
        end
    endgenerate

    // delaration of wires used in the PE array
    wire [DATA_WIDTH-1:0] NS [0:ARRAY_SIZE][0:ARRAY_SIZE];
    wire [DATA_WIDTH-1:0] WE [0:ARRAY_SIZE][0:ARRAY_SIZE];


    // instantiation of PE array
    genvar iRow, iCol;
    generate
        for(iRow=0; iRow<ARRAY_SIZE; iRow=iRow+1) begin
            for(iCol=0; iCol<ARRAY_SIZE; iCol=iCol+1) begin
                if(iRow==0 && iCol==0)begin
                    
                end
                else begin
                    PE processing_element(
                    .clk(clk),
                    .rst(rst),
                    .accumulate_enable(accumulate_enable),

                    .input_north(NS[iRow][iCol]),
                    .input_west(WE[iRow][iCol]),

                    .output_south(NS[iRow+1][iCol]),
                    .output_east(WE[iRow][iCol+1]),
                    .result(results_unpacked[iRow][iCol])
                    );
                end
                
            end
        end
    endgenerate
    PE debug_processing_element(
        .clk(clk),
        .rst(rst),
        .accumulate_enable(accumulate_enable),

        .input_north(NS[0][0]),
        .input_west(WE[0][0]),

        .output_south(NS[1][0]),
        .output_east(WE[0][1]),
        .result(results_unpacked[0][0])
    );


    // Connect the first set of wires to the input of the array
    generate
        for(iCol=0; iCol<ARRAY_SIZE; iCol=iCol+1) begin
            assign NS[0][iCol] = north_inputs[DATA_WIDTH*(ARRAY_SIZE-iCol)-1:DATA_WIDTH*(ARRAY_SIZE-1-iCol)];
            // assign NS[0][iCol] = north_inputs[DATA_WIDTH*(iCol+1)-1:DATA_WIDTH*(iCol)];
        end
        for(iRow=0; iRow<ARRAY_SIZE; iRow=iRow+1) begin
            assign WE[iRow][0] = west_inputs[DATA_WIDTH*(ARRAY_SIZE-iRow)-1:DATA_WIDTH*(ARRAY_SIZE-1-iRow)];
            // assign WE[iRow][0] = west_inputs[DATA_WIDTH*(1+iRow)-1:DATA_WIDTH*(iRow)];
        end
    endgenerate


endmodule
