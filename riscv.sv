module riscv(   input   logic        clk, reset,
                output  logic [31:0] PCF,
                input   logic [31:0] InstrF,
                output  logic        MemReadM, MemWriteM, PCstall,
                output  logic [31:0] ALUResultM, WriteDataM,
                input   logic [31:0] ReadDataM,
                output  logic [31:0] dec
					 );
    logic [6:0] opD;
    logic [2:0] funct3D;
    logic       funct7b5D;
    logic [2:0] ImmSrcD;
    logic       ZeroE;
    logic       PCSrcE;
    logic [2:0] ALUControlE;
    logic       ALUSrcAE, ALUSrcBE;
    logic       ResultSrcEb0;
    logic       RegWriteM;
    logic [1:0] ResultSrcW;
    logic       RegWriteW;

    logic [1:0] ForwardAE, ForwardBE;
    logic       StallF, StallD, FlushD, FlushE;
    logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;

    controller c(clk, reset,
                opD, funct3D, funct7b5D, ImmSrcD,
                FlushE, ZeroE, PCSrcE, ALUControlE, ALUSrcAE, ALUSrcBE,
                ResultSrcEb0, MemReadM, MemWriteM, RegWriteM, RegWriteW, ResultSrcW);

    datapath dp(clk, reset,
                StallF, PCF, InstrF, PCstall,
                opD, funct3D, funct7b5D, StallD, FlushD, ImmSrcD,
                FlushE, ForwardAE, ForwardBE, PCSrcE, ALUControlE,
                ALUSrcAE, ALUSrcBE, ZeroE,
                MemReadM, MemWriteM, WriteDataM, ALUResultM, ReadDataM,
                RegWriteW, ResultSrcW,
                Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW
					 ,dec
					 );
					

    hazard hu(Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
                PCSrcE, ResultSrcEb0, PCstall, RegWriteM, RegWriteW,
                ForwardAE, ForwardBE, StallF, StallD, FlushD, FlushE);
endmodule

module controller(input logic clk, reset,
                // Decode stage control signals
                input logic [6:0] opD,
                input logic [2:0] funct3D,
                input logic funct7b5D,
                output logic [2:0] ImmSrcD,
                // Execute stage control signals
                input logic FlushE,
                input logic ZeroE,
                output logic PCSrcE, // for datapath and Hazard Unit
                output logic [2:0] ALUControlE,
                output logic ALUSrcAE,
                output logic ALUSrcBE, // for lui
                output logic ResultSrcEb0, // for Hazard Unit
                // Memory stage control signals
                output logic MemReadM,
                output logic MemWriteM,
                output logic RegWriteM, // for Hazard Unit
                // Writeback stage control signals
                output logic RegWriteW, // for datapath and Hazard Unit
                output logic [1:0] ResultSrcW);
// pipelined control signals
    logic       RegWriteD, RegWriteE;
    logic [1:0] ResultSrcD, ResultSrcE, ResultSrcM;
    logic       MemReadD, MemReadE;
    logic       MemWriteD, MemWriteE;
    logic       JumpD, JumpE;
    logic       BranchD, BranchE;
    logic [1:0] ALUOpD;
    logic [2:0] ALUControlD;
    logic       ALUSrcAD;
    logic       ALUSrcBD; // for lui
// Decode stage logic
    maindec md( opD, ResultSrcD, MemReadD, MemWriteD, BranchD,
                ALUSrcAD, ALUSrcBD, RegWriteD, JumpD, ImmSrcD, ALUOpD);
    aludec  ad(opD[5], funct3D, funct7b5D, ALUOpD, ALUControlD);

// Execute stage pipeline control register and logic
    floprc #(12) controlregE(clk, reset, FlushE,
                            {RegWriteD, ResultSrcD, MemReadD, MemWriteD, JumpD, BranchD,
                            ALUControlD, ALUSrcAD, ALUSrcBD},
                            {RegWriteE, ResultSrcE, MemReadE, MemWriteE, JumpE, BranchE,
                            ALUControlE, ALUSrcAE, ALUSrcBE});
    assign PCSrcE = (BranchE & ZeroE) | JumpE;
    assign ResultSrcEb0 = ResultSrcE[0];
// Memory stage pipeline control register
    flopr #(5) controlregM(clk, reset,
                        {RegWriteE, ResultSrcE, MemReadE, MemWriteE},
                        {RegWriteM, ResultSrcM, MemReadM, MemWriteM});
// Writeback stage pipeline control register
    flopr #(3) controlregW(clk, reset,
                        {RegWriteM, ResultSrcM},
                        {RegWriteW, ResultSrcW});
endmodule

