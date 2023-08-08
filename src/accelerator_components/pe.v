module PE #(
    parameter DATA_WIDTH=16 // 8bit inputs
) (
    input clk, rst,
    input accumulate_enable,
    input [DATA_WIDTH-1:0] input_north, input_west,
    output reg [DATA_WIDTH-1:0] output_south, output_east,
    output reg [DATA_WIDTH-1:0] result
);

    always @(posedge clk) begin
        if(rst) begin
            output_east <= 'b0;
            output_south <= 'b0;
            result <= 'b0;
        end
        else begin
            if(accumulate_enable) begin
                result <= result + input_north * input_west;
                // $display("input north is %h, input west is %h",input_north,input_west);
            end
            output_south <= input_north;
            output_east <= input_west;
        end
    end

endmodule