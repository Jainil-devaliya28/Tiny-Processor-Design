`timescale 1ns / 1ps
// Accumulator, EXT (high byte of MUL) and C/B (carry/borrow) flag.
// These are separate from the register bank, as required by the lab PDF.
module tiny_state_regs (
    input  wire       clk,
    input  wire       reset,
    input  wire       acc_we,
    input  wire [7:0] acc_d,
    input  wire       ext_we,
    input  wire [7:0] ext_d,
    input  wire       cb_we,
    input  wire       cb_d,
    output reg  [7:0] acc,
    output reg  [7:0] ext,
    output reg        cb
);
    always @(posedge clk) begin
        if (reset) begin
            acc <= 8'h00;
            ext <= 8'h00;
            cb  <= 1'b0;
        end else begin
            if (acc_we) acc <= acc_d;
            if (ext_we) ext <= ext_d;
            if (cb_we)  cb  <= cb_d;
        end
    end
endmodule
