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

module clock_divider (
    input CLK,
    input RESET,
    output dCLK
);
    parameter DIV = 0;

    reg[DIV:0] divided_clk = 0;

    always @(posedge CLK) begin
        divided_clk <= divided_clk + 1;
    end

    assign dCLK = divided_clk[DIV];

endmodule