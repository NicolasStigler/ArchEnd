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
    3'b00?: Result = sum;
    3'b010: Result = a & b;
    3'b011: Result = a | b;
    3'b100: Result = a ^ b;
    3'b101: Result = a * b;
    3'b110: { Long, Result } = a * b;
    3'b111:
      case ({ a[31], b[31] })
        2'b00: { Long, Result } = a * b;
        2'b01: { Long, Result } = -((a) * -(b));
        2'b10: { Long, Result } = -(-(a) * (b));
        2'b11: { Long, Result } = -(a) * -(b);
      endcase
  endcase
end

assign neg = Result[31];
assign zero = (Result == 32'b0);
assign carry = (ALUControl[1] == 1'b0) & sum[32];
assign overflow = (ALUControl[1] == 1'b0) & ~(a[31] ^ b[31] ^ ALUControl[0]) & (a[31] ^ sum[31]);
assign ALUFlags = {neg, zero, carry, overflow};

endmodule
