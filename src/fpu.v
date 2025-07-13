module Add16 (
  input wire [15:0] a, b,
  output reg [15:0] result
);
  // Deconstruct inputs
  wire sign_a = a[15];
  wire [4:0] exp_a = a[14:10];
  wire [9:0] mant_a = a[9:0];

  wire sign_b = b[15];
  wire [4:0] exp_b = b[14:10];
  wire [9:0] mant_b = b[9:0];

  // Internal registers for calculation
  reg sign_r;
  reg [4:0] exp_r;
  reg [10:0] mant_r;
  reg [11:0] mant_a_ext, mant_b_ext;
  reg [12:0] mant_sum;
  integer shift;

  always @(*) begin
    // Handle special cases: Zero
    if ((exp_a == 0 && mant_a == 0)) begin
      result = b;
    end else if ((exp_b == 0 && mant_b == 0)) begin
      result = a;
    end else begin
      // Add implicit 1 for normalized numbers
      mant_a_ext = (exp_a == 0) ? {1'b0, mant_a} : {1'b1, mant_a};
      mant_b_ext = (exp_b == 0) ? {1'b0, mant_b} : {1'b1, mant_b};

      // 1. Align exponents
      if (exp_a > exp_b) begin
        shift = exp_a - exp_b;
        mant_b_ext = mant_b_ext >> shift;
        exp_r = exp_a;
      end else begin
        shift = exp_b - exp_a;
        mant_a_ext = mant_a_ext >> shift;
        exp_r = exp_b;
      end

      // 2. Add or subtract mantissas based on sign
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

      // 3. Normalize the result
      if (mant_sum[12]) begin // Overflow on mantissa add
        mant_r = mant_sum[12:2];
        exp_r = exp_r + 1;
      end else if (mant_sum[11]) begin // Normal case
        mant_r = mant_sum[11:1];
      end else begin // Needs left shifting
        // This part handles denormalization after subtraction
        // A full implementation would require a loop or priority encoder
        // For simplicity, we handle a single shift normalization
        if(mant_sum != 0) begin
            while(mant_sum[10] == 0) begin
                mant_sum = mant_sum << 1;
                exp_r = exp_r - 1;
            end
        end
        mant_r = mant_sum[10:0];
      end
      
      // Handle underflow/overflow for exponent
      if (exp_r >= 31) begin
        result = {sign_r, 5'b11111, 10'b0}; // Infinity
      end else if (exp_r <= 0) begin
         result = {sign_r, 5'b0, mant_r}; // Denormalized or Zero
      end else begin
        result = {sign_r, exp_r, mant_r[9:0]}; // Normalized number
      end
    end
  end
endmodule

module Mul16 (
  input wire [15:0] a, b,
  output reg [15:0] result
);
  // Deconstruct inputs
  wire sign_a = a[15];
  wire [4:0] exp_a = a[14:10];
  wire [9:0] mant_a_in = a[9:0];

  wire sign_b = b[15];
  wire [4:0] exp_b = b[14:10];
  wire [9:0] mant_b_in = b[9:0];

  // Internal registers for calculation
  reg sign_r;
  reg signed [5:0] exp_r; // Use signed for bias subtraction
  reg [10:0] mant_a, mant_b;
  reg [21:0] mant_mul;

  always @(*) begin
    // Handle special cases: Zero
    if ((exp_a == 0 && mant_a_in == 0) || (exp_b == 0 && mant_b_in == 0)) begin
      result = 16'b0;
    end else begin
      // 1. Add implicit 1 for normalized numbers
      mant_a = (exp_a == 0) ? {1'b0, mant_a_in} : {1'b1, mant_a_in};
      mant_b = (exp_b == 0) ? {1'b0, mant_b_in} : {1'b1, mant_b_in};

      // 2. Multiply mantissas
      mant_mul = mant_a * mant_b;

      // 3. Add exponents and subtract bias (15)
      exp_r = exp_a + exp_b - 15;
      sign_r = sign_a ^ sign_b;

      // 4. Normalize the result
      if (mant_mul[21]) begin // Result has 22 bits, check MSB
        mant_mul = mant_mul >> 1;
        exp_r = exp_r + 1;
      end
      
      // Handle overflow/underflow for exponent
      if (exp_r >= 31) begin
        result = {sign_r, 5'b11111, 10'b0}; // Infinity
      end else if (exp_r <= 0) begin
        result = {sign_r, 5'b0, mant_mul[20:11]}; // Denormalized or Zero
      end else begin
        result = {sign_r, exp_r[4:0], mant_mul[20:11]}; // Normalized number
      end
    end
  end
endmodule

module Add32 (
  input wire [31:0] a, b,
  output reg [31:0] result
);
  // Deconstruct inputs
  wire sign_a = a[31];
  wire [7:0] exp_a = a[30:23];
  wire [22:0] mant_a = a[22:0];

  wire sign_b = b[31];
  wire [7:0] exp_b = b[30:23];
  wire [22:0] mant_b = b[22:0];

  // Internal registers for calculation
  reg sign_r;
  reg [7:0] exp_r;
  reg [23:0] mant_r;
  reg [24:0] mant_a_ext, mant_b_ext;
  reg [25:0] mant_sum;
  integer shift;

  always @(*) begin
    // Handle special cases: Zero
    if ((exp_a == 0 && mant_a == 0)) begin
      result = b;
    end else if ((exp_b == 0 && mant_b == 0)) begin
      result = a;
    end else begin
      // Add implicit 1 for normalized numbers
      mant_a_ext = (exp_a == 0) ? {1'b0, mant_a} : {1'b1, mant_a};
      mant_b_ext = (exp_b == 0) ? {1'b0, mant_b} : {1'b1, mant_b};

      // 1. Align exponents
      if (exp_a > exp_b) begin
        shift = exp_a - exp_b;
        mant_b_ext = mant_b_ext >> shift;
        exp_r = exp_a;
      end else begin
        shift = exp_b - exp_a;
        mant_a_ext = mant_a_ext >> shift;
        exp_r = exp_b;
      end

      // 2. Add or subtract mantissas
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
      
      // 3. Normalize the result
      if (mant_sum[25]) begin // Overflow on mantissa add
        mant_r = mant_sum[25:2];
        exp_r = exp_r + 1;
      end else if (mant_sum[24]) begin // Normal case
        mant_r = mant_sum[24:1];
      end else begin // Needs left shifting
        if(mant_sum != 0) begin
            while(mant_sum[23] == 0) begin
                mant_sum = mant_sum << 1;
                exp_r = exp_r - 1;
            end
        end
        mant_r = mant_sum[23:0];
      end

      // Handle underflow/overflow for exponent
      if (exp_r >= 255) begin
        result = {sign_r, 8'hFF, 23'b0}; // Infinity
      end else if (exp_r == 0) begin
        result = {sign_r, 8'b0, mant_r[22:0]}; // Denormalized or Zero
      end else begin
        result = {sign_r, exp_r, mant_r[22:0]}; // Normalized number
      end
    end
  end
endmodule

module Mul32 (
  input wire [31:0] a, b,
  output reg [31:0] result
);
  // Deconstruct inputs
  wire sign_a = a[31];
  wire [7:0] exp_a = a[30:23];
  wire [22:0] mant_a_in = a[22:0];

  wire sign_b = b[31];
  wire [7:0] exp_b = b[30:23];
  wire [22:0] mant_b_in = b[22:0];

  // Internal registers for calculation
  reg sign_r;
  reg signed [8:0] exp_r; // Use signed for bias subtraction
  reg [23:0] mant_a, mant_b;
  reg [47:0] mant_mul;

  always @(*) begin
    // Handle special cases: Zero
    if ((exp_a == 0 && mant_a_in == 0) || (exp_b == 0 && mant_b_in == 0)) begin
      result = 32'b0;
    end else begin
      // 1. Add implicit 1 for normalized numbers
      mant_a = (exp_a == 0) ? {1'b0, mant_a_in} : {1'b1, mant_a_in};
      mant_b = (exp_b == 0) ? {1'b0, mant_b_in} : {1'b1, mant_b_in};

      // 2. Multiply mantissas
      mant_mul = mant_a * mant_b;

      // 3. Add exponents and subtract bias (127)
      exp_r = exp_a + exp_b - 127;
      sign_r = sign_a ^ sign_b;

      // 4. Normalize the result
      if (mant_mul[47]) begin // Result has 48 bits, check MSB
        mant_mul = mant_mul >> 1;
        exp_r = exp_r + 1;
      end
      
      // Handle overflow/underflow for exponent
      if (exp_r >= 255) begin
        result = {sign_r, 8'hFF, 23'b0}; // Infinity
      end else if (exp_r <= 0) begin
        result = {sign_r, 8'b0, mant_mul[46:24]}; // Denormalized or Zero
      end else begin
        result = {sign_r, exp_r[7:0], mant_mul[46:24]}; // Normalized number
      end
    end
  end
endmodule