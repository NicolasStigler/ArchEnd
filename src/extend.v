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