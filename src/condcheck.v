module condcheck (
  Cond,
  Flags,
  CondEx
);
  input wire [3:0] Cond;
  input wire [3:0] Flags;
  output wire CondEx;

  always @(*)
    case (Cond)
      4'b0000: CondEx = Flags[2];
      4'b0001: CondEx = ~Flags[2];
      4'b0010: CondEx = Flags[1];
      4'b0011: CondEx = ~Flags[1];
      4'b0100: CondEx = Flags[3];
      4'b0101: CondEx = ~Flags[3];
      4'b0110: CondEx = Flags[0];
      4'b0111: CondEx = ~Flags[0];
      4'b1000: CondEx = (Flags[1] & ~Flags[2]);
      4'b1001: CondEx = (~Flags[1] | Flags[2]);
      4'b1010: CondEx = (Flags[3] == Flags[0]);
      4'b1011: CondEx = (Flags[3] != Flags[0]);
      4'b1100: CondEx = (~Flags[2] & (Flags[3] == Flags[0]));
      4'b1101: CondEx = (Flags[2] | (Flags[3] != Flags[0]));
      4'b1110: CondEx = 1'b1;
      default: CondEx = 1'bx;
    endcase
endmodule
