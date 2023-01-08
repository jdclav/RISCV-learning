module SOC (
      input  CLK,        
      input  RESET,      
      output [31:0] LEDS
);

reg [31:0] count = 0;
always @(posedge CLK) begin
   count <= count + 1;
end
assign LEDS = count;

endmodule