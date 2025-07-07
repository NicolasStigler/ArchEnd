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
  Long
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
  input wire Long;
  reg [3:0] state;
  reg [3:0] nextstate;
  reg [14:0] controls;
  localparam [3:0] FETCH = 0;
  localparam [3:0] DECODE = 1;
  localparam [3:0] MEMADR = 2;
  localparam [3:0] MEMRD = 3;
  localparam [3:0] MEMWB = 4;
  localparam [3:0] MEMWR = 5;
  localparam [3:0] EXECUTER = 6;
  localparam [3:0] EXECUTEI = 7;
  localparam [3:0] EXECUTEF = 8;
  localparam [3:0] ALUWB = 9;
  localparam [3:0] ALUWB2 = 10;
  localparam [3:0] FPUWB = 11;
  localparam [3:0] BRANCH = 12;
  localparam [3:0] UNKNOWN = 13;

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
          2'b11: nextstate = EXECUTEF;
          default: nextstate = UNKNOWN;
        endcase
      EXECUTER: nextstate = (Long == 1'b1) ? ALUWB2 : ALUWB;
      EXECUTEI: nextstate = (Long == 1'b1) ? ALUWB2 : ALUWB;
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
      ALUWB2: nextstate = FETCH;
      FPUWB: nextstate = FETCH;
      BRANCH: nextstate = FETCH;
      default: nextstate = FETCH;
    endcase

  // state-dependent output logic
  always @(*)
    case (state)
      FETCH: controls = 15'b100001010011000;
      DECODE: controls = 15'b000000010011000;
      EXECUTER: controls = 15'b000000000000010;
      EXECUTEI: controls = 15'b000000000000110;
      EXECUTEF: controls = 15'b000000000000000;
      ALUWB: controls = 15'b000100000000000;
      ALUWB2: controls = 15'b000100000000001;
      FPUWB: controls = 15'b000010000000000;
      MEMADR: controls = 15'b000000000000100;
      MEMWR: controls = 15'b001000100000000;
      MEMRD: controls = 15'b000000100000000;
      MEMWB: controls = 15'b000100001000000;
      BRANCH: controls = 15'b010000010000100;
      default: controls = 15'bx;
    endcase
  assign {NextPC, Branch, MemW, RegW, FPUW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp, Long} = controls;
endmodule