module maindec( input  logic [6:0] op,
                output logic [1:0] ResultSrc,
                output logic       MemRead,
                output logic       MemWrite,
                output logic       Branch,
                output logic       ALUSrcA, // for lui
                output logic       ALUSrcB,
                output logic       RegWrite, Jump,
                output logic [2:0] ImmSrc,
                output logic [1:0] ALUOp);

        logic [13:0] controls;

        assign {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemRead, MemWrite,
                ResultSrc, Branch, ALUOp, Jump} = controls;
    always_comb
        case(op)
        // RegWrite_ImmSrc_ALUSrcA_ALUSrcB_MemWrite_ResultSrc_Branch_ALUOp_Jump
            7'b0000011: controls = 14'b1_000_0_1_1_0_01_0_00_0; // lw
            7'b0100011: controls = 14'b0_001_0_1_0_1_00_0_00_0; // sw
            7'b0110011: controls = 14'b1_xxx_0_0_0_0_00_0_10_0; // R-type
            7'b1100011: controls = 14'b0_010_0_0_0_0_00_1_01_0; // beq
            7'b0010011: controls = 14'b1_000_0_1_0_0_00_0_10_0; // I-type ALU
            7'b1101111: controls = 14'b1_011_0_0_0_0_10_0_00_1; // jal
            7'b0110111: controls = 14'b1_100_1_1_0_0_00_0_00_0; // lui
            7'b0000000: controls = 14'b0_000_0_0_0_0_00_0_00_0; // need valid values at reset

            default:    controls = 1'bx_xxx_x_x_x_xx_x_xx_x; // non-implemented instruction

        endcase
endmodule

module aludec(  input logic        opb5,
                input logic  [2:0] funct3,
                input logic        funct7b5,
                input logic  [1:0] ALUOp,
                output logic [2:0] ALUControl);

    logic RtypeSub;
    assign RtypeSub = funct7b5 & opb5; // TRUE for R-type subtract instruction
    always_comb
        case(ALUOp)
            2'b00: ALUControl = 3'b000; // addition
            2'b01: ALUControl = 3'b001; // subtraction
            default:case(funct3) // R-type or I-type ALU
                        3'b000: if (RtypeSub)
                                    ALUControl = 3'b001; // sub
                                else
                                    ALUControl = 3'b000; // add, addi
                        3'b010:     ALUControl = 3'b101; // slt, slti
                        3'b100:     ALUControl = 3'b100; // xor
                        3'b110:     ALUControl = 3'b011; // or, ori
                        3'b111:     ALUControl = 3'b010; // and, andi
                        default:    ALUControl = 3'bxxx; // ???
                    endcase
        endcase 
endmodule

