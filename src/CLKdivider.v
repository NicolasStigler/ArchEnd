module CLKdivider(
  input wire clk, 
  input wire reset,
  output reg t
);
  reg [23:0] counter = 1;
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      t <= 0;
      counter <= 0;
    end
    else begin
      counter <= counter + 1;
      if (counter == 0)
        t <= ~t;
    end
  end
endmodule