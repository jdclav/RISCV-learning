module SOC (
    input  CLK,        
    input  RESET,      
    output [31:0] LEDS
);

    reg [31:0] MEM [0:255];
    reg [31:0] PC = 0;
    reg [31:0] instruction;

    initial begin
        MEM[0] = 32'b0000000_00000_00000_000_00001_0110011;
        MEM[1] = 32'b000000000001_00001_000_00001_0010011;
        MEM[2] = 32'b000000000001_00001_000_00001_0010011;
        MEM[3] = 32'b000000000001_00001_000_00001_0010011;
        MEM[4] = 32'b000000000001_00001_000_00001_0010011;
        MEM[6] = 32'b000000_00001_00010_010_00000_0100011;
        MEM[7] = 32'b000000000001_00000_000_00000_1110011;
    end

    wire LUI = (instruction[5:0] == 7'b0110111);
    wire AUIPC = (instruction[5:0] == 7'b0010111);
    wire JAL = (instruction[5:0] == 7'b1101111);
    wire JALR = (instruction[5:0] == 7'b1100111);
    wire ALUimm = (instruction[5:0] == 7'b0010011);
    wire ALU = (instruction[5:0] == 7'b0110011);
    wire branch = (instruction[5:0] == 7'b1100011);
    wire load = (instruction[5:0] == 7'b0000011);
    wire store = (instruction[5:0] == 7'b0100011);
    wire fence = (instruction[5:0] == 7'b0001111);
    wire system = (instruction[5:0] == 7'b1110011);

    wire [3:0] rs1 = instruction[19:15];
    wire [3:0] rs2 = instruction[24:20]; 
    wire [3:0] rd = instruction[11:7];

    wire [1:0] funct3 = instruction[14:12];
    wire [5:0] funct7 = instruction[31:25];

    wire [30:0] imm = {{20{instruction[31]}}, instruction[31:20]};

    wire [31:0] upperImmediate = {instruction[31:12], {12{1'b0}}};
    wire [31:0] sImmediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    wire [31:0] bImmediate = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    wire [31:0] jImmediate = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};

    always @(posedge CLK) begin
        instruction <= PC;
        PC <= PC + 1;
    end

    assign LEDS = {{20{1'b0}}, LUI, AUIPC, JAL, JALR, ALUimm, ALU, branch, load, store, fence, system};

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