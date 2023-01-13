module SOC (
    input CLK,        
    input RESET,      
    output [31:0] LEDS
);

    reg [31:0] MEM [0:255];
    reg [31:0] PC = 0;
    reg [31:0] LEDSoutput = 0;

    reg [31:0] rs1Register = 0;
    reg [31:0] rs2Register = 0;
    reg [31:0] writeDataRegister = 0;

    localparam fetch = 0;
    localparam decode = 1;
    localparam execute = 2;
    localparam memory = 3;
    localparam writeback = 4;

    reg[2:0] state = fetch;
    reg[31:0] instruction = 0;

    //Preloaded instructions
    initial begin
        MEM[0] = 32'b0000000_00000_00000_000_00001_0110011;
        MEM[1] = 32'b000000000001_00001_000_00001_0010011;
        MEM[2] = 32'b000000000001_00001_000_00001_0010011;
        MEM[3] = 32'b000000000001_00001_000_00001_0010011;
        MEM[4] = 32'b000000000001_00001_000_00001_0010011;
        MEM[6] = 32'b000000_00001_00010_010_00000_0100011;
        MEM[7] = 32'b000000000001_00000_000_00000_1110011;
    end
    //A state machine that controls each step of the processor
    always @(posedge CLK) begin
        case(state)
            fetch: begin
                instruction <= MEM[PC[31:2]];
                state <= decode;
            end
            decode: begin
                rs1Register <= rs1Value;
                rs2Register <= rs2Value;
                state <= execute;
            end
            execute: begin
                state <= memory;
            end
            memory: begin
                state <= writeback;
                LEDSoutput <= instruction;
            end
            writeback: begin
                if(writeEnable && rd != 0) begin
                    writeDataRegister <= 0;
                end
                PC <= PC + 4;
                state <= fetch;
            end
        endcase
    end

    assign LEDS = LEDSoutput;

    assign writeData = writeDataRegister;

    wire [31:0] rs1Value = 0;
    wire [31:0] rs2Value = 0;
    wire [31:0] writeData = 0;
    wire writeEnable = 0;

    registerBanks bank(
        .CLK(CLK),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .registerType(1'b0),
        .writeEnable(writeEnable),
        .writeData(writeData),
        .rs1Data(rs1Value),
        .rs2Data(rs2Value)
    );

    //These wires represent the decoded opcode from an instruction. When a given wire goes to one that means that instruction is taking place
    wire LUI = (instruction[6:0] == 7'b0110111);
    wire AUIPC = (instruction[6:0] == 7'b0010111);
    wire JAL = (instruction[6:0] == 7'b1101111);
    wire JALR = (instruction[6:0] == 7'b1100111);
    wire ALUimm = (instruction[6:0] == 7'b0010011);
    wire ALU = (instruction[6:0] == 7'b0110011);
    wire branch = (instruction[6:0] == 7'b1100011);
    wire load = (instruction[6:0] == 7'b0000011);
    wire store = (instruction[6:0] == 7'b0100011);
    wire fence = (instruction[6:0] == 7'b0001111);
    wire system = (instruction[6:0] == 7'b1110011);

    //These are the register IDs decoded from an instruction and will only be valid if the instruction needs a register
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20]; 
    wire [4:0] rd = instruction[11:7];

    //These are the function codes decoded from an instruction and are used by some instructions to fully determine that instruction to execute
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    //The decoded immediate value used by I type instructions
    wire [31:0] immediateImmediate = {{20{instruction[31]}}, instruction[31:20]};

    //The other immediates for other instructions
    wire [31:0] upperImmediate = {instruction[31:12], {12{1'b0}}};
    wire [31:0] storeImmediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    wire [31:0] branchImmediate = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    wire [31:0] jumpImmediate = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};

endmodule

// //The module that will 
module ALU (
    input ALU,
    input ALUimm,
    input [4:0] rs1,
    input [4:0] rs2,
    input [31:0] value1,
    input [31:0] value2,
    input [2:0] funct3,
    input [6:0] funct7,
    output [31:0] ALUresult
);
    reg [31:0] result = 0;
    always @(*) begin
        case(funct3)
            3'b000: result = (ALU & funct7[5]) ? (value1 - value2) : (value1 + value2);
            3'b001: result = (value1 << rs1);
            3'b010: result = ($signed(value1) < $signed(value2));
            3'b011: result = (value1 < value2);
            3'b100: result = (value1 ^ value2);
            3'b101: result = (funct7[5] ? ($signed(value1) >>> rs2) : (value1 >> rs2));
            3'b110: result = (value1 | value2);
            3'b111: result = (value1 & value2);
        endcase
    end
    assign ALUresult = result;

endmodule

//Takes in a clock signal and outputs a signal 2^ of the parameter slower than the input
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

//Acts as the module that will hold all types of register banks, currently only holds the integer registers
module registerBanks (
    input CLK,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input registerType,
    input writeEnable,
    input [31:0] writeData,
    output [31:0] rs1Data,
    output [31:0] rs2Data
);
    reg [31:0] integerRegisters [0:31];

    reg [31:0] rs1Out = 0;
    reg [31:0] rs2Out = 0;

    //On clock if writing in enabled and the zero register is not the target then write the input data to the register
    //Also on clock update the data presented by the rs1 and rs2 input registers
    always @(posedge CLK) begin
        if(registerType == 0) begin
            if(writeEnable && rd != 0) begin
                integerRegisters[rd] <= writeData;
            end
            rs1Out <= integerRegisters[rs1];
            rs2Out <= integerRegisters[rs2];
        end
    end

    assign rs1Data = rs1Out;
    assign rs2Data = rs2Out;

endmodule
