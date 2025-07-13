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
  endcase
end

assign neg = Result[31];
assign zero = (Result == 32'b0);
assign carry = (ALUControl[1] == 1'b0) & sum[32];
assign overflow = (ALUControl[1] == 1'b0) & ~(a[31] ^ b[31] ^ ALUControl[0]) & (a[31] ^ sum[31]);
assign ALUFlags = {neg, zero, carry, overflow};

endmodule
