module decoder (
    input [31:0]instruction
);

    wire LUI = (instruction[6:0] == 7'b0110111);
    wire AUIPC = (instruction[6:0] == 7'b0010111);
    wire JAL = (instruction[6:0] == 7'b1101111);
    wire JALR = (instruction[6:0] == 7'b1100111);
    wire ALUimm = (instruction[6:0] == 7'b0010011);
    wire ALU = (instruction[6:0] == 7'b0110011);
    wire branch = (instruction[6:0] == 7'b1100011);
    wire load = (instruction[6:0] == 7'b0000011);
    wire store = (instruction[6:0] == 7'b0100011);
    wire fench = (instruction[6:0] == 7'b0001111);
    wire system = (instruction[6:0] == 7'b1110011);

    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20]; 
    wire [4:0] rd = instruction[11:7];

    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    wire [31:0] imm = {{20{instruction[31]}}, instruction[31:20]};

    wire [31:0] upperImmediate = {instruction[31:12], {12{1'b0}}};
    wire [31:0] sImmediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    wire [31:0] bImmediate = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    wire [31:0] jImmediate = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};

    

endmodule