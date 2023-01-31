`default_nettype none
`include "./modules/clock_divider.v"
module top (
    input           clk30,
    input [1:0]     button,
    
    output [6:0]    LED,
    output [2:0]    LEDC
);

    wire reset = ~button[0];

    clock_divider #(.MAX_COUNT(30000000 - 1)) div_1 (
        .clock_i(clk30),
        .reset_i(reset),
        .out_o(LED[0])
    );

    clock_divider div_2 (
        .clock_i(clk30),
        .reset_i(reset),
        .out_o(LED[1])
    );

    assign LEDC [0] = 1'b0;
    assign LEDC [1] = 1'b1;
    assign LEDC [2] = 1'b0;
    
    endmodule