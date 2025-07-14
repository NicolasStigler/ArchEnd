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
