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
  ALUControl,
  LongFlag
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
  input wire LongFlag;
  wire [31:0] PCNext;
  wire [31:0] PC;
  wire [31:0] ExtImm;
  wire [31:0] SrcA;
  wire [31:0] SrcB;
  wire [31:0] Result;
  wire [31:0] Data;
  wire [31:0] RD1;
  wire [31:0] RD2;
  wire [31:0] A;
  wire [31:0] ALUResult;
  wire [31:0] ALUResult2;
  wire [31:0] ALUOut;
  wire [31:0] ALUOut2;
  wire [3:0] RA1;
  wire [3:0] RA2;
  wire [3:0] A3;
  wire [31:0] FPUResult;
  wire FPUOverflow;
  wire [31:0] FPRD1, FPRD2;

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

  fpuregfile fprf(
    .clk(clk),
    .we3(FPUWrite),
    .ra1(RA1),
    .ra2(RA2),
    .a3(A3),
    .wd3(Result),
    .r15(Result),
    .rd1(FPRD1),
    .rd2(FPRD2)
  );

  wire [31:0] pRA1, pRA2;
  assign pRA1 = FPUWrite ? FPRD1 : RD1;
  assign pRA2 = FPUWrite ? FPRD2 : RD2;

  fpu f(
    .a(pRA1),
    .b(pRA2),
    .op(ALUControl[0]),
    .precision(ALUControl[1]),
    .result(FPUResult),
    .overflowFlag(FPUOverflow)
  );

  wire [31:0] MainResult;
  assign MainResult = FPUWrite ? FPUResult : ALUOut;

  regfile rf(
    .clk(clk),
    .we3(RegWrite),
    .ra1(RA1),
    .ra2(RA2),
    .a3(A3),
    .a4(Instr[15:12]),
    .wd3(MainResult),
    .wd4(ALUOut2),
    .r15(MainResult),
    .rd1(RD1),
    .rd2(RD2),
    .Long(LongFlag)
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
    .Long(ALUResult2),
    .ALUFlags(ALUFlags)
  );

  flopr #(32) alureg(
    .clk(clk),
    .reset(reset),
    .d(ALUResult),
    .q(ALUOut)
  );

  flopr #(32) alureg2(
    .clk(clk),
    .reset(reset),
    .d(ALUResult2),
    .q(ALUOut2)
  );

  mux3 #(32) resultmux(
    .d0(ALUOut),
    .d1(Data),
    .d2(ALUResult),
    .s(ResultSrc),
    .y(Result)
  );

  assign Result = MainResult;
  assign PCNext = Result;
endmodule