module datapath(input logic clk, reset,
                // Fetch stage signals
                input   logic        StallF,
                output  logic [31:0] PCF,
                input   logic [31:0] InstrF_i,
                output  logic        PCstall,
                // Decode stage signals
                output  logic [6:0] opD,
                output  logic [2:0] funct3D,
                output  logic       funct7b5D,
                input   logic       StallD, FlushD,
                input   logic [2:0] ImmSrcD,
                // Execute stage signals
                input   logic       FlushE,
                input   logic [1:0] ForwardAE, ForwardBE,
                input   logic       PCSrcE,
                input   logic [2:0] ALUControlE,
                input   logic       ALUSrcAE, // needed for lui
                input   logic       ALUSrcBE,
                output  logic       ZeroE,
                // Memory stage signals
                input   logic       MemReadM,
                input   logic       MemWriteM,
                output  logic [31:0]WriteDataM, ALUResultM,
                input   logic [31:0]ReadDataM,
                // Writeback stage signals
                input   logic       RegWriteW,
                input   logic [1:0] ResultSrcW,
                // Hazard Unit signals
                output  logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E,
                output  logic [4:0] RdE, RdM, RdW,
					 
				output  logic [31:0] dec);

    // Fetch stage signals
        logic [31:0] PCNextF, PCPlus4F, InstrF_o;
    // Decode stage signals
        logic [31:0] InstrD_in, InstrD;
        logic [31:0] PCD, PCPlus4D;
        logic [31:0] RD1D, RD2D;
        logic [31:0] ImmExtD;
        logic [4:0]  RdD;
    // Execute stage signals
        logic [31:0] RD1E, RD2E;
        logic [31:0] PCE, ImmExtE;
        logic [31:0] SrcAE, SrcBE;
        logic [31:0] SrcAEforward;
        logic [31:0] ALUResultE;
        logic [31:0] WriteDataE;
        logic [31:0] PCPlus4E;
        logic [31:0] PCTargetE;
    // Memory stage signals
        logic [31:0] PCPlus4M;
    // Writeback stage signals
        logic [31:0] ALUResultW;
        logic [31:0] ReadDataW;
        logic [31:0] PCPlus4W;
        logic [31:0] ResultW;
    // Fetch stage pipeline register and logic
        mux2    #(32) pcmux(PCPlus4F, PCTargetE, PCSrcE, PCNextF);
        flopenr #(32) pcreg(clk, reset, ~StallF, PCNextF, PCF);
        instr_realign realign(clk, reset, FlushD, InstrF_i, InstrF_o, PCstall);
        adder         pcadd(PCF, 32'h4, PCPlus4F);
    // Decode stage pipeline register and logic
        flopenrc #(96) regD(clk, reset, FlushD, ~StallD,
                            {InstrF_o, PCF, PCPlus4F},
                            {InstrD_in, PCD, PCPlus4D});
		  
					assign dec = InstrD;

		decompress     decom(InstrD_in, InstrD);
        assign opD       = InstrD[6:0];
        assign funct3D   = InstrD[14:12];
        assign funct7b5D = InstrD[30];
        assign Rs1D      = InstrD[19:15];
        assign Rs2D      = InstrD[24:20];
        assign RdD       = InstrD[11:7];

        regfile rf(clk, reset, RegWriteW, Rs1D, Rs2D, RdW, ResultW, RD1D, RD2D);
        extend ext(InstrD[31:7], ImmSrcD, ImmExtD);

    // Execute stage pipeline register and logic
        floprc #(175) regE(clk, reset, FlushE,
                            {RD1D, RD2D, PCD, Rs1D, Rs2D, RdD, ImmExtD, PCPlus4D},
                            {RD1E, RD2E, PCE, Rs1E, Rs2E, RdE, ImmExtE, PCPlus4E});
        mux3 #(32) faemux(RD1E, ResultW, ALUResultM, ForwardAE, SrcAEforward);
        mux2 #(32) srcamux(SrcAEforward, 32'b0, ALUSrcAE, SrcAE); // for lui
        mux3 #(32) fbemux(RD2E, ResultW, ALUResultM, ForwardBE, WriteDataE);
        mux2 #(32) srcbmux(WriteDataE, ImmExtE, ALUSrcBE, SrcBE);
        alu        alu(SrcAE, SrcBE, ALUControlE, ALUResultE, ZeroE);
        adder      branchadd(ImmExtE, PCE, PCTargetE);
    // Memory stage pipeline register
        flopr #(101) regM(clk, reset,
                        {ALUResultE, WriteDataE, RdE, PCPlus4E},
                        {ALUResultM, WriteDataM, RdM, PCPlus4M});
    // Writeback stage pipeline register and logic
        flopr #(101) regW(clk, reset,
                        {ALUResultM, ReadDataM, RdM, PCPlus4M},
                        {ALUResultW, ReadDataW, RdW, PCPlus4W});
        mux3 #(32) resultmux(ALUResultW, ReadDataW, PCPlus4W, ResultSrcW,
        ResultW);
endmodule

