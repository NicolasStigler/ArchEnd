module condlogic (
  clk,
  reset,
  Cond,
  ALUFlags,
  FlagW,
  PCS,
  NextPC,
  RegW,
  MemW,
  FPUW,
  PCWrite,
  RegWrite,
  MemWrite,
  FPUWrite
);
  input wire clk;
  input wire reset;
  input wire [3:0] Cond;
  input wire [3:0] ALUFlags;
  input wire [1:0] FlagW;
  input wire PCS;
  input wire NextPC;
  input wire RegW;
  input wire MemW;
  input wire FPUW;
  output wire PCWrite;
  output wire RegWrite;
  output wire MemWrite;
  output wire FPUWrite;
  wire [1:0] FlagWrite;
  wire [3:0] Flags;
  wire CondEx;
  wire CondExFl;

  // ADD CODE HERE
  condcheck cc(
    .Cond(Cond),
    .Flags(Flags),
    .CondEx(CondEx)
  );

  flopr #(1) condexreg(
    .clk(clk),
    .reset(reset),
    .d(CondEx),
    .q(CondExFl)
  );

  flopenr #(2) aluflags1reg(
    .clk(clk),
    .reset(reset),
    .en(FlagWrite[1]),
    .d(ALUFlags[3:2]),
    .q(Flags[3:2])
  );

  flopenr #(2) aluflags2reg(
    .clk(clk),
    .reset(reset),
    .en(FlagWrite[0]),
    .d(ALUFlags[1:0]),
    .q(Flags[1:0])
  );

  assign FlagWrite = FlagW & {2 {CondEx}};
  assign PCWrite = NextPC | (PCS & CondExFl);
  assign RegWrite = CondExFl & RegW;
  assign MemWrite = CondExFl & MemW;
  assign FPUWrite = CondExFl & FPUW;
endmodule
