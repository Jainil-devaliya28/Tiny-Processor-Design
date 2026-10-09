`timescale 1ns / 1ps
// 4-bit program counter: +1 per instruction, or load a branch/return target.
module tiny_pc (
    input  wire       clk,
    input  wire       reset,      // synchronous, active high
    input  wire       en,         // advance this cycle
    input  wire       load,       // load target instead of incrementing
    input  wire [3:0] target,
    output reg  [3:0] pc
);
    always @(posedge clk) begin
        if (reset)    pc <= 4'h0;
        else if (en)  pc <= load ? target : pc + 4'd1;
    end
endmodule
