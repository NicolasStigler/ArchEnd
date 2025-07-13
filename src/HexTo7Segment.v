module HexTo7Segment (
  input [3:0] digit,
  output reg [7:0] catode
);
  always @(*)
    case (digit)
      4'h0: catode = 8'b00000011; // 0
      4'h1: catode = 8'b10011111; // 1
      4'h2: catode = 8'b00100101; // 2
      4'h3: catode = 8'b00001101; // 3
      4'h4: catode = 8'b10011001; // 4
      4'h5: catode = 8'b01001001; // 5
      4'h6: catode = 8'b01000001; // 6
      4'h7: catode = 8'b00011111; // 7
      4'h8: catode = 8'b00000001; // 8
      4'h9: catode = 8'b00001001; // 9
      4'hA: catode = 8'b00010001; // A
      4'hB: catode = 8'b11000001; // B
      4'hC: catode = 8'b01100011; // C
      4'hD: catode = 8'b10000101; // D
      4'hE: catode = 8'b01100001; // E
      4'hF: catode = 8'b01110001; // F
      default: catode = 8'b11111111; // off
    endcase
endmodule