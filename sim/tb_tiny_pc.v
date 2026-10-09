`timescale 1ns / 1ps
module tb_tiny_pc;
    reg clk = 0, reset = 1, en = 0, load = 0;
    reg [3:0] target = 0;
    wire [3:0] pc;
    integer errors = 0;
    tiny_pc dut (.clk(clk), .reset(reset), .en(en), .load(load), .target(target), .pc(pc));
    always #5 clk = ~clk;
    task chk(input [3:0] exp, input [8*20:1] msg);
        begin #1; if (pc !== exp) begin errors = errors + 1; $display("FAIL %0s: pc=%h exp=%h", msg, pc, exp); end end
    endtask
    initial begin
        @(negedge clk); chk(4'h0, "reset");
        reset = 0;
        @(negedge clk); chk(4'h0, "en=0 holds");
        en = 1;
        @(negedge clk); chk(4'h1, "inc 1");
        @(negedge clk); chk(4'h2, "inc 2");
        load = 1; target = 4'h9;
        @(negedge clk); chk(4'h9, "load 9");
        load = 0;
        @(negedge clk); chk(4'hA, "inc after load");
        load = 1; target = 4'hF;
        @(negedge clk); chk(4'hF, "load F");
        load = 0;
        @(negedge clk); chk(4'h0, "wrap F->0");
        en = 0;
        @(negedge clk); chk(4'h0, "hold");
        en = 1; @(negedge clk); en = 0; reset = 1;
        @(negedge clk); chk(4'h0, "sync reset wins");
        $display("tb_tiny_pc: %0d errors", errors);
        if (errors == 0) $display("tb_tiny_pc: PASS"); else $display("tb_tiny_pc: FAIL");
        $finish;
    end
endmodule
