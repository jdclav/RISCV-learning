`default_nettype none
module top (
    input clk30,
    input [1:0] button,
    output [6:0] LED,
    output [2:0] LEDC
);

    localparam clk30frequency = 30000000;

    localparam idleState = 2'b00;
    localparam countState = 2'b01;
    localparam doneState = 2'b10;

    localparam maxLED = 4'b1111;

    wire rst = ~button[0];

    wire go = ~button[1];

    // Create a 32 bit register
    reg [31:0] counter = 0;

    reg dividedClock = 0;

    reg [1:0] state = idleState;

    reg [3:0] leds = 0;

    reg done = 0;

    // Every positive edge increment register by 1
    always @(posedge dividedClock or posedge rst) begin
        if(rst == 1'b1) begin
            
            state <= idleState;
        end else begin
            case (state)
                idleState: begin
                    if(go == 1'b1) begin
                        state <= countState;
                    end
                end
                countState: begin
                    if(leds == maxLED) begin
                        state <= doneState;
                    end
                end
                doneState: state <= idleState;
                default: state <= idleState;
            endcase
        end
    end

    always @(posedge dividedClock or posedge rst) begin
        if(rst == 1'b1) begin
            leds <= 0;
        end else begin
            if(state == countState) begin
                leds <= leds + 1;
            end else begin
                leds <= 0;
            end
        end
    end

    always @(*) begin 
        if(state == doneState) begin
            done = 1'b1;
        end else begin
            done = 0;
        end
    end

    always @(posedge clk30 or posedge rst) begin
        if(rst == 1'b1) begin
            counter <= 0;
        end else if(counter == ((clk30frequency/4) - 1)) begin
            counter <= 0;
            dividedClock <= ~dividedClock;
        end else begin
            counter <= counter + 1;
        end
    end

    
    // Output inverted values of counter onto LEDs
    assign LED = {done, 2'b00, leds};
    assign LEDC [0] = 1'b0;
    assign LEDC [1] = 1'b1;
    assign LEDC [2] = 1'b0;
endmodule
