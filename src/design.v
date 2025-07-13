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

  // Delay writing flags until ALUWB state
  flopr #(2) flagwritereg(
    clk,
    reset,
    FlagW & {2 {CondEx}},
    FlagWrite
  );

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

  assign PCWrite = NextPC | (PCS & CondExFl);
  assign RegWrite = CondExFl & RegW;
  assign MemWrite = CondExFl & MemW;
endmodule

module arm (
  clk,
  reset,
  MemWrite,
  Adr,
  WriteData,
  ReadData
);
  input wire clk;
  input wire reset;
  output wire MemWrite;
  output wire [31:0] Adr;
  output wire [31:0] WriteData;
  input wire [31:0] ReadData;
  wire [31:0] Instr;
  wire [3:0] ALUFlags;
  wire PCWrite;
  wire RegWrite;
  wire IRWrite;
  wire FPUWrite;
  wire AdrSrc;
  wire [1:0] RegSrc;
  wire [1:0] ALUSrcA;
  wire [1:0] ALUSrcB;
  wire [1:0] ImmSrc;
  wire [3:0] ALUControl;
  wire [1:0] ResultSrc;
  controller c(
    .clk(clk),
    .reset(reset),
    .Instr(Instr[31:4]),
    .ALUFlags(ALUFlags),
    .PCWrite(PCWrite),
    .MemWrite(MemWrite),
    .RegWrite(RegWrite),
    .IRWrite(IRWrite),
    .FPUWrite(FPUWrite),
    .AdrSrc(AdrSrc),
    .RegSrc(RegSrc),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .ResultSrc(ResultSrc),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl)
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
    .FPUWrite(FPUWrite),
    .AdrSrc(AdrSrc),
    .RegSrc(RegSrc),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .ResultSrc(ResultSrc),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl)
  );
endmodule

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
  input wire [3:0] ALUControl;
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

  mux3 #(32) resultmux(
    .d0(ALUOut),
    .d1(Data),
    .d2(ALUResult),
    .s(ResultSrc),
    .y(Result)
  );

  assign PCNext = Result;
endmodule

module alu (
  input [31:0] a, b,
  input [2:0] ALUControl,
  output reg [31:0] Result, Long,
  output wire [3:0] ALUFlags
);

wire neg, zero, carry, overflow;
wire [31:0] condinvb;
wire [32:0] sum; // suma 33 bits, carry bit 33

assign condinvb = ALUControl[0] ? ~b : b; // mux
assign sum = a + condinvb + ALUControl[0]; // a + b + cin

always @(*) begin
  casex (ALUControl)
    3'b00?: Result = sum; // 0: ADD | 1: SUB
    3'b010: Result = a & b; // AND
    3'b011: Result = a | b; // ORR
    3'b100: Result = a * b; // MUL
    3'b101: { Long, Result } = $signed(a) * $signed(b); // SMUL
    3'b110: { Long, Result } = $unsigned(a) * $unsigned(b); // UMUL
    3'b111: Result = a / b; // DIV
  endcase
end

