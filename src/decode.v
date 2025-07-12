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
  output reg RegW;
  output wire MemW;
  output reg FPUW;
  output wire IRWrite;
  output wire AdrSrc;
  output reg [1:0] ResultSrc;
  output reg [1:0] ALUSrcA;
  output reg [1:0] ALUSrcB;
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
    ALUControl = 3'b000;
    FlagW = 2'b00;
    FPUW = 0;
    ResultSrc = 2'b00;
    ALUSrcA = 2'b00;
    ALUSrcB = 2'b00;
    IRWrite = 0;
    RegW = 0;

    // Lógica para ALU
    if (ALUOp) begin
      if (Mul == 4'b1001)
        case (Funct[4:1])
          4'b0000: ALUControl = 3'b100; // MUL
          4'b0100: ALUControl = 3'b101; // SMUL
          4'b0110: ALUControl = 3'b110; // UMUL
          4'b1000: ALUControl = 3'b111; // DIV
          default: ALUControl = 3'b000;
        endcase
      else
        case (Funct[4:1])
          4'b0100: ALUControl = 3'b000; // ADD
          4'b0010: ALUControl = 3'b001; // SUB
          4'b0000: ALUControl = 3'b010; // AND
          4'b1100: ALUControl = 3'b011; // ORR
          default: ALUControl = 3'b000;
        endcase

      FlagW[1] = Funct[0];
      FlagW[0] = Funct[0] & (ALUControl == 3'b000);
    end

    // Lógica para instrucciones flotantes
    if (Op == 2'b11) begin
      case (Funct)
        6'b000000: begin // FADD
          FPUW = 1;
          ResultSrc = 2'b10;
          RegW = 1;
        end
        6'b000001: begin // FMUL
          FPUW = 1;
          ResultSrc = 2'b10;
          RegW = 1;
        end
        6'b000010: begin // FADDH
          FPUW = 1;
          ResultSrc = 2'b10;
          RegW = 1;
        end
        6'b000011: begin // FMULH
          FPUW = 1;
          ResultSrc = 2'b10;
          RegW = 1;
        end
      endcase
    end
  end

  // PC Logic
  assign PCS = ((Rd == 4'b1111) & RegW) | Branch;

  // Instr Decoder
  assign ImmSrc = Op;
  assign RegSrc[1] = Op == 2'b01;
  assign RegSrc[0] = Op == 2'b10;
endmodule
