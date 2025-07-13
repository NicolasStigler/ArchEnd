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