assign neg = Result[31];
assign zero = (Result == 32'b0);
assign carry = (ALUControl[1] == 1'b0) & sum[32];
assign overflow = (ALUControl[1] == 1'b0) & ~(a[31] ^ b[31] ^ ALUControl[0]) & (a[31] ^ sum[31]);
assign ALUFlags = {neg, zero, carry, overflow};

endmodule

module controller (
  clk,
  reset,
  Instr,
  ALUFlags,
  PCWrite,
  MemWrite,
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
  input wire [31:4] Instr;
  input wire [3:0] ALUFlags;
  output wire PCWrite;
  output wire MemWrite;
  output wire RegWrite;
  output wire IRWrite;
  output wire FPUWrite;
  output wire AdrSrc;
  output wire [1:0] RegSrc;
  output wire [1:0] ALUSrcA;
  output wire [1:0] ALUSrcB;
  output wire [1:0] ResultSrc;
  output wire [1:0] ImmSrc;
  output wire [2:0] ALUControl;
  wire [1:0] FlagW;
  wire PCS;
  wire NextPC;
  wire RegW;
  wire MemW;
  wire FPUW;
  decode dec(
    .clk(clk),
    .reset(reset),
    .Op(Instr[27:26]),
    .Funct(Instr[25:20]),
    .Rd(Instr[15:12]),
    .Mul(Instr[7:4]),
    .FlagW(FlagW),
    .PCS(PCS),
    .NextPC(NextPC),
    .RegW(RegW),
    .MemW(MemW),
    .FPUW(FPUW),
    .IRWrite(IRWrite),
    .AdrSrc(AdrSrc),
    .ResultSrc(ResultSrc),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .ImmSrc(ImmSrc),
    .RegSrc(RegSrc),
    .ALUControl(ALUControl)
  );
  condlogic cl(
    .clk(clk),
    .reset(reset),
    .Cond(Instr[31:28]),
    .ALUFlags(ALUFlags),
    .FlagW(FlagW),
    .PCS(PCS),
    .NextPC(NextPC),
    .RegW(RegW),
    .MemW(MemW),
    .FPUW(FPUW),
    .PCWrite(PCWrite),
    .RegWrite(RegWrite),
    .MemWrite(MemWrite),
    .FPUWrite(FPUWrite)
  );
endmodule

module condcheck (
  Cond,
  Flags,
  CondEx
);
  input wire [3:0] Cond;
  input wire [3:0] Flags;
  output reg CondEx;

  always @(*)
    case (Cond)
      4'b0000: CondEx = Flags[2]; // EQ
      4'b0001: CondEx = ~Flags[2]; // NE
      4'b0010: CondEx = Flags[1]; // CS
      4'b0011: CondEx = ~Flags[1]; // CC
      4'b0100: CondEx = Flags[3]; // MI
      4'b0101: CondEx = ~Flags[3]; // PL
      4'b0110: CondEx = Flags[0]; // VS
      4'b0111: CondEx = ~Flags[0]; // VC
      4'b1000: CondEx = (Flags[1] & ~Flags[2]); // HI
      4'b1001: CondEx = (~Flags[1] | Flags[2]); // LS
      4'b1010: CondEx = (Flags[3] == Flags[0]); // GE
      4'b1011: CondEx = (Flags[3] != Flags[0]); // LT
      4'b1100: CondEx = (~Flags[2] & (Flags[3] == Flags[0])); // GT
      4'b1101: CondEx = (Flags[2] | (Flags[3] != Flags[0])); // LE
      4'b1110: CondEx = 1'b1; // AL
      default: CondEx = 1'bx;
    endcase
endmodule

module flopr (
  clk,
  reset,
  d,
  q
);
  parameter WIDTH = 8;
  input wire clk;
  input wire reset;
  input wire [WIDTH - 1:0] d;
  output reg [WIDTH - 1:0] q;
  always @(posedge clk or posedge reset)
    if (reset)
      q <= 0;
    else
      q <= d;
endmodule

module decode (
  clk,
  reset,
  Op,
  Funct,
  Rd,
  Mul,
  FlagW,
  PCS,
  NextPC,
  RegW,
  MemW,
  FPUW,
  IRWrite,
  AdrSrc,
  ResultSrc,
  ALUSrcA,
  ALUSrcB,
  ImmSrc,
  RegSrc,
  ALUControl
);
  input wire clk;
  input wire reset;
  input wire [1:0] Op;
  input wire [5:0] Funct;
  input wire [3:0] Rd;
  input wire [3:0] Mul;
  output reg [1:0] FlagW;
  output wire PCS;
  output wire NextPC;
  output wire RegW;
  output wire MemW;
  output wire FPUW;
  output wire IRWrite;
  output wire AdrSrc;
  output wire [1:0] ResultSrc;
  output wire [1:0] ALUSrcA;
  output wire [1:0] ALUSrcB;
  output wire [1:0] ImmSrc;
  output wire [1:0] RegSrc;
  output reg [2:0] ALUControl;
  wire Branch;
  wire ALUOp;

  // Main FSM
  mainfsm fsm(
    .clk(clk),
    .reset(reset),
    .Op(Op),
    .Funct(Funct),
    .IRWrite(IRWrite),
    .AdrSrc(AdrSrc),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .ResultSrc(ResultSrc),
    .NextPC(NextPC),
    .RegW(RegW),
    .MemW(MemW),
    .FPUW(FPUW),
    .Branch(Branch),
    .ALUOp(ALUOp)
  );

  // ALU Decoder
  always @(*) begin
    if (ALUOp) begin
      if (Mul == 4'b1001) // Instr[7:4] = Multiply Indicator
        case (Funct[4:1])
          4'b0000: ALUControl = 3'b100; // MUL
          4'b0100: ALUControl = 3'b101; // SMUL
          4'b0110: ALUControl = 3'b110; // UMUL
          4'b1000: ALUControl = 3'b111; // DIV
          default: ALUControl = 3'bxxx;
        endcase
      else
        case (Funct[4:1])
          4'b0100: ALUControl = 3'b000; // ADD
          4'b0010: ALUControl = 3'b001; // SUB
          4'b0000: ALUControl = 3'b010; // AND
          4'b1100: ALUControl = 3'b011; // ORR
          default: ALUControl = 3'bxxx;
        endcase
      FlagW[1] = Funct[0];
      FlagW[0] = Funct[0] & (ALUControl == 3'b00?);
    end else begin
      ALUControl = 3'b000;
      FlagW = 2'b00;
    end
  end

  // PC Logic
  assign PCS = ((Rd == 4'b1111) & RegW) | Branch;

  // Instr Decoder
  assign ImmSrc = Op;
  assign RegSrc[1] = Op == 2'b01;
  assign RegSrc[0] = Op == 2'b10;
endmodule

module extend (
  Instr,
  ImmSrc,
  ExtImm
);
  input wire [23:0] Instr;
  input wire [1:0] ImmSrc;
  output reg [31:0] ExtImm;
  always @(*)
    case (ImmSrc)
      2'b00: ExtImm = {24'b0, Instr[7:0]}; // Zero extend 8 LSB of Instr
      2'b01: ExtImm = {20'b0, Instr[11:0]}; // Zero extend 12 LSB of Instr
      2'b10: ExtImm = {{6 {Instr[23]}}, Instr[23:0], 2'b0}; // Sign extend Instr
      default: ExtImm = 32'bx;
    endcase
endmodule
module flopenr (
  clk,
  reset,
  en,
  d,
  q
);
  parameter WIDTH = 8;
  input wire clk;
  input wire reset;
  input wire en;
  input wire [WIDTH - 1:0] d;
  output reg [WIDTH - 1:0] q;
  always @(posedge clk or posedge reset)
    if (reset)
      q <= 0;
    else if (en)
      q <= d;
endmodule

module mainfsm (
  clk,
  reset,
  Op,
  Funct,
  IRWrite,
  AdrSrc,
  ALUSrcA,
  ALUSrcB,
  ResultSrc,
  NextPC,
  RegW,
  MemW,
  FPUW,
  Branch,
  ALUOp
);
  input wire clk;
  input wire reset;
  input wire [1:0] Op;
  input wire [5:0] Funct;
  output wire IRWrite;
  output wire AdrSrc;
  output wire [1:0] ALUSrcA;
  output wire [1:0] ALUSrcB;
  output wire [1:0] ResultSrc;
  output wire NextPC;
  output wire RegW;
  output wire MemW;
  output wire FPUW;
  output wire Branch;
  output wire ALUOp;
  reg [3:0] state;
  reg [3:0] nextstate;
  reg [12:0] controls;
  localparam [3:0] FETCH = 0;
  localparam [3:0] DECODE = 1;
  localparam [3:0] MEMADR = 2;
  localparam [3:0] MEMRD = 3;
  localparam [3:0] MEMWB = 4;
  localparam [3:0] MEMWR = 5;
  localparam [3:0] EXECUTER = 6;
  localparam [3:0] EXECUTEI = 7;
  localparam [3:0] ALUWB = 8;
  localparam [3:0] BRANCH = 9;
  localparam [3:0] UNKNOWN = 10;

  // state register
  always @(posedge clk or posedge reset)
    if (reset)
      state <= FETCH;
    else
      state <= nextstate;

  // next state logic
  always @(*)
    casex (state)
      FETCH: nextstate = DECODE;
      DECODE:
        case (Op)
          2'b00:
            if (Funct[5])
              nextstate = EXECUTEI;
            else
              nextstate = EXECUTER;
          2'b01: nextstate = MEMADR;
          2'b10: nextstate = BRANCH;
          default: nextstate = UNKNOWN;
        endcase
      EXECUTER: nextstate = ALUWB;
      EXECUTEI: nextstate = ALUWB;
      MEMADR:
        if (Funct[0])
          nextstate = MEMRD;
        else
          nextstate = MEMWR;
      MEMRD: nextstate = MEMWB;
      MEMWB: nextstate = FETCH;
      MEMWR: nextstate = FETCH;
      ALUWB: nextstate = FETCH;
      BRANCH: nextstate = FETCH;
      default: nextstate = FETCH;
    endcase

  // state-dependent output logic
  always @(*)
    case (state)
      FETCH: controls = 13'b1000101001100;
      DECODE: controls = 13'b0000001001100;
      EXECUTER: controls = 13'b0000000000001;
      EXECUTEI: controls = 13'b0000000000011;
      ALUWB: controls = 13'b0001000000000;
      MEMADR: controls = 13'b0000000000010;
      MEMWR: controls = 13'b0010010000000;
      MEMRD: controls = 13'b0000010000000;
      MEMWB: controls = 13'b0001000100000;
      BRANCH: controls = 13'b0100001000010;
      default: controls = 13'bx;
    endcase
  assign {NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp} = controls;
endmodule

module mem (
  clk,
  we,
  a,
  wd,
  rd
);
  input wire clk;
  input wire we;
  input wire [31:0] a;
  input wire [31:0] wd;
  output wire [31:0] rd;
  reg [31:0] RAM [63:0];
  initial $readmemh("memfile.mem", RAM);
  assign rd = RAM[a[31:2]]; // word aligned
  always @(posedge clk)
    if (we)
      RAM[a[31:2]] <= wd;
endmodule

module mux2 (
  d0,
  d1,
  s,
  y
);
  parameter WIDTH = 8;
  input wire [WIDTH - 1:0] d0; // 0
  input wire [WIDTH - 1:0] d1; // 1
  input wire s;
  output wire [WIDTH - 1:0] y;
  assign y = (s ? d1 : d0);
endmodule

module mux3 (
  d0,
  d1,
  d2,
  s,
  y
);
  parameter WIDTH = 8;
  input wire [WIDTH - 1:0] d0; // 00
  input wire [WIDTH - 1:0] d1; // 01
  input wire [WIDTH - 1:0] d2; // 10
  input wire [1:0] s;
  output wire [WIDTH - 1:0] y;
  assign y = (s[1] ? d2 : (s[0] ? d1 : d0));
endmodule

module regfile (
  clk,
  we3,
  ra1,
  ra2,
  a3,
  wd3,
  r15,
  rd1,
  rd2
);
  input wire clk;
  input wire we3;
  input wire [3:0] ra1;
  input wire [3:0] ra2;
  input wire [3:0] a3;
  input wire [31:0] wd3;
  input wire [31:0] r15; // PC+8
  output reg [31:0] rd1;
  output reg [31:0] rd2;
  reg [31:0] rf [14:0]; // 15 registers
  always @(posedge clk) begin
    if (we3)
      rf[a3] <= wd3; // write wd3 into the register a3
  end
  always @(*) begin
    // if ra is 15, use r15, else use register in rf
    rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1];
    rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];
  end
endmodule

module top (
  clk,
  reset,
  WriteData,
  Adr,
  MemWrite
);
  input wire clk;
  input wire reset;
  output wire [31:0] WriteData;
  output wire [31:0] Adr;
  output wire MemWrite;
  // wire [31:0] PC;
  // wire [31:0] Instr;
  wire [31:0] ReadData;
  // instantiate processor and shared memory
  arm arm(
    .clk(clk),
    .reset(reset),
    .MemWrite(MemWrite),
    .Adr(Adr),
    .WriteData(WriteData),
    .ReadData(ReadData)
  );
  mem mem(
    .clk(clk),
    .we(MemWrite),
    .a(Adr),
    .wd(WriteData),
    .rd(ReadData)
  );
endmodule
