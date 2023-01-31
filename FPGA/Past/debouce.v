`default_nettype none
module top (
    input clk30,
    input [1:0] button,
    output [6:0] LED,
    output [2:0] LEDC
);
    localparam clk30frequency = 30000000;

    localparam depressed = 2'b00;
    localparam pressed = 2'b01;
    localparam hold = 2'b10;

    wire rst = ~button[0];

    wire go = ~button[1];

    // Create a 32 bit register
    reg [31:0] counter = 0;

    reg dividedClock = 0;

    reg [1:0] state = depressed;

    reg [6:0] leds = 0;

    // Every positive edge increment register by 1
    always @(posedge clk30 or posedge rst) begin
        if(rst == 1'b1) begin
            leds <= 0;   
            state <= depressed;
        end else begin
            case (state)
                depressed: begin
                    if(go == 1'b1) begin
                        state <= pressed;
                    end
                end
                pressed: begin
                    if((go == 1'b1) & (counter >= (clk30frequency/100) - 1)) begin
                        leds <= leds + 1;
                        state <= hold;
                    end else if (go == 0) begin
                        state <= depressed;
                    end 
                end
                hold: begin
                    if(go == 0) begin
                        state <= depressed;
                    end
                end
                default: state <= depressed;
            endcase
        end
    end


    always @(posedge clk30 or posedge rst) begin
        if(rst == 1'b1) begin
            counter <= 0;
        end else if(state == pressed) begin
            counter <= counter + 1;
        end else begin
            counter <= 0;
        end
    end

    
    // Output inverted values of counter onto LEDs
    assign LED = leds;
    assign LEDC [0] = 1'b0;
    assign LEDC [1] = 1'b1;
    assign LEDC [2] = 1'b0;
endmodule
