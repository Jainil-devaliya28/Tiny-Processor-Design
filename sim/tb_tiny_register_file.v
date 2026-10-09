`timescale 1ns / 1ps
module tb_tiny_register_file;
    reg clk = 0;
    reg we = 0, ext_we = 0;
    reg [3:0] waddr = 0, ext_waddr = 0, raddr = 0, vaddr = 0;
    reg [7:0] wdata = 0, ext_wdata = 0;
    wire [7:0] rdata, vdata;
    integer errors = 0, i;

    tiny_register_file dut (.clk(clk), .we(we), .waddr(waddr), .wdata(wdata),
        .ext_we(ext_we), .ext_waddr(ext_waddr), .ext_wdata(ext_wdata),
        .raddr(raddr), .rdata(rdata), .vaddr(vaddr), .vdata(vdata));

    always #5 clk = ~clk;

    task expect8(input [7:0] got, input [7:0] exp, input [8*24:1] msg);
        begin if (got !== exp) begin errors = errors + 1; $display("FAIL %0s: got %h exp %h", msg, got, exp); end end
    endtask

    initial begin
        // power-up values
        raddr = 5; vaddr = 6; #1;
        expect8(rdata, 8'd8,  "init R5"); expect8(vdata, 8'd12, "init R6");
        raddr = 1; #1; expect8(rdata, 8'hA5, "init R1");
        raddr = 0; #1; expect8(rdata, 8'h00, "init R0");

        // processor write, every register
        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk); we = 1; waddr = i; wdata = 8'h10 + i;
            @(negedge clk); we = 0;
            raddr = i; vaddr = i; #1;
            expect8(rdata, 8'h10 + i, "write/read A");
            expect8(vdata, 8'h10 + i, "write/read B");
        end
        // write disabled -> no change
        @(negedge clk); we = 0; waddr = 3; wdata = 8'hEE;
        @(negedge clk); raddr = 3; #1; expect8(rdata, 8'h13, "we=0 holds");
        // external port writes
        @(negedge clk); ext_we = 1; ext_waddr = 9; ext_wdata = 8'h5A;
        @(negedge clk); ext_we = 0; raddr = 9; #1; expect8(rdata, 8'h5A, "ext write");
        // external port has priority over processor port
        @(negedge clk); we = 1; waddr = 4; wdata = 8'h11; ext_we = 1; ext_waddr = 4; ext_wdata = 8'h22;
        @(negedge clk); we = 0; ext_we = 0; raddr = 4; #1; expect8(rdata, 8'h22, "ext priority");
        // two simultaneous independent reads
        raddr = 9; vaddr = 4; #1;
        expect8(rdata, 8'h5A, "dual read A"); expect8(vdata, 8'h22, "dual read B");

        $display("tb_tiny_register_file: %0d errors", errors);
        if (errors == 0) $display("tb_tiny_register_file: PASS"); else $display("tb_tiny_register_file: FAIL");
        $finish;
    end
endmodule
