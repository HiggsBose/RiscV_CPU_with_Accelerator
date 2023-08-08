module FIFOBuffer #(
    parameter DATA_WIDTH=16,
    parameter BUFFER_SIZE = 16 // the buffer can hold 63 elements at most
) (
    input clk, rst, 
    // inject: if high, inject buffer_input into registers
    // bubble: if high, pop out data from the 0th register (Tips: check the bit order)
    input inject, bubble,
    input [BUFFER_SIZE*DATA_WIDTH-1:0] buffer_input,
    output reg [DATA_WIDTH-1:0] buffer_output
);

    integer buffer_index;

    reg [DATA_WIDTH-1:0] buffer_data [BUFFER_SIZE-1:0];

    always @(posedge clk) begin
        if(rst) begin
            for(buffer_index=0; buffer_index<BUFFER_SIZE; buffer_index=buffer_index+1)begin
                buffer_data[buffer_index] <= 'b0;
            end
            buffer_output <= 'b0;
        end
        else if(inject)begin
            for(buffer_index=0; buffer_index<BUFFER_SIZE; buffer_index=buffer_index+1)begin
                buffer_data[buffer_index] <= buffer_input[DATA_WIDTH*(BUFFER_SIZE-buffer_index)-1 -: DATA_WIDTH];
            end
        end
        else if(bubble) begin
            for(buffer_index=0; buffer_index<BUFFER_SIZE; buffer_index=buffer_index+1) begin
                if(buffer_index==0) begin
                    buffer_output <= buffer_data[buffer_index];
                end
                else begin
                    buffer_data[buffer_index-1] <= buffer_data[buffer_index];
                end
            end
            buffer_data[BUFFER_SIZE-1] <= 'b0;
        end
    end



endmodule