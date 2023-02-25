`default_nettype none
`timescale 1 ns / 10 ps
`include "./modules/clock_divider.v"
module clock_divider_tb ();

    // The signal coming out of the clock divider
    wire    dividedClock;

    // Internal registers
    reg     clock = 0;
    reg     reset = 0;

    // The duration of the test
    localparam TOTAL_DURATION = 10000;

    always begin 
        #16.66
        clock = ~clock;
    end

    // Instantiating the clock divider as the unit under test
    clock_divider #(.MAX_COUNT(9)) uut (
        .clock_i(clock),
        .reset_i(reset),
        .out_o(dividedClock)
    );

    // Pulse the reset to set everything to a known state
    initial begin
        #10
        reset = 1'b1;
        #1
        reset = 1'b0;
    end

    initial begin

        // Create a simulation file
        $dumpfile("clock_divider_tb.vcd");
        $dumpvars(0, clock_divider_tb);

        // Delay by the intended test time
        #(TOTAL_DURATION);

        // Declare the end of test and end the test
        $display("Test Complete!");
        $finish;

    end

endmodule