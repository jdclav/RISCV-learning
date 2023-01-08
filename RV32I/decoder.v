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
    
    

endmodule