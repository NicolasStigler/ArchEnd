module floplfr (
  clk,
  reset,
  lf,
  d0,
  d1,
  q
);
  input wire clk;
  input wire reset;
  input wire lf;
  input wire [31:0] d0;
  input wire [31:0] d1;
  output reg [31:0] q;
  always @(posedge clk or posedge reset)
    if (reset)
      q <= 0;
    else if (lf)
      q <= d1;
    else
      q <= d0;
endmodule
