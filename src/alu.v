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
