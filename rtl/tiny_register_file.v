`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// 16 x 8-bit register bank.
//   * raddr/rdata : operand read port, driven by the instruction's register field
//                   (also exported as the "source register -> output port" of TH-4)
//   * vaddr/vdata : second, independent read port for board display/debug
//   * write port  : processor write (MOV Ri,ACC)
//   * ext port    : external load (switches on the FPGA board / testbench);
//                   has priority over the processor write port.
// No reset: contents survive a processor reset so operands loaded from the board
// are kept.  Power-up values come from the initial block (supported by Xilinx).
//------------------------------------------------------------------------------
module tiny_register_file (
    input  wire       clk,
    input  wire       we,
    input  wire [3:0] waddr,
    input  wire [7:0] wdata,
    input  wire       ext_we,
    input  wire [3:0] ext_waddr,
    input  wire [7:0] ext_wdata,
    input  wire [3:0] raddr,
    output wire [7:0] rdata,
    input  wire [3:0] vaddr,
    output wire [7:0] vdata
);
    reg [7:0] registers [0:15];
    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1) registers[i] = 8'h00;
        registers[1] = 8'hA5;   // junk: shows that XRA R1 really clears ACC
        registers[5] = 8'd8;
        registers[6] = 8'd12;
    end

    assign rdata = registers[raddr];
    assign vdata = registers[vaddr];

    always @(posedge clk) begin
        if (ext_we)    registers[ext_waddr] <= ext_wdata;
        else if (we)   registers[waddr]     <= wdata;
    end
endmodule
