`default_nettype none
module clock_divider #(
    parameter                   COUNT_WIDTH = 32,
    parameter   [COUNT_WIDTH:0] MAX_COUNT   = 15000000 - 1
) (
    input clock_i,
    input reset_i,

    output reg out_o
);

    

    //Internal Registers
    reg divide_clock;
    reg [COUNT_WIDTH:0] count;

    //Clock divider
    always @(posedge clock_i or posedge reset_i) begin
        if (reset_i == 1'b1) begin
            count <= 0;
            out_o <= 0;
        end else if (count == MAX_COUNT) begin
            count <= 0;
            out_o <= ~out_o;
        end else begin
            count <= count + 1;
        end
    end

endmodule
