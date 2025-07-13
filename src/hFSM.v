module hFSM(
  input clk,
  input reset,
  input [15:0] data,
  output reg [3:0] digit,
  output reg [3:0] anode
);
  reg [1:0] state = 0;

  always @(posedge clk or posedge reset) begin
    if (reset)
      state <= 0;
    else
      state <= state + 1;
  end

  always @(*)
    case (state)
      2'b00: begin
        anode = 4'b0111;
        digit = data[15:12];
      end
      2'b01: begin
        anode = 4'b1011;
        digit = data[11:8];
      end
      2'b10: begin
        anode = 4'b1101;
        digit = data[7:4];
      end
      2'b11: begin
        anode = 4'b1110;
        digit = data[3:0];
      end
      default: begin
        anode = 4'b1111;
        digit = 4'b0000;
      end 
    endcase
endmodule