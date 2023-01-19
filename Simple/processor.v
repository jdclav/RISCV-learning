module SOC (
    input CLK,        
    input RESET,      
    output [31:0] LEDS
);

    //Currently acts as both program memory and data memory. When provided an address the data at that address will either
    //output the data (aligned by the word) to the readData line if the read line is high or write data to the address with a 
    //writeMask that determines which byte of the word is written to
    program_memory rom(
        .CLK(CLK),
        .address(address),
        .writeData(writeData),
        .writeMask(writeMask),
        .readData(readData),
        .read(read)
    );

    //The processor takes data in through its readData line based on the address provided on the address line. See above comment
    //for more details on the interaction with memory
    processor CPU(
        .CLK(CLK),
        .address(address),
        .readData(readData),
        .writeDataMemory(writeData),
        .writeMask(writeMask), 
        .read(read)
    );

    wire [31:0] writeData;
    wire [3:0] writeMask;
    wire [31:0] address;
    wire [31:0] readData;
    wire read;

endmodule

module processor (
    input CLK,
    output [31:0] address,
    input [31:0] readData,
    output [31:0] writeDataMemory,
    output [3:0] writeMask,
    output read
);

    //A state machine that controls each step of the processor
    always @(posedge CLK) begin
        case(state)
            fetch: begin
                state <= decode;
            end
            decode: begin
                state <= execute;
                instruction <= readData;
            end
            execute: begin
                if(system_I) begin
                    $finish();
                end
                state <= memory;
            end
            memory: begin
                state <= writeback;
            end
            writeback: begin
                PC <= nextPC;
                state <= fetch;
            end
        endcase
    end

    //Reading is enabled (read line set high) if the state is fetch or the state is memory and data is being read.
    assign read = (state == fetch || (state == memory && load_I));
    //The address to be read which will either be the next instruction(PC) or the address for a data access.
    assign address = (state == fetch) ? PC : addressLoadStore;

    //PC is the program counter and tracks which instruction is being processed.
    reg [31:0] PC = 0;
    reg [31:0] LEDSoutput = 0;

    //The value1Register holds the value from the first source register. The value2Register holds the value from the second
    //source register if there is one or an immediate value if relavent
    wire [31:0] value1Register = rs1Value;
    wire [31:0] value2Register = ALUimm_I | JALR_I ? immediateImmediate : rs2Value;

    localparam fetch = 0;
    localparam decode = 1;
    localparam execute = 2;
    localparam memory = 3;
    localparam writeback = 4;

    reg[2:0] state = fetch;
    reg[31:0] instruction = 0;

    assign LEDS = LEDSoutput;

    assign writeDataRegister = (JAL_I || JALR_I) ? (PCplus4) : (LUI_I) ? upperImmediate : (AUIPC_I) ? PCplusImmediate : load_I ? loadData : writeDataALU;

    assign writeEnable = ((!branch_I && !store_I) & (state == writeback));

    assign nextPC = ((branch_I && takeBranch) || JAL_I) ? PCplusImmediate : JALR_I ? {addition[31:1], 1'b0}: PCplus4;

    assign PCplusImmediate = PC + (JAL_I ? jumpImmediate : AUIPC_I ? upperImmediate : branchImmediate);

    assign PCplus4 = PC + 4;

    assign addressLoadStore = value1Register + (load_I ? immediateImmediate : storeImmediate);

    assign halfwordLoad = addressLoadStore[1] ? readData[31:16] : readData[15:0];

    assign byteLoad = addressLoadStore[0] ? halfwordLoad[15:8] : halfwordLoad[7:0];

    assign byteAccess = funct3[1:0] == 2'b00;

    assign halfwordAccess = funct3[1:0] == 2'b01;

    assign loadData = byteAccess ? {{24{loadSign}}, byteLoad} : halfwordAccess ? {{16{loadSign}}, halfwordLoad} : readData;

    assign loadSign = !funct3[2] & (byteAccess ? byteLoad[7] : halfwordLoad[15]);

    assign writeDataMemory[7:0] = value2Register [7:0];

    assign writeDataMemory[15:8] = addressLoadStore[0] ? value2Register[7:0] : value2Register[15:8];

    assign writeDataMemory[23:16] = addressLoadStore[1] ? value2Register[7:0] : value2Register[23:16];

    assign writeDataMemory[31:24] = addressLoadStore[0] ? value2Register[7:0] : addressLoadStore[1] ? value2Register[15:8] : value2Register [31:24];

    assign storeMask = byteAccess ? (addressLoadStore[1] ? (addressLoadStore[0] ? 4'b1000 : 4'b0100) : (addressLoadStore[0] ? 4'b0010 : 4'b0001)) : halfwordAccess ? (addressLoadStore[1] ? 4'b1100 : 4'b0011) : 4'b1111;

    assign writeMask = {4{(state == memory && store_I)}} & storeMask;

    wire [31:0] storeMask;
    wire loadSign; 
    wire [31:0] loadData;
    wire byteAccess;
    wire halfwordAccess;
    wire [31:0] rs1Value;
    wire [31:0] rs2Value;
    wire [31:0] writeDataALU;
    wire writeEnable;
    wire writeStep;
    wire [31:0] writeDataRegister;
    wire [31:0] nextPC;
    wire takeBranch;
    wire [31:0] addition;
    wire [31:0] PCplus4;
    wire [31:0] PCplusImmediate;
    wire [31:0] addressLoadStore;
    wire [15:0] halfwordLoad;
    wire [7:0] byteLoad;

    registerBanks bank(
        .CLK(CLK),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .registerType(1'b0),
        .writeEnable(writeEnable),
        .writeData(writeDataRegister),
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
        .ALUresult(writeDataALU),
        .takeBranch(takeBranch),
        .addition(addition)
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
    output [31:0] ALUresult,
    output takeBranch,
    output [31:0] addition
);

    function [31:0] flip;
        input [31:0] in;
        flip = {in[0],in[1],in[2],in[3],in[4],in[5],in[6],in[7],in[8],in[9],in[10],in[11],in[12],in[13],in[14],in[15],in[16],in[17],in[18],in[19],in[20],in[21],in[22],in[23],in[24],in[25],in[26],in[27],in[28],in[29],in[30],in[31]};
    endfunction

    wire [32:0] subtration = {1'b0,value1} - {1'b0,value2};
    wire equal = (subtration[31:0] == 0);
    wire lessThanUnsigned = subtration[32];
    wire lessThan = (value1[31] ^ value2[31]) ? value1[31] : subtration[32];
    wire [31:0] add = value1 + value2;
    wire [31:0] shift_in = (funct3 == 3'b001) ? flip(value1) : value1;
    wire [32:0] shifter = $signed({funct7[5] & value1[31], shift_in}) >>> rs2;
    wire [31:0] left_shift = flip(shifter[31:0]);

    reg [31:0] result;
    always @(*) begin
        case(funct3)
            3'b000: result = (ALU & funct7[5]) ? subtration[31:0] : add;
            3'b001: result = left_shift;
            3'b010: result = {31'b0, lessThan};
            3'b011: result = {31'b0, lessThanUnsigned};
            3'b100: result = (value1 ^ value2);
            3'b101: result = shifter;
            3'b110: result = (value1 | value2);
            3'b111: result = (value1 & value2);
        endcase
    end

    reg branch;
    always @(*) begin
        case(funct3)
            3'b000: branch = equal;
            3'b001: branch = !equal;
            3'b100: branch = lessThan;
            3'b101: branch = !lessThan;
            3'b110: branch = lessThanUnsigned;
            3'b111: branch = !lessThanUnsigned;
            default: branch = 1'b0;
        endcase
    end
    assign takeBranch = branch;
    assign ALUresult = result;
    assign addition = add;
endmodule

module program_memory (
    input CLK,
    input [31:0] address,
    input read,
    input [31:0] writeData,
    input [3:0] writeMask,
    output reg [31:0] readData
);

    reg [31:0] MEM [0:255];

    `include "../tools/riscv_assembly.v"
    integer L0_   = 12;
    integer L1_   = 32;
    integer wait_ = 64;   
    integer L2_   = 72;

    initial begin

        LI(a0,0);
        LI(s1,4);      
        LI(s0,0);         
        Label(L0_); 
        LB(a1,s0,400);
        SB(a1,s0,800);       
        //CALL(LabelRef(wait_));
        ADDI(s0,s0,1); 
        BNE(s0,s1, LabelRef(L0_));

        // Read 16 bytes from adress 800
        LI(s0,0);
        Label(L1_);
        LB(a0,s0,800); // a0 (=x10) is plugged to the LEDs
        //CALL(LabelRef(wait_));
        ADDI(s0,s0,1); 
        BNE(s0,s1, LabelRef(L1_));
        EBREAK();

        Label(wait_);
        LI(t0,1);
        SLLI(t0,t0,1);
        Label(L2_);
        ADDI(t0,t0,-1);
        BNEZ(t0,LabelRef(L2_));
        RET();

        endASM();

        // Note: index 100 (word address)
        //     corresponds to 
        // address 400 (byte address)
        MEM[100] = {8'h4, 8'h3, 8'h2, 8'h1};
        MEM[101] = {8'h8, 8'h7, 8'h6, 8'h5};
        MEM[102] = {8'hc, 8'hb, 8'ha, 8'h9};
        MEM[103] = {8'hff, 8'hf, 8'he, 8'hd};            
    end

    wire [29:0] wordAddress = address[31:2];

    always @(posedge CLK) begin
        if(read) begin
            readData <= MEM[address[31:2]];
        end
        case (1'b1)
            writeMask[0]: MEM[wordAddress][7:0] <= writeData[7:0];
            writeMask[1]: MEM[wordAddress][15:8] <= writeData[15:8];
            writeMask[2]: MEM[wordAddress][23:16] <= writeData[23:16];
            writeMask[3]: MEM[wordAddress][31:24] <= writeData[31:24];
        endcase
    end
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
                $display("Register Write %b",writeData);
            end
            rs1Out <= integerRegisters[rs1];
            rs2Out <= integerRegisters[rs2];
        end
    end

    assign rs1Data = rs1Out;
    assign rs2Data = rs2Out;

endmodule
