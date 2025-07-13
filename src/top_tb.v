`timescale 1ns / 1ps

module testbench;
  reg clk;
  reg reset;
  wire [3:0] anode;
  wire [7:0] catode;
  wire [3:0] state;

  top dut(
    .clk(clk),
    .reset(reset),
    .anode(anode),
    .catode(catode),
    .state(state)
  );
  initial begin
    reset <= 1;
    #(5);
    reset <= 0;
  end
  always begin
    clk <= 1;
    #(5);
    clk <= 0;
    #(5);
  end
  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars;
  end
endmodule