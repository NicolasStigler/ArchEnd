module fpu (
  input wire clk,
  input wire start,
  input wire [1:0] op,        // 00 = add, 01 = mul
  input wire precision,       // 0 = single (32), 1 = half (16)
  input wire [31:0] a,
  input wire [31:0] b,
  output reg [31:0] result,
  output reg done,
  output reg overflow
);

  real a_real, b_real, res_real;

  always @(*) begin
    done = 0;
    overflow = 0;
    a_real = $bitstoreal(a);
    b_real = $bitstoreal(b);

    case (op)
      2'b00: res_real = a_real + b_real;
      2'b01: res_real = a_real * b_real;
      default: res_real = 0;
    endcase

    if (res_real > 3.4028235e38 || res_real < -3.4028235e38)
      overflow = 1;

    result = $realtobits(res_real);
    done = 1;
  end
endmodule
