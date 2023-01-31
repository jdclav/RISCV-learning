`default_nettype none
module top (
    input           clk30,
    input [1:0]     button,
    
    output [6:0]    LED,
    output [2:0]    LEDC
);

    wire reset  = ~button[0];
    wire go     = ~button[1];

    wire nextUp;
    wire nextDown;
    
    wire countUp    = go | nextUp;
    wire countDown  = nextDown;

    wire [6:0] ledsUp;
    wire [6:0] ledsDown;

    wire dividedClock;

    reg [6:0] leds;
    
    reg count_direction;

    clock_divider #(
        .MAX_COUNT(2000000 - 1)
    ) div_1 (
        .clock_i(clk30),
        .reset_i(reset),
        .out_o(dividedClock)
    );

    count_up_down #(
        .UP_DOWN(1'b1)
    ) up (
        .clock_i(dividedClock),
        .reset_i(reset),
        .go_i(countUp),
        .led_o(ledsUp),
        .next_o(nextDown)
    );
    
    count_up_down #(
        .UP_DOWN(1'b0)
    ) down (
        .clock_i(dividedClock),
        .reset_i(reset),
        .go_i(countDown),
        .led_o(ledsDown),
        .next_o(nextUp)
    );

    always @(posedge dividedClock or posedge reset) begin
        if (reset == 1'b1) begin
            count_direction <= 1'b1;
        end else begin
            if (nextUp == 1'b1) begin
                count_direction <= 1'b1;
            end else if (nextDown == 1'b1) begin
                count_direction <= 1'b0;
            end
        end
    end
            

    always @( * ) begin
        if (count_direction == 1'b1) begin
            leds <= ledsUp;
        end else begin
            leds <= ledsDown;
        end
    end


    assign LED = leds;

    assign LEDC [0] = 1'b0;
    assign LEDC [1] = 1'b1;
    assign LEDC [2] = 1'b0;
    
endmodule

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

module count_up_down #(
    parameter UP_DOWN = 0,
    parameter MAX_COUNT = 7'b1111111
) (
    input           clock_i,
    input           reset_i,
    input           go_i,

    output [6:0]    led_o,
    output          next_o
);

    localparam IDLE_STATE = 1'b0;
    localparam COUNT_STATE = 1'b1;

    reg state;

    reg [6:0]   leds;
    reg         next;

    always @(posedge clock_i or posedge reset_i) begin
        if (reset_i == 1'b1) begin
            state <= IDLE_STATE;
        end else begin
            case (state)
                IDLE_STATE: begin
                    next <= 0;
                    if (go_i == 1'b1) begin
                        state <= COUNT_STATE;
                    end
                end
                COUNT_STATE: begin
                    if (UP_DOWN == 1'b1 && leds == MAX_COUNT) begin
                        next <= 1'b1;
                        state <= IDLE_STATE;
                    end else if (UP_DOWN == 1'b0 && leds == 0) begin
                        next <= 1'b1;
                        state <= IDLE_STATE;
                    end
                end
            endcase
        end
    end

    always @(posedge clock_i or posedge reset_i) begin
        if (reset_i == 1'b1) begin
            leds <= 0;
        end else begin
            case (state)
                IDLE_STATE: begin
                    if (UP_DOWN == 1'b1) begin
                        leds <= 0;
                    end else begin
                        leds <= MAX_COUNT;
                    end
                end
                COUNT_STATE: begin
                    if (UP_DOWN == 1'b1) begin
                        if (leds != MAX_COUNT) begin
                            leds <= leds + 1;
                        end 
                    end else begin
                        if (leds != 0) begin
                            leds <= leds - 1;
                        end
                    end
                end
            endcase
        end
    end

    assign next_o = next;
    assign led_o = leds;

endmodule

