`default_nettype none
module top (
    input clk30,
    input [1:0] button,
    output [6:0] LED,
    output [2:0] LEDC
);

    localparam clk30frequency = 30000000;

    wire rst = ~button[0];

    // Create a 32 bit register
    reg [31:0] counter = 0;

    reg oneSecond = 0;

    reg [6:0] leds = 0;

    // Every positive edge increment register by 1
    always @(posedge oneSecond or posedge rst) begin
        if(rst == 1'b1) begin
            leds <= 0;
        end else begin
            leds <= leds + 1;
        end
    end

    always @(posedge clk30 or posedge rst) begin
        if(rst == 1'b1) begin
            counter <= 0;
        end else if(counter == ((clk30frequency/2) - 1)) begin
            counter <= 0;
            oneSecond<= ~oneSecond;
        end else begin
            counter <= counter + 1;
        end
    end

    
    // Output inverted values of counter onto LEDs
    assign LED = leds;
    assign LEDC [0] = 1'b0;
    assign LEDC [1] = 1'b1;
    assign LEDC [2] = 1'b0;
endmodule
