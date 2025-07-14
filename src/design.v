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

module HexTo7Segment (
  input [3:0] digit,
  output reg [7:0] catode
);
  always @(*)
    case (digit)
      4'h0: catode = 8'b00000011; // 0
      4'h1: catode = 8'b10011111; // 1
      4'h2: catode = 8'b00100101; // 2
      4'h3: catode = 8'b00001101; // 3
      4'h4: catode = 8'b10011001; // 4
      4'h5: catode = 8'b01001001; // 5
      4'h6: catode = 8'b01000001; // 6
      4'h7: catode = 8'b00011111; // 7
      4'h8: catode = 8'b00000001; // 8
      4'h9: catode = 8'b00001001; // 9
      4'hA: catode = 8'b00010001; // A
      4'hB: catode = 8'b11000001; // B
      4'hC: catode = 8'b01100011; // C
      4'hD: catode = 8'b10000101; // D
      4'hE: catode = 8'b01100001; // E
      4'hF: catode = 8'b01110001; // F
      default: catode = 8'b11111111; // off
    endcase
endmodule
module hex_display(
  input clk, 
  input reset, 
  input [15:0] data,
  output wire [3:0] anode,
  output wire [7:0] catode
);
  wire scl_clk;
  wire [3:0] digit;
  CLKdivider sc(
    .clk(clk),
    .reset(reset),
    .t(scl_clk)
  );
  hFSM m(
    .clk(scl_clk),
    .reset(reset),
    .data(data),
    .digit(digit),
    .anode(anode)
  );
  HexTo7Segment decoder (
    .digit(digit),
    .catode(catode)
  );
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

module alu (
  input [31:0] a, b,
  input [3:0] ALUControl,
  output reg [31:0] Result, Long,
  output wire [3:0] ALUFlags
);

wire neg, zero, carry, overflow;
wire [31:0] condinvb;
wire [32:0] sum; // suma 33 bits, carry bit 33

assign condinvb = ALUControl[0] ? ~b : b; // mux
assign sum = a + condinvb + ALUControl[0]; // a + b + cin

wire [15:0] add16_result;
wire [15:0] mul16_result;
wire [31:0] add32_result;
wire [31:0] mul32_result;

Add16 fpu_add16 (
  .a(a[15:0]),
  .b(b[15:0]),
  .result(add16_result)
);

Mul16 fpu_mul16 (
  .a(a[15:0]),
  .b(b[15:0]),
  .result(mul16_result)
);

Add32 fpu_add32 (
  .a(a),
  .b(b),
  .result(add32_result)
);

Mul32 fpu_mul32 (
  .a(a),
  .b(b),
  .result(mul32_result)
);

always @(*) begin
  Long = 32'b0;
  casex (ALUControl)
    4'b000?: Result = sum; // 0: ADD | 1: SUB
    4'b0010: Result = a & b; // AND
    4'b0011: Result = a | b; // ORR
    4'b0100: Result = a * b; // MUL
    4'b0101: { Long, Result } = $signed(a) * $signed(b); // SMUL
    4'b0110: { Long, Result } = $unsigned(a) * $unsigned(b); // UMUL
    4'b0111: Result = a / b; // DIV
    4'b1000: Result = a ^ b; // EOR
    4'b1001: Result = b; // MOV
    4'b1010: Result = a << b; // LSL
    4'b1011: Result = {16'b0, add16_result}; // Add16 (FP)
    4'b1100: Result = {16'b0, mul16_result}; // Mul16 (FP)
    4'b1101: Result = add32_result; // Add32 (FP)
    4'b1110: Result = mul32_result; // Mul32 (FP)
  endcase
end

wire longFlag = (ALUControl == 4'b0101) | (ALUControl == 4'b0110);

