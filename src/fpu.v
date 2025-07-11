module fpu (
  input wire [31:0] a, b,
  input wire op, // 0: add, 1: mul
  input wire prec, // 0: half, 1: single
  output reg [31:0] result
);

  // Internal signals for half precision
  wire [15:0] a_half = a[15:0];
  wire [15:0] b_half = b[15:0];
  reg [15:0] res_half;
  reg [31:0] res_single;

  // IEEE 754 half precision parameters
  localparam HALF_EXP_BITS = 5;
  localparam HALF_FRAC_BITS = 10;
  localparam HALF_EXP_BIAS = 15;

  // IEEE 754 single precision parameters
  localparam SINGLE_EXP_BITS = 8;
  localparam SINGLE_FRAC_BITS = 23;
  localparam SINGLE_EXP_BIAS = 127;

  // Helper function for normalization and rounding (half precision)
  function [15:0] half_add;
    input [15:0] x, y;
    reg sign_x, sign_y, sign_res;
    reg [4:0] exp_x, exp_y, exp_res;
    reg [10:0] frac_x, frac_y, frac_res;
    reg [11:0] sum;
    begin
      sign_x = x[15];
      exp_x = x[14:10];
      frac_x = {1'b1, x[9:0]};
      sign_y = y[15];
      exp_y = y[14:10];
      frac_y = {1'b1, y[9:0]};
      // Align exponents
      if (exp_x > exp_y) begin
        frac_y = frac_y >> (exp_x - exp_y);
        exp_res = exp_x;
      end else begin
        frac_x = frac_x >> (exp_y - exp_x);
        exp_res = exp_y;
      end
      // Add/subtract mantissas
      if (sign_x == sign_y)
        sum = frac_x + frac_y;
      else if (frac_x >= frac_y)
        sum = frac_x - frac_y;
      else begin
        sum = frac_y - frac_x;
        sign_res = sign_y;
      end
      // Normalize
      if (sum[11]) begin
        sum = sum >> 1;
        exp_res = exp_res + 1;
      end
      frac_res = sum[10:0];
      sign_res = sign_x;
      half_add = {sign_res, exp_res, frac_res[9:0]};
    end
  endfunction

  // Helper function for multiplication (half precision)
  function [15:0] half_mul;
    input [15:0] x, y;
    reg sign_x, sign_y, sign_res;
    reg [4:0] exp_x, exp_y, exp_res;
    reg [10:0] frac_x, frac_y;
    reg [21:0] prod;
    begin
      sign_x = x[15];
      exp_x = x[14:10];
      frac_x = {1'b1, x[9:0]};
      sign_y = y[15];
      exp_y = y[14:10];
      frac_y = {1'b1, y[9:0]};
      sign_res = sign_x ^ sign_y;
      exp_res = exp_x + exp_y - HALF_EXP_BIAS;
      prod = frac_x * frac_y;
      // Normalize
      if (prod[21]) begin
        prod = prod >> 1;
        exp_res = exp_res + 1;
      end
      half_mul = {sign_res, exp_res[4:0], prod[19:10]};
    end
  endfunction

  // Helper function for normalization and rounding (single precision)
  function [31:0] single_add;
    input [31:0] x, y;
    reg sign_x, sign_y, sign_res;
    reg [7:0] exp_x, exp_y, exp_res;
    reg [23:0] frac_x, frac_y, frac_res;
    reg [24:0] sum;
    begin
      sign_x = x[31];
      exp_x = x[30:23];
      frac_x = {1'b1, x[22:0]};
      sign_y = y[31];
      exp_y = y[30:23];
      frac_y = {1'b1, y[22:0]};
      // Align exponents
      if (exp_x > exp_y) begin
        frac_y = frac_y >> (exp_x - exp_y);
        exp_res = exp_x;
      end else begin
        frac_x = frac_x >> (exp_y - exp_x);
        exp_res = exp_y;
      end
      // Add/subtract mantissas
      if (sign_x == sign_y)
        sum = frac_x + frac_y;
      else if (frac_x >= frac_y)
        sum = frac_x - frac_y;
      else begin
        sum = frac_y - frac_x;
        sign_res = sign_y;
      end
      // Normalize
      if (sum[24]) begin
        sum = sum >> 1;
        exp_res = exp_res + 1;
      end
      frac_res = sum[23:0];
      sign_res = sign_x;
      single_add = {sign_res, exp_res, frac_res[22:0]};
    end
  endfunction

  // Helper function for multiplication (single precision)
  function [31:0] single_mul;
    input [31:0] x, y;
    reg sign_x, sign_y, sign_res;
    reg [7:0] exp_x, exp_y, exp_res;
    reg [23:0] frac_x, frac_y;
    reg [47:0] prod;
    begin
      sign_x = x[31];
      exp_x = x[30:23];
      frac_x = {1'b1, x[22:0]};
      sign_y = y[31];
      exp_y = y[30:23];
      frac_y = {1'b1, y[22:0]};
      sign_res = sign_x ^ sign_y;
      exp_res = exp_x + exp_y - SINGLE_EXP_BIAS;
      prod = frac_x * frac_y;
      // Normalize
      if (prod[47]) begin
        prod = prod >> 1;
        exp_res = exp_res + 1;
      end
      single_mul = {sign_res, exp_res, prod[45:23]};
    end
  endfunction

  always @(*) begin
    if (prec == 1'b0) begin // half precision
      if (op == 1'b0) begin // add
        res_half = half_add(a_half, b_half);
      end else begin // mul
        res_half = half_mul(a_half, b_half);
      end
      result = {16'b0, res_half};
    end else begin // single precision
      if (op == 1'b0) begin // add
        res_single = single_add(a, b);
      end else begin // mul
        res_single = single_mul(a, b);
      end
      result = res_single;
    end
  end
endmodule
