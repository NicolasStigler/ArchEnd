module top (
  clk,
  reset,
  anode,
  catode,
  state
);
  input wire clk;
  input wire reset;
  output wire [3:0] anode;
  output wire [7:0] catode;
  output wire [3:0] state;
  wire MemWrite;
  wire [31:0] Adr;
  wire [31:0] WriteData;
  wire [31:0] ReadData;
  wire RegWrite;
  wire [31:0] RegDisplay;
  reg [15:0] DisplayData;
  wire [3:0] Rd;
  // instantiate processor and shared memory
  arm arm(
    .clk(clk),
    .reset(reset),
    .MemWrite(MemWrite),
    .Adr(Adr),
    .WriteData(WriteData),
    .ReadData(ReadData),
    .RegWrite(RegWrite),
    .RegDisplay(RegDisplay),
    .Rd(Rd),
    .state(state)
  );
  mem mem(
    .clk(clk),
    .we(MemWrite),
    .a(Adr),
    .wd(WriteData),
    .rd(ReadData)
  );

  // instantiate display controller
  always @(posedge clk or posedge reset) begin
    if (reset) 
      DisplayData <= 16'b0; // reset display data
    else if (RegWrite & (Rd == 4'b1011)) // if register 11 is written to
      DisplayData <= RegDisplay[15:0];
  end

  hex_display hd(
    .clk(clk),
    .reset(reset),
    .data(DisplayData),
    .anode(anode),
    .catode(catode)
  );
endmodule
