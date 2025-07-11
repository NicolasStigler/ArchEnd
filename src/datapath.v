module datapath (
  clk,
  reset,
  Adr,
  WriteData,
  ReadData,
  Instr,
  ALUFlags,
  PCWrite,
  RegWrite,
  IRWrite,
  FPUWrite,
  AdrSrc,
  RegSrc,
  ALUSrcA,
  ALUSrcB,
  ResultSrc,
  ImmSrc,
  ALUControl
);
  input wire clk;
  input wire reset;
  output wire [31:0] Adr;
  output wire [31:0] WriteData;
  input wire [31:0] ReadData;
  output wire [31:0] Instr;
  output wire [3:0] ALUFlags;
  input wire PCWrite;
  input wire RegWrite;
  input wire IRWrite;
  input wire FPUWrite;
  input wire AdrSrc;
  input wire [1:0] RegSrc;
  input wire [1:0] ALUSrcA;
  input wire [1:0] ALUSrcB;
  input wire [1:0] ResultSrc;
  input wire [1:0] ImmSrc;
  input wire [2:0] ALUControl;
  wire [31:0] PCNext;
  wire [31:0] PC;
  wire [31:0] ExtImm;
  wire [31:0] SrcA;
  wire [31:0] SrcB;
  wire [31:0] Result;
  wire [31:0] FPUResult;
  wire FPUOp;
  wire FPUPrec;
  wire [31:0] Data;
  wire [31:0] RD1;
  wire [31:0] RD2;
  wire [31:0] A;
  wire [31:0] ALUResult;
  wire [31:0] ALUOut;
  wire [3:0] RA1;
  wire [3:0] RA2;
  wire [3:0] A3;

  // Datapath Hardware Submodules
  flopenr #(32) pcreg(
    .clk(clk),
    .reset(reset),
    .en(PCWrite),
    .d(PCNext),
    .q(PC)
  );

  mux2 #(32) adrmux(
    .d0(PC),
    .d1(PCNext),
    .s(AdrSrc),
    .y(Adr)
  );

  flopenr #(32) instrreg(
    .clk(clk),
    .reset(reset),
    .en(IRWrite),
    .d(ReadData),
    .q(Instr)
  );

  flopr #(32) datareg(
    .clk(clk),
    .reset(reset),
    .d(ReadData),
    .q(Data)
  );

  wire [3:0] mRA1;
  assign mRA1 = (Instr[7:4] == 4'b1001) ? Instr[3:0] : Instr[19:16];

  mux2 #(4) ra1mux(
    .d0(mRA1),
    .d1(4'd15),
    .s(RegSrc[0]),
    .y(RA1)
  );

  wire [3:0] mRA2;
  assign mRA2 = (Instr[7:4] == 4'b1001) ? Instr[11:8] : Instr[3:0];

  mux2 #(4) ra2mux(
    .d0(mRA2),
    .d1(Instr[15:12]),
    .s(RegSrc[1]),
    .y(RA2)
  );

  assign A3 = (Instr[7:4] == 4'b1001) ? Instr[19:16] : Instr[15:12];

  extend e(
    .Instr(Instr[23:0]),
    .ImmSrc(ImmSrc),
    .ExtImm(ExtImm)
  );

  regfile rf(
    .clk(clk),
    .we3(RegWrite),
    .ra1(RA1),
    .ra2(RA2),
    .a3(A3),
    .wd3(Result),
    .r15(Result),
    .rd1(RD1),
    .rd2(RD2)
  );

  // FPU instance
  fpu fpu_inst(
    .a(RD1),
    .b(RD2),
    .op(FPUOp),
    .prec(FPUPrec),
    .result(FPUResult)
  );

  flopr #(64) rdreg(
    .clk(clk),
    .reset(reset),
    .d({RD1, RD2}),
    .q({A, WriteData})
  );

  mux2 #(32) srcamux(
    .d0(A),
    .d1(PC),
    .s(ALUSrcA[0]),
    .y(SrcA)
  );

  mux3 #(32) srcbmux(
    .d0(WriteData),
    .d1(ExtImm),
    .d2(32'd4),
    .s(ALUSrcB),
    .y(SrcB)
  );

  alu a(
    .a(SrcA),
    .b(SrcB),
    .ALUControl(ALUControl),
    .Result(ALUResult),
    .ALUFlags(ALUFlags)
  );

  flopr #(32) alureg(
    .clk(clk),
    .reset(reset),
    .d(ALUResult),
    .q(ALUOut)
  );

  // ResultSrc: 0=ALUOut, 1=Data, 2=ALUResult, 3=FPUResult
  wire [1:0] ResultSrcExt;
  assign ResultSrcExt = ResultSrc;
  mux4 #(32) resultmux(
    .d0(ALUOut),
    .d1(Data),
    .d2(ALUResult),
    .d3(FPUResult),
    .s(ResultSrcExt),
    .y(Result)
  );

  assign FPUOp = Instr[20]; // 0=add, 1=mul
  assign FPUPrec = Instr[22]; // 0=half, 1=single

  assign PCNext = Result;
endmodule
