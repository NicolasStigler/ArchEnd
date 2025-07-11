module mux4 (
  d0,
  d1,
  d2,
  d3,
  s,
  y
);
  parameter WIDTH = 8;
  input wire [WIDTH - 1:0] d0; // 00
  input wire [WIDTH - 1:0] d1; // 01
  input wire [WIDTH - 1:0] d2; // 10
  input wire [WIDTH - 1:0] d3; // 11
  input wire [1:0] s;
  output wire [WIDTH - 1:0] y;
  assign y = (s[1] ? (s[0] ? d3 : d2) : (s[0] ? d1 : d0));
endmodule
