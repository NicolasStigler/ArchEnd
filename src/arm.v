module arm (
  clk,
  reset,
  MemWrite,
  Adr,
  WriteData,
  ReadData,
  RegWrite,
  RegDisplay,
  Rd,
  state
);
  input wire clk;
  input wire reset;
  output wire MemWrite;
  output wire [31:0] Adr;
  output wire [31:0] WriteData;
  input wire [31:0] ReadData;
  output wire [31:0] RegDisplay;
  output wire [3:0] Rd;
  output wire [3:0] state;
  output wire RegWrite;
  wire [31:0] Instr;
  wire [3:0] ALUFlags;
  wire PCWrite;
  wire IRWrite;
  wire AdrSrc;
  wire [1:0] RegSrc;
  wire [1:0] ALUSrcA;
  wire [1:0] ALUSrcB;
  wire [1:0] ImmSrc;
  wire [3:0] ALUControl;
  wire [1:0] ResultSrc;
  wire isMul;
  wire longFlag;
  controller c(
    .clk(clk),
    .reset(reset),
    .Instr(Instr[31:4]),
    .ALUFlags(ALUFlags),
    .PCWrite(PCWrite),
    .MemWrite(MemWrite),
    .RegWrite(RegWrite),
    .IRWrite(IRWrite),
    .AdrSrc(AdrSrc),
    .RegSrc(RegSrc),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .ResultSrc(ResultSrc),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl),
    .isMul(isMul),
    .longFlag(longFlag),
    .state(state),
    .Rd(Rd)
  );
  datapath dp(
    .clk(clk),
    .reset(reset),
    .Adr(Adr),
    .WriteData(WriteData),
    .ReadData(ReadData),
    .Instr(Instr),
    .ALUFlags(ALUFlags),
    .PCWrite(PCWrite),
    .RegWrite(RegWrite),
    .IRWrite(IRWrite),
    .AdrSrc(AdrSrc),
    .RegSrc(RegSrc),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .ResultSrc(ResultSrc),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl),
    .isMul(isMul),
    .longFlag(longFlag),
    .Rd(Rd)
  );
  assign RegDisplay = dp.rf.rf[4'b1011];
endmodule
