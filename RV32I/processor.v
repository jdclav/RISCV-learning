module SOC (
    input CLK,        
    input RESET,      
    output [31:0] LEDS
);

    reg [31:0] MEM [0:255];
    reg [31:0] PC = 0;
    reg [31:0] LEDSoutput = 0;

    wire [31:0] value1Register = rs1Value;
    wire [31:0] value2Register = immediate ? immediateImmediate : rs2Value;

    localparam fetch = 0;
    localparam decode = 1;
    localparam execute = 2;
    localparam memory = 3;
    localparam writeback = 4;

    reg[2:0] state = fetch;
    reg[31:0] instruction = 0;

    //Preloaded instructions
    `include "../Tools/riscv_assembly.v"
    initial begin
        ADD(x0,x0,x0);
        ADD(x1,x0,x0);
        ADDI(x1,x1,1);
        ADDI(x1,x1,1);
        ADDI(x1,x1,1);
        ADDI(x1,x1,1);
        ADD(x2,x1,x0);
        ADD(x3,x1,x2);
        SRLI(x3,x3,3);
        SLLI(x3,x3,31);
        SRAI(x3,x3,5);
        SRLI(x1,x3,26);
        EBREAK();
    end

    //A state machine that controls each step of the processor
    always @(posedge CLK) begin
        case(state)
            fetch: begin
                instruction <= MEM[PC[31:2]];
                state <= decode;
            end
            decode: begin
                state <= execute;
            end
            execute: begin
                state <= memory;
            end
            memory: begin
                state <= writeback;
            end
            writeback: begin
                PC <= PC + 4;
                state <= fetch;
            end
        endcase
    end

    assign LEDS = LEDSoutput;


    assign writeEnable = ((ALU_I || ALUimm_I) & (state == writeback));

    assign immediate = ALUimm_I;

    wire [31:0] rs1Value;
    wire [31:0] rs2Value;
    wire [31:0] writeData;
    wire writeEnable;
    wire writeStep;

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

    ALU compute(
        .ALU(ALU_I),
        .rs1(rs1),
        .rs2(rs2),
        .value1(value1Register),
        .value2(value2Register),
        .funct3(funct3),
        .funct7(funct7),
        .ALUresult(writeData)
    );

    //These wires represent the decoded opcode from an instruction. When a given wire goes to one that means that instruction is taking place
    wire LUI_I = (instruction[6:0] == 7'b0110111);
    wire AUIPC_I = (instruction[6:0] == 7'b0010111);
    wire JAL_I = (instruction[6:0] == 7'b1101111);
    wire JALR_I = (instruction[6:0] == 7'b1100111);
    wire ALUimm_I = (instruction[6:0] == 7'b0010011);
    wire ALU_I = (instruction[6:0] == 7'b0110011);
    wire branch_I = (instruction[6:0] == 7'b1100011);
    wire load_I = (instruction[6:0] == 7'b0000011);
    wire store_I = (instruction[6:0] == 7'b0100011);
    wire fence_I = (instruction[6:0] == 7'b0001111);
    wire system_I = (instruction[6:0] == 7'b1110011);

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

    always @(posedge CLK) begin
        $display("PC=%0d",PC);
        $display(funct7[5]);
        case (1'b1)
            ALU_I: $display("ALUreg rd=%d rs1=%d rs2=%d funct3=%b",rd, rs1, rs2, funct3);
            ALUimm_I: $display("ALUimm rd=%d rs1=%d imm=%0d funct3=%b",rd, rs1, immediateImmediate, funct3);
            branch_I: $display("BRANCH");
            JAL_I:    $display("JAL");
            JALR_I:   $display("JALR");
            AUIPC_I:  $display("AUIPC");
            LUI_I:    $display("LUI");	
            load_I:   $display("LOAD");
            store_I:  $display("STORE");
            system_I: $display("SYSTEM");
            fence_I: $display("FENCE");
        endcase 
    end

endmodule

//The module that will act as the ALU and will perform calculations
module ALU (
    input ALU,
    input [4:0] rs1,
    input [4:0] rs2,
    input [31:0] value1,
    input [31:0] value2,
    input [2:0] funct3,
    input [6:0] funct7,
    output [31:0] ALUresult
);
    reg [31:0] result;
    always @(*) begin
        case(funct3)
            3'b000: result = (ALU & funct7[5]) ? (value1 - value2) : (value1 + value2);
            3'b001: result = (value1 << rs2);
            3'b010: result = ($signed(value1) < $signed(value2));
            3'b011: result = (value1 < value2);
            3'b100: result = (value1 ^ value2);
            3'b101: result = funct7[5] ? ($signed(value1) >>> rs2) : (value1 >> rs2);
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


    integer     i;
    initial begin
        for(i=0; i<32; ++i) begin
            integerRegisters[i] = 0;
        end
    end

    //On clock if writing in enabled and the zero register is not the target then write the input data to the register
    //Also on clock update the data presented by the rs1 and rs2 input registers
    always @(posedge CLK) begin
        if(registerType == 0) begin
            if(writeEnable && rd != 0) begin
                integerRegisters[rd] <= writeData;
                $display(writeData);
            end
            rs1Out <= integerRegisters[rs1];
            rs2Out <= integerRegisters[rs2];
        end
    end

    assign rs1Data = rs1Out;
    assign rs2Data = rs2Out;

endmodule
