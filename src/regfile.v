module regfile (
  clk,
  we3,
  we4,
  ra1,
  ra2,
  a3,
  a4,
  wd3,
  r15,
  rd1,
  rd2
);
  input wire clk;
  input wire we3;
  input wire we4;
  input wire [3:0] ra1;
  input wire [3:0] ra2;
  input wire [3:0] a3;
  input wire [3:0] a4;
  input wire [31:0] wd3;
  input wire [31:0] r15; // PC+8
  output wire [31:0] rd1;
  output wire [31:0] rd2;
  reg [31:0] rf [14:0]; // 15 registers
  always @(posedge clk) begin
    if (we3)
      rf[a3] <= wd3; // write wd3 into the register a3
    if (we4)
      rf[a4] <= wd3; // write wd3 into the register a4
  end

  // if ra is 15, use r15, else use register in rf
  assign rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1];
  assign rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];
endmodule
