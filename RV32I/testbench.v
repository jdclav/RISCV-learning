`include "RV32I/counter.v"

module bench();
    reg CLK;
    wire RESET = 0; 
    wire [31:0] LEDS;
    reg [31:0] MEM [0:255];

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
        MEM[0] = 32'b0000000_00000_00000_000_00001_0110011;
        MEM[1] = 32'b000000000001_00001_000_00001_0010011;
        MEM[2] = 32'b000000000001_00001_000_00001_0010011;
        MEM[3] = 32'b000000000001_00001_000_00001_0010011;
        MEM[4] = 32'b000000000001_00001_000_00001_0010011;
        MEM[6] = 32'b000000_00001_00010_010_00000_0100011;
        MEM[7] = 32'b000000000001_00000_000_00000_1110011;
      
    end

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