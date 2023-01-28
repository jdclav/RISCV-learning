`default_nettype none
module top (
    input clk30,
    input [1:0] button,
    output [6:0] LED,
    output [2:0] LEDC
);
    // Create a 32 bit register
    reg [6:0] counter = 0;

    wire rst;
    wire clk;

    assign rst = ~button[0];

    assign clk = ~button[1];
    
    // Every positive edge increment register by 1
    always @(posedge clk or posedge rst) begin
        if(rst == 1'b1) begin 
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

    // Output inverted values of counter onto LEDs
    assign LED = counter;
    assign LEDC [0] = 1'b0;
    assign LEDC [1] = 1'b1;
    assign LEDC [2] = 1'b0;
endmodule
