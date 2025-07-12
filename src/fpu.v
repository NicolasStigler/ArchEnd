module fpu(
  input wire [31:0] a, b,
  input wire op, // 0: add, 1: mul
  input wire prec, // 0: half, 1: single
  output reg [31:0] result
);
  // IEEE 754 half precision add
  function [15:0] half_add;
    input [15:0] a, b;
    reg sign_a, sign_b, sign_r;
    reg [4:0] exp_a, exp_b, exp_r;
    reg [10:0] mant_a, mant_b, mant_r;
    reg [11:0] mant_a_ext, mant_b_ext;
    reg [12:0] mant_sum;
    reg [15:0] result;
    integer shift;
    begin
      sign_a = a[15];
      exp_a = a[14:10];
      mant_a = a[9:0];
      sign_b = b[15];
      exp_b = b[14:10];
      mant_b = b[9:0];
      // Handle zero
      if (exp_a == 0 && mant_a == 0)
        half_add = b;
      else if (exp_b == 0 && mant_b == 0)
        half_add = a;
      else begin
        // Add implicit 1 for normalized
        mant_a_ext = (exp_a == 0) ? {1'b0, mant_a} : {1'b1, mant_a};
        mant_b_ext = (exp_b == 0) ? {1'b0, mant_b} : {1'b1, mant_b};
        // Align exponents
        if (exp_a > exp_b) begin
          shift = exp_a - exp_b;
          mant_b_ext = mant_b_ext >> shift;
          exp_r = exp_a;
        end else begin
          shift = exp_b - exp_a;
          mant_a_ext = mant_a_ext >> shift;
          exp_r = exp_b;
        end
        // Add/sub mantissas
        if (sign_a == sign_b) begin
          mant_sum = mant_a_ext + mant_b_ext;
          sign_r = sign_a;
        end else begin
          if (mant_a_ext >= mant_b_ext) begin
            mant_sum = mant_a_ext - mant_b_ext;
            sign_r = sign_a;
          end else begin
            mant_sum = mant_b_ext - mant_a_ext;
            sign_r = sign_b;
          end
        end
        // Normalize
        if (mant_sum[12]) begin
          mant_r = mant_sum[12:2];
          exp_r = exp_r + 1;
        end else begin
          mant_r = mant_sum[11:1];
        end
        // Handle underflow/overflow
        if (exp_r >= 31) begin
          result = {sign_r, 5'b11111, 10'b0}; // Inf
        end else if (exp_r == 0) begin
          result = {sign_r, 5'b0, mant_r[9:0]}; // Denorm
        end else begin
          result = {sign_r, exp_r[4:0], mant_r[9:0]};
        end
        half_add = result;
      end
      // Add implicit 1 for normalized
      mant_a_ext = (exp_a == 0) ? {1'b0, mant_a} : {1'b1, mant_a};
      mant_b_ext = (exp_b == 0) ? {1'b0, mant_b} : {1'b1, mant_b};
      // Align exponents
      if (exp_a > exp_b) begin
        shift = exp_a - exp_b;
        mant_b_ext = mant_b_ext >> shift;
        exp_r = exp_a;
      end else begin
        shift = exp_b - exp_a;
        mant_a_ext = mant_a_ext >> shift;
        exp_r = exp_b;
      end
      // Add/sub mantissas
      if (sign_a == sign_b) begin
        mant_sum = mant_a_ext + mant_b_ext;
        sign_r = sign_a;
      end else begin
        if (mant_a_ext >= mant_b_ext) begin
          mant_sum = mant_a_ext - mant_b_ext;
          sign_r = sign_a;
        end else begin
          mant_sum = mant_b_ext - mant_a_ext;
          sign_r = sign_b;
        end
      end
      // Normalize
      if (mant_sum[12]) begin
        mant_r = mant_sum[12:2];
        exp_r = exp_r + 1;
      end else begin
        mant_r = mant_sum[11:1];
      end
      // Handle underflow/overflow
      if (exp_r >= 31) begin
        result = {sign_r, 5'b11111, 10'b0}; // Inf
      end else if (exp_r == 0) begin
        result = {sign_r, 5'b0, mant_r[9:0]}; // Denorm
      end else begin
        result = {sign_r, exp_r[4:0], mant_r[9:0]};
      end
      half_add = result;
    end
  endfunction

  // IEEE 754 half precision mul
  function [15:0] half_mul;
    input [15:0] a, b;
    reg sign_a, sign_b, sign_r;
    reg [4:0] exp_a, exp_b, exp_r;
    reg [10:0] mant_a, mant_b;
    reg [21:0] mant_mul;
    reg [15:0] result;
    begin
      sign_a = a[15];
      exp_a = a[14:10];
      mant_a = a[9:0];
      sign_b = b[15];
      exp_b = b[14:10];
      mant_b = b[9:0];
      // Handle zero
      if ((exp_a == 0 && mant_a == 0) || (exp_b == 0 && mant_b == 0))
        half_mul = 16'b0;
      else begin
        // Add implicit 1 for normalized
        mant_a = (exp_a == 0) ? mant_a : {1'b1, mant_a[9:0]};
        mant_b = (exp_b == 0) ? mant_b : {1'b1, mant_b[9:0]};
        mant_mul = mant_a * mant_b;
        exp_r = exp_a + exp_b - 15;
        sign_r = sign_a ^ sign_b;
        // Normalize
        if (mant_mul[21]) begin
          mant_mul = mant_mul >> 11;
          exp_r = exp_r + 1;
        end else begin
          mant_mul = mant_mul >> 10;
        end
        // Handle overflow/underflow
        if (exp_r >= 31) begin
          result = {sign_r, 5'b11111, 10'b0}; // Inf
        end else if (exp_r <= 0) begin
          result = {sign_r, 5'b0, mant_mul[9:0]}; // Denorm
        end else begin
          result = {sign_r, exp_r[4:0], mant_mul[9:0]};
        end
        half_mul = result;
      end
    end
  endfunction

  // IEEE 754 single precision add
  function [31:0] single_add;
    input [31:0] a, b;
    reg sign_a, sign_b, sign_r;
    reg [7:0] exp_a, exp_b, exp_r;
    reg [22:0] mant_a, mant_b, mant_r;
    reg [23:0] mant_a_ext, mant_b_ext;
    reg [24:0] mant_sum;
    reg [31:0] result;
    integer shift;
    begin
      sign_a = a[31];
      exp_a = a[30:23];
      mant_a = a[22:0];
      sign_b = b[31];
      exp_b = b[30:23];
      mant_b = b[22:0];
      // Handle zero
      if (exp_a == 0 && mant_a == 0)
        single_add = b;
      else if (exp_b == 0 && mant_b == 0)
        single_add = a;
      else begin
        // Add implicit 1 for normalized
        mant_a_ext = (exp_a == 0) ? {1'b0, mant_a} : {1'b1, mant_a};
        mant_b_ext = (exp_b == 0) ? {1'b0, mant_b} : {1'b1, mant_b};
        // Align exponents
        if (exp_a > exp_b) begin
          shift = exp_a - exp_b;
          mant_b_ext = mant_b_ext >> shift;
          exp_r = exp_a;
        end else begin
          shift = exp_b - exp_a;
          mant_a_ext = mant_a_ext >> shift;
          exp_r = exp_b;
        end
        // Add/sub mantissas
        if (sign_a == sign_b) begin
          mant_sum = mant_a_ext + mant_b_ext;
          sign_r = sign_a;
        end else begin
          if (mant_a_ext >= mant_b_ext) begin
            mant_sum = mant_a_ext - mant_b_ext;
            sign_r = sign_a;
          end else begin
            mant_sum = mant_b_ext - mant_a_ext;
            sign_r = sign_b;
          end
        end
        // Normalize
        if (mant_sum[24]) begin
          mant_r = mant_sum[24:2];
          exp_r = exp_r + 1;
        end else begin
          mant_r = mant_sum[23:1];
        end
        // Handle underflow/overflow
        if (exp_r >= 255) begin
          result = {sign_r, 8'hff, 23'b0}; // Inf
        end else if (exp_r == 0) begin
          result = {sign_r, 8'b0, mant_r[22:0]}; // Denorm
        end else begin
          result = {sign_r, exp_r[7:0], mant_r[22:0]};
        end
        single_add = result;
      end
    end
  endfunction

  // IEEE 754 single precision mul
  function [31:0] single_mul;
    input [31:0] a, b;
    reg sign_a, sign_b, sign_r;
    reg [7:0] exp_a, exp_b, exp_r;
    reg [22:0] mant_a, mant_b;
    reg [47:0] mant_mul;
    reg [31:0] result;
    begin
      sign_a = a[31];
      exp_a = a[30:23];
      mant_a = a[22:0];
      sign_b = b[31];
      exp_b = b[30:23];
      mant_b = b[22:0];
      // Handle zero
      if ((exp_a == 0 && mant_a == 0) || (exp_b == 0 && mant_b == 0))
        single_mul = 32'b0;
      else begin
        // Add implicit 1 for normalized
        mant_a = (exp_a == 0) ? mant_a : {1'b1, mant_a[22:0]};
        mant_b = (exp_b == 0) ? mant_b : {1'b1, mant_b[22:0]};
        mant_mul = mant_a * mant_b;
        exp_r = exp_a + exp_b - 127;
        sign_r = sign_a ^ sign_b;
        // Normalize
        if (mant_mul[47]) begin
          mant_mul = mant_mul >> 24;
          exp_r = exp_r + 1;
        end else begin
          mant_mul = mant_mul >> 23;
        end
        // Handle overflow/underflow
        if (exp_r >= 255) begin
          result = {sign_r, 8'hff, 23'b0}; // Inf
        end else if (exp_r <= 0) begin
          result = {sign_r, 8'b0, mant_mul[22:0]}; // Denorm
        end else begin
          result = {sign_r, exp_r[7:0], mant_mul[22:0]};
        end
        single_mul = result;
      end
    end
  endfunction

  always @(*) begin
    result = 32'b0;
    if (prec == 1'b0) begin
      if (op == 1'b0)
        result = {16'b0, half_add(a[15:0], b[15:0])};
      else
        result = {16'b0, half_mul(a[15:0], b[15:0])};
    end else begin
      if (op == 1'b0)
        result = single_add(a, b);
      else
        result = single_mul(a, b);
    end
  end
endmodule