assign neg = ((Result[31] == 1'b1) & ~longFlag) | ((Long[31] == 1'b1) & longFlag);
assign zero = longFlag ? ((Long == 32'b0) & (Result == 32'b0)) : (Result == 32'b0);
assign carry = (ALUControl[1] == 1'b0) & sum[32];
assign overflow = (ALUControl[1] == 1'b0) & ~(a[31] ^ b[31] ^ ALUControl[0]) & (a[31] ^ sum[31]);
assign ALUFlags = {neg, zero, carry, overflow};

endmodule

module regfile (
  clk,
  we3,
  we4,
  ra1,
  ra2,
  a3,
  a4,
  wd3,
  r15,
  rd1,
  rd2
);
  input wire clk;
  input wire we3;
  input wire we4;
  input wire [3:0] ra1;
  input wire [3:0] ra2;
  input wire [3:0] a3;
  input wire [3:0] a4;
  input wire [31:0] wd3;
  input wire [31:0] r15; // PC+8
  output wire [31:0] rd1;
  output wire [31:0] rd2;
  reg [31:0] rf [14:0]; // 15 registers
  always @(posedge clk) begin
    if (we3)
      rf[a3] <= wd3; // write wd3 into the register a3
    if (we4)
      rf[a4] <= wd3; // write wd3 into the register a4
  end

  // if ra is 15, use r15, else use register in rf
  assign rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1];
  assign rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];
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
  AdrSrc,
  RegSrc,
  ALUSrcA,
  ALUSrcB,
  ResultSrc,
  ImmSrc,
  ALUControl,
  isMul,
  longFlag,
  state,
  Rd
);
  input wire clk;
  input wire reset;
  input wire [31:4] Instr;
  input wire [3:0] ALUFlags;
  output wire PCWrite;
  output wire MemWrite;
  output wire RegWrite;
  output wire IRWrite;
  output wire AdrSrc;
  output wire [1:0] RegSrc;
  output wire [1:0] ALUSrcA;
  output wire [1:0] ALUSrcB;
  output wire [1:0] ResultSrc;
  output wire [1:0] ImmSrc;
  output wire [3:0] ALUControl;
  output wire isMul;
  output wire longFlag;
  output wire [3:0] state;
  input wire [3:0] Rd;
  wire [1:0] FlagW;
  wire PCS;
  wire NextPC;
  wire RegW;
  wire MemW;
  decode dec(
    .clk(clk),
    .reset(reset),
    .Op(Instr[27:26]),
    .Funct(Instr[25:20]),
    .Rd(Rd),
    .Mul(Instr[7:4]),
    .FlagW(FlagW),
    .PCS(PCS),
    .NextPC(NextPC),
    .RegW(RegW),
    .MemW(MemW),
    .IRWrite(IRWrite),
    .AdrSrc(AdrSrc),
    .ResultSrc(ResultSrc),
    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .ImmSrc(ImmSrc),
    .RegSrc(RegSrc),
    .ALUControl(ALUControl),
    .isMul(isMul),
    .longFlag(longFlag),
    .state(state)
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
    .PCWrite(PCWrite),
    .RegWrite(RegWrite),
    .MemWrite(MemWrite)
  );
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
  Branch,
  ALUOp,
  isMul,
  longFlag,
  state
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
  output wire Branch;
  output wire ALUOp;
  input wire isMul;
  output wire longFlag;
  output reg [3:0] state;
  reg [3:0] nextstate;
  reg [13:0] controls;
  localparam [3:0] FETCH = 0;
  localparam [3:0] DECODE = 1;
  localparam [3:0] MEMADR = 2;
  localparam [3:0] MEMRD = 3;
  localparam [3:0] MEMWB = 4;
  localparam [3:0] MEMWR = 5;
  localparam [3:0] EXECUTER = 6;
  localparam [3:0] EXECUTEI = 7;
  localparam [3:0] ALUWB = 8;
  localparam [3:0] ALUWB2 = 9;
  localparam [3:0] BRANCH = 10;
  localparam [3:0] UNKNOWN = 11;

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
      ALUWB: nextstate = (((Funct[4:1] == 4'b0100) | (Funct[4:1] == 4'b0110)) & isMul) ? ALUWB2 : FETCH;
      ALUWB2: nextstate = FETCH;
      BRANCH: nextstate = FETCH;
      default: nextstate = FETCH;
    endcase

  // state-dependent output logic
  always @(*)
    case (state)
      FETCH: controls = 14'b10001010011000;
      DECODE: controls = 14'b00000010011000;
      EXECUTER: controls = 14'b00000000000010;
      EXECUTEI: controls = 14'b00000000000110;
      ALUWB: controls = (((Funct[4:1] == 4'b0100) | (Funct[4:1] == 4'b0110)) & isMul) ? 14'b00010000000001 : 14'b00010000000000;
      ALUWB2: controls = 14'b00010000000000;
      MEMADR: controls = 14'b00000000000100;
      MEMWR: controls = 14'b00100100000000;
      MEMRD: controls = 14'b00000100000000;
      MEMWB: controls = 14'b00010001000000;
      BRANCH: controls = 14'b01000010000100;
      default: controls = 14'bx;
    endcase
  assign {NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp, longFlag} = controls;
