`include "Simple/processor.v"

module bench(    
    input clk30,
    output [6:0] led_rgb_multiplex_a,
    output [2:0] led_rgb_multiplex_b
);
    reg CLK;
    wire RESET = 0; 
    wire [31:0] LEDS;
   
    //Used to slow down operation so that outputs can be observed. 18 works pretty well to observe outputs.
    clock_divider #(.DIV(18)) 
    divide(
        .CLK(CLK),
        .RESET(RESET),
        .dCLK(clk)
    );

    //The SOC currently only uses clk.
    SOC test(
        .CLK(clk),
        .RESET(RESET),
        .LEDS(LEDS)
    );

    reg[31:0] prev_LEDS = 0;

    wire clk;

    initial begin
        CLK = 0;
        forever begin
            #1 CLK = ~CLK;

            if(LEDS != prev_LEDS) begin
                $display("LEDS = %b",LEDS);
            end

            prev_LEDS <= LEDS;

        end
    end

endmodule  