// Hazard Unit: forward, stall, and flush
module hazard(input logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
            input logic PCSrcE, ResultSrcEb0,
            input logic PCstall,
            input logic RegWriteM, RegWriteW,
            output logic [1:0] ForwardAE, ForwardBE,
            output logic StallF, StallD, FlushD, FlushE);
    logic lwStallD;
    // forwarding logic
    always_comb begin
        ForwardAE = 2'b00;
        ForwardBE = 2'b00;
        if (Rs1E != 5'b0)
            if ((Rs1E == RdM) & RegWriteM) ForwardAE = 2'b10;
            else if ((Rs1E == RdW) & RegWriteW) ForwardAE = 2'b01;

        if (Rs2E != 5'b0)
            if ((Rs2E == RdM) & RegWriteM) ForwardBE = 2'b10;
            else if ((Rs2E == RdW) & RegWriteW) ForwardBE = 2'b01;
    end
    // stalls and flushes
    assign lwStallD = ResultSrcEb0 & ((Rs1D == RdE) | (Rs2D == RdE)) ;
    assign StallF = lwStallD | PCstall;
    assign StallD = lwStallD;
    assign FlushD = PCSrcE;
    assign FlushE = lwStallD | PCSrcE;
endmodule

// module regfile(input logic clk,
//             input logic we3,
//             input logic [ 4:0] a1, a2, a3,
//             input logic [31:0] wd3,
//             output logic [31:0] rd1, rd2);
//             logic [31:0] rf[31:0];
// // three ported register file
// // read two ports combinationally (A1/RD1, A2/RD2)
// // write third port on rising edge of clock (A3/WD3/WE3)
// // write occurs on falling edge of clock
// // register 0 hardwired to 0
// always_ff @(negedge clk)
//     if (we3) rf[a3] <= wd3;
//         assign rd1 = (a1 != 0) ? rf[a1] : 0;
//         assign rd2 = (a2 != 0) ? rf[a2] : 0;
// endmodule

module regfile (
    input logic clk,
    input logic reset,
    input logic we3,
    input logic [4:0] a1, a2, a3,
    input logic [31:0] wd3,
    output logic [31:0] rd1, rd2
);
    logic [31:0] rf[31:0];
    integer i;

    // three ported register file
    // read two ports combinationally (A1/RD1, A2/RD2)
    // write third port on rising edge of clock (A3/WD3/WE3)
    // write occurs on falling edge of clock
    // register 0 hardwired to 0

    // Initialize registers during reset
    always_ff @(negedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                rf[i] <= 32'd0;
            end
        end else
            // Write operation on rising edge of clock
            if (we3) rf[a3] <= wd3;
    end
        
        // Read operations
        assign rd1 = (a1 != 0) ? rf[a1] : 0;
        assign rd2 = (a2 != 0) ? rf[a2] : 0;
    
endmodule


module adder(input [31:0] a, b,
        output [31:0] y);
        assign y = a + b;
endmodule

module extend(input logic [31:7] instr,
            input logic [2:0] immsrc, // extended to 3 bits for lui
            output logic [31:0] immext);
    always_comb
        case(immsrc)
        // I-type
        3'b000: immext = {{20{instr[31]}}, instr[31:20]};
        // S-type (stores)
        3'b001: immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        // B-type (branches)
        3'b010: immext = {{20{instr[31]}}, instr[7], instr[30:25],
        instr[11:8], 1'b0};
        // J-type (jal)
        3'b011: immext = {{12{instr[31]}}, instr[19:12], instr[20],
        instr[30:21], 1'b0};
        // U-type (lui, auipc)
        3'b100: immext = {instr[31:12], 12'b0};
        default: immext = 32'bx; // undefined
        endcase
endmodule

module flopr #(parameter WIDTH = 8)
    (input logic clk, reset,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q);
    always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else q <= d;
endmodule

module flopenr #(parameter WIDTH = 8)
    (input logic clk, reset, en,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q);
    always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else if (en) q <= d;
endmodule

module flopenrc #(parameter WIDTH = 8)
    (input logic clk, reset, clear, en,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q);
    always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else if (en)
    if (clear) q <= 0;
    else q <= d;
endmodule

module floprc #(parameter WIDTH = 8)
    (input logic clk,
    input logic reset,
    input logic clear,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q);
    always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else
    if (clear) q <= 0;
    else q <= d;
endmodule

module mux2 #(parameter WIDTH = 8)
    (input logic [WIDTH-1:0] d0, d1,
    input logic s,
    output logic [WIDTH-1:0] y);
    assign y = s ? d1 : d0;
endmodule

module mux3 #(parameter WIDTH = 8)
    (input logic [WIDTH-1:0] d0, d1, d2,
    input logic [1:0] s,
    output logic [WIDTH-1:0] y);
    assign y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule

module imem(input logic [31:0] a,
    output logic [31:0] rd);
    logic [31:0] RAM[63:0];
    initial
    $readmemh("C:/Users/Dell/dan/intelFPGA_lite/18.1/2023-march/da/example.txt",RAM);
    assign rd = RAM[a[31:2]]; // word aligned
endmodule


module alu(input logic [31:0] a, b,
            input logic [2:0] alucontrol,
            output logic [31:0] result,
            output logic zero);
        logic [31:0]    condinvb, sum;
        logic           v; // overflow
        logic           isAddSub; // true when is add or subtract operation

        assign condinvb = alucontrol[0] ? ~b : b;
        assign sum = a + condinvb + alucontrol[0];
        assign isAddSub = ~alucontrol[2] & ~alucontrol[1] |
                        ~alucontrol[1] & alucontrol[0];
        always_comb
            case (alucontrol)
                3'b000: result = sum; // add
                3'b001: result = sum; // subtract
                3'b010: result = a & b; // and
                3'b011: result = a | b; // or
                3'b100: result = a ^ b; // xor
                3'b101: result = sum[31] ^ v; // slt
                default: result = 32'bx;
            endcase
        assign zero = (result == 32'b0);
        assign v = ~(alucontrol[0] ^ a[31] ^ b[31]) & (a[31] ^ sum[31]) & isAddSub;
endmodule
