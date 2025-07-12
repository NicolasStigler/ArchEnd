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
  ALUOp,
  longFlag,
  long
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
  output wire longFlag;
  input wire long;
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
      EXECUTER: nextstate = long == 1 ? ALUWB2 : ALUWB;
      EXECUTEI: nextstate = long == 1 ? ALUWB2 : ALUWB;
      EXECUTEF: nextstate = FPUWB;
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
      FETCH: controls =    14'b10001010011000;
      DECODE: controls =   14'b00000010011000;
      EXECUTER: controls = 14'b00000000000010;
      EXECUTEI: controls = 14'b00000000000110;
      EXECUTEF: controls = 14'b00000000000000;
      MEMADR: controls =   14'b00000000000100;
      MEMRD: controls =    14'b00000100000000;
      MEMWB: controls =    14'b00010001000000;
      MEMWR: controls =    14'b00100100000000;
      ALUWB: controls =    14'b00010000000000;
      ALUWB2: controls =   14'b00010000000001;
      FPUWB: controls =    14'b00010000000000;
      BRANCH: controls =   14'b01000010000100;
      default: controls = 14'b0;
    endcase
  assign {NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp, longFlag} = controls;
endmodule
