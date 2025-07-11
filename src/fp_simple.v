module fp_add(
  input  [31:0] a,
  input  [31:0] b,
  output [31:0] result
);
  // Extract sign, exponent, mantissa
  wire sign_a = a[31];
  wire sign_b = b[31];
  wire [7:0] exp_a = a[30:23];
  wire [7:0] exp_b = b[30:23];
  wire [23:0] mant_a = {1'b1, a[22:0]};
  wire [23:0] mant_b = {1'b1, b[22:0]};

  // Align exponents
  wire [7:0] exp_diff = (exp_a > exp_b) ? (exp_a - exp_b) : (exp_b - exp_a);
  wire [23:0] mant_a_shifted = (exp_a >= exp_b) ? mant_a : (mant_a >> exp_diff);
  wire [23:0] mant_b_shifted = (exp_b > exp_a) ? mant_b : (mant_b >> exp_diff);
  wire [7:0] exp_res = (exp_a >= exp_b) ? exp_a : exp_b;

  // Add/subtract mantissas
  wire [24:0] mant_res;
  assign mant_res = (sign_a == sign_b) ? (mant_a_shifted + mant_b_shifted) : (mant_a_shifted - mant_b_shifted);
  wire sign_res = (mant_res[24]) ? sign_a : sign_b;

  // Normalize result
  reg [7:0] exp_norm;
  reg [22:0] mant_norm;
  reg [24:0] mant_tmp;
  integer i;
  always @(*) begin
    mant_tmp = mant_res;
    exp_norm = exp_res;
    // Normalize (shift left until MSB is 1)
    for (i = 24; i > 0; i = i - 1) begin
      if (mant_tmp[i]) begin
        mant_norm = mant_tmp[i-1: i-23];
        exp_norm = exp_norm + (i - 23);
        break;
      end
    end
  end
  assign result = {sign_res, exp_norm, mant_norm};
endmodule

module fp_mul(
  input  [31:0] a,
  input  [31:0] b,
  output [31:0] result
);
  wire sign_a = a[31];
  wire sign_b = b[31];
  wire [7:0] exp_a = a[30:23];
  wire [7:0] exp_b = b[30:23];
  wire [23:0] mant_a = {1'b1, a[22:0]};
  wire [23:0] mant_b = {1'b1, b[22:0]};

  wire sign_res = sign_a ^ sign_b;
  wire [8:0] exp_res = exp_a + exp_b - 8'd127;
  wire [47:0] mant_res = mant_a * mant_b;

  // Normalize mantissa
  wire [22:0] mant_norm = mant_res[47] ? mant_res[46:24] : mant_res[45:23];
  wire [7:0] exp_norm = mant_res[47] ? exp_res + 1 : exp_res;

  assign result = {sign_res, exp_norm, mant_norm};
endmodule
