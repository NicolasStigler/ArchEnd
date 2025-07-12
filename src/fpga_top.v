module fpga_top(
    input wire CLK,
    input wire [15:0] SW,
    input wire [4:0] BTN,
    output wire [15:0] LED
);
    // Registers for instruction halves
    reg [15:0] instr_lo = 0;
    reg [15:0] instr_hi = 0;
    reg half_sel = 0; // 0: low, 1: high
    reg [31:0] instr = 0;
    reg latched = 0;

    // Button debounce (simple)
    reg btn0_last = 0;
    reg btn1_last = 0;

    always @(posedge CLK) begin
        // BTN[0]: toggle half_sel
        if (BTN[0] && !btn0_last)
            half_sel <= ~half_sel;
        btn0_last <= BTN[0];

        // BTN[1]: latch current half
        if (BTN[1] && !btn1_last) begin
            if (!half_sel)
                instr_lo <= SW;
            else
                instr_hi <= SW;
            latched <= 1;
        end else begin
            latched <= 0;
        end
        btn1_last <= BTN[1];

        // Combine halves
        instr <= {instr_hi, instr_lo};
    end

    // Connect to processor
    wire clk = CLK;
    wire reset = BTN[4];
    wire [31:0] WriteData, Adr;
    wire MemWrite;
    top dut(
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .Adr(Adr),
        .MemWrite(MemWrite)
        // You may need to connect instr to your processor's instruction input if you want manual loading
    );

    // LED feedback: show which half is selected and latched
    assign LED[0] = half_sel; // 0: low, 1: high
    assign LED[1] = latched;
    assign LED[15:2] = instr[13:0]; // Show lower bits of instruction for feedback
endmodule