endmodule

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
  PCWrite,
  RegWrite,
  MemWrite
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
  output wire PCWrite;
  output wire RegWrite;
  output wire MemWrite;
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
endmodule

module floplfr (
  clk,
  reset,
  lf,
  d0,
  d1,
  q
);
  input wire clk;
  input wire reset;
  input wire lf;
  input wire [31:0] d0;
  input wire [31:0] d1;
  output reg [31:0] q;
  always @(posedge clk or posedge reset)
    if (reset)
      q <= 0;
    else if (lf)
      q <= d1;
    else
      q <= d0;
endmodule

module hFSM(
  input clk,
  input reset,
  input [15:0] data,
  output reg [3:0] digit,
  output reg [3:0] anode
);
  reg [1:0] state = 0;

  always @(posedge clk or posedge reset) begin
    if (reset)
      state <= 0;
    else
      state <= state + 1;
  end

  always @(*)
    case (state)
      2'b00: begin
        anode = 4'b0111;
        digit = data[15:12];
      end
      2'b01: begin
        anode = 4'b1011;
        digit = data[11:8];
      end
      2'b10: begin
        anode = 4'b1101;
        digit = data[7:4];
      end
      2'b11: begin
        anode = 4'b1110;
        digit = data[3:0];
      end
      default: begin
        anode = 4'b1111;
        digit = 4'b0000;
      end 
    endcase
endmodule
module CLKdivider(
  input wire clk, 
  input wire reset,
  output reg t
);
  reg [23:0] counter = 1;
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      t <= 0;
      counter <= 0;
    end
    else begin
      counter <= counter + 1;
      if (counter == 0)
        t <= ~t;
    end
  end
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
  IRWrite,
  AdrSrc,
  ResultSrc,
  ALUSrcA,
  ALUSrcB,
  ImmSrc,
  RegSrc,
  ALUControl,
  isMul,
  longFlag,
  state
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
  output wire IRWrite;
  output wire AdrSrc;
  output wire [1:0] ResultSrc;
  output wire [1:0] ALUSrcA;
  output wire [1:0] ALUSrcB;
  output wire [1:0] ImmSrc;
  output wire [1:0] RegSrc;
  output reg [3:0] ALUControl;
  output wire isMul;
  output wire longFlag;
  output wire [3:0] state;
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
    .Branch(Branch),
    .ALUOp(ALUOp),
    .isMul(isMul),
    .longFlag(longFlag),
    .state(state)
  );

  assign isMul = ((Op == 2'b00) & (Mul == 4'b1001));

  // ALU Decoder
  always @(*) begin
    if (ALUOp) begin
      if (isMul) // Instr[7:4] = Multiply Indicator
        case (Funct[4:1])
          4'b0000: ALUControl = 4'b0100; // MUL
          4'b0100: ALUControl = 4'b0110; // UMUL
          4'b0110: ALUControl = 4'b0101; // SMUL
          4'b1000: ALUControl = 4'b0111; // DIV
          default: ALUControl = 4'bxxxx;
        endcase
      else
        case (Funct[4:1])
          4'b0100: ALUControl = 4'b0000; // ADD
          4'b0010: ALUControl = 4'b0001; // SUB
          4'b0000: ALUControl = 4'b0010; // AND
          4'b1100: ALUControl = 4'b0011; // ORR
          4'b0001: ALUControl = 4'b1000; // EOR
          4'b1101: ALUControl = 4'b1001; // MOV
          4'b1110: ALUControl = 4'b1010; // LSL
          4'b1000: ALUControl = 4'b1011; // Add16
          4'b1010: ALUControl = 4'b1100; // Mul16
          4'b1001: ALUControl = 4'b1101; // Add32
          4'b1011: ALUControl = 4'b1110; // Mul32
          default: ALUControl = 4'bxxxx;
        endcase
      FlagW[1] = Funct[0];
      FlagW[0] = Funct[0] & (ALUControl == 4'b000?);
    end else begin
      ALUControl = 4'b0000;
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
  AdrSrc,
  RegSrc,
  ALUSrcA,
  ALUSrcB,
  ResultSrc,
  ImmSrc,
  ALUControl,
  isMul,
  longFlag,
  Rd
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
  input wire AdrSrc;
  input wire [1:0] RegSrc;
  input wire [1:0] ALUSrcA;
  input wire [1:0] ALUSrcB;
  input wire [1:0] ResultSrc;
  input wire [1:0] ImmSrc;
  input wire [3:0] ALUControl;
  input wire isMul;
  input wire longFlag;
  output wire [3:0] Rd;
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
  wire [3:0] RA1;
  wire [3:0] RA2;

  assign PCNext = Result;

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
  assign mRA1 = (isMul) ? Instr[3:0] : Instr[19:16];

  mux2 #(4) ra1mux(
    .d0(mRA1),
    .d1(4'd15),
    .s(RegSrc[0]),
    .y(RA1)
  );

  wire [3:0] mRA2;
  assign mRA2 = (isMul) ? Instr[11:8] : Instr[3:0];

  mux2 #(4) ra2mux(
    .d0(mRA2),
    .d1(Instr[15:12]),
    .s(RegSrc[1]),
    .y(RA2)
  );

  assign Rd = (isMul) ? Instr[19:16] : Instr[15:12];

  extend e(
    .Instr(Instr[23:0]),
    .ImmSrc(ImmSrc),
    .ExtImm(ExtImm)
  );

  regfile rf(
    .clk(clk),
    .we3(RegWrite),
    .we4(longFlag),
    .ra1(RA1),
    .ra2(RA2),
    .a3(Rd),
    .a4(Instr[15:12]),
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
    .Long(ALUResult2),
    .ALUFlags(ALUFlags)
  );

  floplfr alureg(
    .clk(clk),
    .reset(reset),
    .lf(longFlag),
    .d0(ALUResult),
    .d1(ALUResult2),
    .q(ALUOut)
  );

  mux3 #(32) resultmux(
    .d0(ALUOut),
    .d1(Data),
    .d2(ALUResult),
    .s(ResultSrc),
    .y(Result)
  );
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

