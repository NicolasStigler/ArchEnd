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
  reg Long;

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
    .ALUOp(ALUOp),
    .Long(Long)
  );

  // ALU Decoder
  always @(*) begin
    Long = 1'b0;
    if (Op == 2'b11) begin
      ALUControl[0] = Funct[0];
      ALUControl[1] = Funct[2];
      ALUControl[2] = 1'b0;
      FlagW = 2'b00;
    end else if (ALUOp) begin
      if (Mul == 4'b1001) // Instr[7:4] = Multiply Indicator
        case (Funct[4:1])
          4'b0000: ALUControl = 3'b100; // MUL
          4'b0110: begin
            ALUControl = 3'b101; // SMUL
            Long = 1'b1;
          end
          4'b0100: begin
            ALUControl = 3'b110; // UMUL
            Long = 1'b1;
          end
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
