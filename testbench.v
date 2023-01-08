`include "./counter.v"

module bench();
    reg CLK;
    wire RESET = 0; 
    wire [31:0] LEDS;

    clock_divider #(.DIV(20)) 
    divide(
        .CLK(CLK),
        .RESET(RESET),
        .dCLK(clk)
    );

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