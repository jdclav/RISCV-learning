`include "./counter.v"

module bench();
   reg CLK;
   wire RESET = 0; 
   wire [31:0] LEDS;

   SOC uut(
     .CLK(CLK),
     .RESET(RESET),
     .LEDS(LEDS)
   );

   reg[31:0] prev_LEDS = 0;
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