module top (
  clk,
  reset,
  anode,
  catode,
  state
);
  input wire clk;
  input wire reset;
  output wire [3:0] anode;
  output wire [7:0] catode;
  output wire [3:0] state;
  wire MemWrite;
  wire [31:0] Adr;
  wire [31:0] WriteData;
  wire [31:0] ReadData;
  wire RegWrite;
  wire [31:0] RegDisplay;
  reg [15:0] DisplayData;
  wire [3:0] Rd;
  // instantiate processor and shared memory
  arm arm(
    .clk(clk),
    .reset(reset),
    .MemWrite(MemWrite),
    .Adr(Adr),
    .WriteData(WriteData),
    .ReadData(ReadData),
    .RegWrite(RegWrite),
    .RegDisplay(RegDisplay),
    .Rd(Rd),
    .state(state)
  );
  mem mem(
    .clk(clk),
    .we(MemWrite),
    .a(Adr),
    .wd(WriteData),
    .rd(ReadData)
  );

  // instantiate display controller
  always @(posedge clk or posedge reset) begin
    if (reset) 
      DisplayData <= 16'b0; // reset display data
    else if (RegWrite & (Rd == 4'b1011)) // if register 11 is written to
      DisplayData <= RegDisplay[15:0];
  end

  hex_display hd(
    .clk(clk),
    .reset(reset),
    .data(DisplayData),
    .anode(anode),
    .catode(catode)
  );
endmodule

module Add16 (
  input wire [15:0] a, b,
  output reg [15:0] result
);
  // Deconstruct inputs
  wire sign_a = a[15];
  wire [4:0] exp_a = a[14:10];
  wire [9:0] mant_a = a[9:0];

  wire sign_b = b[15];
  wire [4:0] exp_b = b[14:10];
  wire [9:0] mant_b = b[9:0];

  // Internal registers for calculation
  reg sign_r;
  reg [4:0] exp_r;
  reg [10:0] mant_r;
  reg [11:0] mant_a_ext, mant_b_ext;
  reg [12:0] mant_sum;
  integer shift;

  always @(*) begin
    // Handle special cases: Zero
    if ((exp_a == 0 && mant_a == 0)) begin
      result = b;
    end else if ((exp_b == 0 && mant_b == 0)) begin
      result = a;
    end else begin
      // Add implicit 1 for normalized numbers
      mant_a_ext = (exp_a == 0) ? {1'b0, mant_a} : {1'b1, mant_a};
      mant_b_ext = (exp_b == 0) ? {1'b0, mant_b} : {1'b1, mant_b};

      // 1. Align exponents
      if (exp_a > exp_b) begin
        shift = exp_a - exp_b;
        mant_b_ext = mant_b_ext >> shift;
        exp_r = exp_a;
      end else begin
        shift = exp_b - exp_a;
        mant_a_ext = mant_a_ext >> shift;
        exp_r = exp_b;
      end

      // 2. Add or subtract mantissas based on sign
      if (sign_a == sign_b) begin
        mant_sum = mant_a_ext + mant_b_ext;
        sign_r = sign_a;
      end else begin
        if (mant_a_ext >= mant_b_ext) begin
          mant_sum = mant_a_ext - mant_b_ext;
          sign_r = sign_a;
        end else begin
          mant_sum = mant_b_ext - mant_a_ext;
          sign_r = sign_b;
        end
      end

      // 3. Normalize the result
      if (mant_sum[12]) begin // Overflow on mantissa add
        mant_r = mant_sum[12:2];
        exp_r = exp_r + 1;
      end else if (mant_sum[11]) begin // Normal case
        mant_r = mant_sum[11:1];
      end else begin // Needs left shifting
        // This part handles denormalization after subtraction
        // A full implementation would require a loop or priority encoder
        // For simplicity, we handle a single shift normalization
        if(mant_sum != 0) begin
            while(mant_sum[10] == 0) begin
                mant_sum = mant_sum << 1;
                exp_r = exp_r - 1;
            end
        end
        mant_r = mant_sum[10:0];
      end
      
      // Handle underflow/overflow for exponent
      if (exp_r >= 31) begin
        result = {sign_r, 5'b11111, 10'b0}; // Infinity
      end else if (exp_r <= 0) begin
         result = {sign_r, 5'b0, mant_r}; // Denormalized or Zero
      end else begin
        result = {sign_r, exp_r, mant_r[9:0]}; // Normalized number
      end
    end
  end
endmodule

module Mul16 (
  input wire [15:0] a, b,
  output reg [15:0] result
);
  // Deconstruct inputs
  wire sign_a = a[15];
  wire [4:0] exp_a = a[14:10];
  wire [9:0] mant_a_in = a[9:0];

  wire sign_b = b[15];
  wire [4:0] exp_b = b[14:10];
  wire [9:0] mant_b_in = b[9:0];

  // Internal registers for calculation
  reg sign_r;
  reg signed [5:0] exp_r; // Use signed for bias subtraction
  reg [10:0] mant_a, mant_b;
  reg [21:0] mant_mul;

  always @(*) begin
    // Handle special cases: Zero
    if ((exp_a == 0 && mant_a_in == 0) || (exp_b == 0 && mant_b_in == 0)) begin
      result = 16'b0;
    end else begin
      // 1. Add implicit 1 for normalized numbers
      mant_a = (exp_a == 0) ? {1'b0, mant_a_in} : {1'b1, mant_a_in};
      mant_b = (exp_b == 0) ? {1'b0, mant_b_in} : {1'b1, mant_b_in};

      // 2. Multiply mantissas
      mant_mul = mant_a * mant_b;

      // 3. Add exponents and subtract bias (15)
      exp_r = exp_a + exp_b - 15;
      sign_r = sign_a ^ sign_b;

      // 4. Normalize the result
      if (mant_mul[21]) begin // Result has 22 bits, check MSB
        mant_mul = mant_mul >> 1;
        exp_r = exp_r + 1;
      end
      
      // Handle overflow/underflow for exponent
      if (exp_r >= 31) begin
        result = {sign_r, 5'b11111, 10'b0}; // Infinity
      end else if (exp_r <= 0) begin
        result = {sign_r, 5'b0, mant_mul[20:11]}; // Denormalized or Zero
      end else begin
        result = {sign_r, exp_r[4:0], mant_mul[20:11]}; // Normalized number
      end
    end
  end
endmodule

module Add32 (
  input wire [31:0] a, b,
  output reg [31:0] result
);
  // Deconstruct inputs
  wire sign_a = a[31];
  wire [7:0] exp_a = a[30:23];
  wire [22:0] mant_a = a[22:0];

  wire sign_b = b[31];
  wire [7:0] exp_b = b[30:23];
  wire [22:0] mant_b = b[22:0];

  // Internal registers for calculation
  reg sign_r;
  reg [7:0] exp_r;
  reg [23:0] mant_r;
  reg [24:0] mant_a_ext, mant_b_ext;
  reg [25:0] mant_sum;
  integer shift;

  always @(*) begin
    // Handle special cases: Zero
    if ((exp_a == 0 && mant_a == 0)) begin
      result = b;
    end else if ((exp_b == 0 && mant_b == 0)) begin
      result = a;
    end else begin
      // Add implicit 1 for normalized numbers
      mant_a_ext = (exp_a == 0) ? {1'b0, mant_a} : {1'b1, mant_a};
      mant_b_ext = (exp_b == 0) ? {1'b0, mant_b} : {1'b1, mant_b};

      // 1. Align exponents
      if (exp_a > exp_b) begin
        shift = exp_a - exp_b;
        mant_b_ext = mant_b_ext >> shift;
        exp_r = exp_a;
      end else begin
        shift = exp_b - exp_a;
        mant_a_ext = mant_a_ext >> shift;
        exp_r = exp_b;
      end

      // 2. Add or subtract mantissas
      if (sign_a == sign_b) begin
        mant_sum = mant_a_ext + mant_b_ext;
        sign_r = sign_a;
      end else begin
        if (mant_a_ext >= mant_b_ext) begin
          mant_sum = mant_a_ext - mant_b_ext;
          sign_r = sign_a;
        end else begin
          mant_sum = mant_b_ext - mant_a_ext;
          sign_r = sign_b;
        end
      end
      
      // 3. Normalize the result
      if (mant_sum[25]) begin // Overflow on mantissa add
        mant_r = mant_sum[25:2];
        exp_r = exp_r + 1;
      end else if (mant_sum[24]) begin // Normal case
        mant_r = mant_sum[24:1];
      end else begin // Needs left shifting
        if(mant_sum != 0) begin
            while(mant_sum[23] == 0) begin
                mant_sum = mant_sum << 1;
                exp_r = exp_r - 1;
            end
        end
        mant_r = mant_sum[23:0];
      end

      // Handle underflow/overflow for exponent
      if (exp_r >= 255) begin
        result = {sign_r, 8'hFF, 23'b0}; // Infinity
      end else if (exp_r == 0) begin
        result = {sign_r, 8'b0, mant_r[22:0]}; // Denormalized or Zero
      end else begin
        result = {sign_r, exp_r, mant_r[22:0]}; // Normalized number
      end
    end
  end
endmodule

module Mul32 (
  input wire [31:0] a, b,
  output reg [31:0] result
);
  // Deconstruct inputs
  wire sign_a = a[31];
  wire [7:0] exp_a = a[30:23];
  wire [22:0] mant_a_in = a[22:0];

  wire sign_b = b[31];
  wire [7:0] exp_b = b[30:23];
  wire [22:0] mant_b_in = b[22:0];

  // Internal registers for calculation
  reg sign_r;
  reg signed [8:0] exp_r; // Use signed for bias subtraction
  reg [23:0] mant_a, mant_b;
  reg [47:0] mant_mul;

  always @(*) begin
    // Handle special cases: Zero
    if ((exp_a == 0 && mant_a_in == 0) || (exp_b == 0 && mant_b_in == 0)) begin
      result = 32'b0;
    end else begin
      // 1. Add implicit 1 for normalized numbers
      mant_a = (exp_a == 0) ? {1'b0, mant_a_in} : {1'b1, mant_a_in};
      mant_b = (exp_b == 0) ? {1'b0, mant_b_in} : {1'b1, mant_b_in};

      // 2. Multiply mantissas
      mant_mul = mant_a * mant_b;

      // 3. Add exponents and subtract bias (127)
      exp_r = exp_a + exp_b - 127;
      sign_r = sign_a ^ sign_b;

      // 4. Normalize the result
      if (mant_mul[47]) begin // Result has 48 bits, check MSB
        mant_mul = mant_mul >> 1;
        exp_r = exp_r + 1;
      end
      
      // Handle overflow/underflow for exponent
      if (exp_r >= 255) begin
        result = {sign_r, 8'hFF, 23'b0}; // Infinity
      end else if (exp_r <= 0) begin
        result = {sign_r, 8'b0, mant_mul[46:24]}; // Denormalized or Zero
      end else begin
        result = {sign_r, exp_r[7:0], mant_mul[46:24]}; // Normalized number
      end
    end
  end
endmodule
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
