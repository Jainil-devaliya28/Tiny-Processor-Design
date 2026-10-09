`timescale 1ns / 1ps
// Synchronise + debounce a push button and emit a one-clock pulse on press.
module tiny_btn_pulse #(parameter DEBOUNCE = 2_000_000) (   // 20 ms @ 100 MHz
    input  wire clk,
    input  wire btn,
    output wire pulse
);
    reg s0 = 1'b0, s1 = 1'b0, stable = 1'b0, stable_d = 1'b0;
    reg [31:0] cnt = 32'd0;
    always @(posedge clk) begin
        s0 <= btn;
        s1 <= s0;
        if (s1 == stable) cnt <= 32'd0;
        else if (cnt == DEBOUNCE - 1) begin stable <= s1; cnt <= 32'd0; end
        else cnt <= cnt + 32'd1;
        stable_d <= stable;
    end
    assign pulse = stable & ~stable_d;
endmodule
