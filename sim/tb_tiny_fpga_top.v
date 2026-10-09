`timescale 1ns / 1ps
// Board-wrapper test with scaled-down dividers (fast to simulate).
module tb_tiny_fpga_top;
    reg clk = 0, btnC = 1, btnL = 0;
    reg [15:0] sw = 16'h0000;
    wire [15:0] led;
    integer errors = 0;

    tiny_fpga_top #(.PROGRAM(0), .SLOW_DIV(8), .DEBOUNCE(4)) dut (.clk(clk), .btnC(btnC), .btnL(btnL), .sw(sw), .led(led));
    always #5 clk = ~clk;

    task chk(input [15:0] got, input [15:0] exp, input [8*28:1] msg);
        begin if (got !== exp) begin errors = errors + 1; $display("FAIL %0s: got %h exp %h", msg, got, exp); end end
    endtask

    initial begin
        repeat (6) @(posedge clk);
        btnC = 0; sw[11:8] = 4'd7;                      // view R7
        repeat (10) @(posedge clk); #1;
        chk(led[13], 0, "not halted before run"); chk(led[7:0], 8'd0, "R7 = 0 before run");
        sw[13] = 1;                                     // RUN, slow speed
        repeat (200) @(posedge clk); #1;
        chk(led[13], 1, "halted after run");
        chk(led[7:0], 8'd20, "R7 = 20 on LEDs");
        sw[12] = 1; #1; chk(led[7:0], 8'd20, "ACC = 20 on LEDs"); sw[12] = 0;
        chk(led[11:8], 4'd5, "PC = 5 (HLT)");
        // reload R5 := 100 using the button, rerun at full speed
        sw[13] = 0; btnC = 1; repeat (4) @(posedge clk); btnC = 0;
        sw[11:8] = 4'd5; sw[7:0] = 8'd100;
        btnL = 1; repeat (12) @(posedge clk); btnL = 0; repeat (12) @(posedge clk);
        sw[11:8] = 4'd5; #1; chk(led[7:0], 8'd100, "R5 loaded = 100");
        sw[11:8] = 4'd7; sw[14] = 1; sw[13] = 1;
        repeat (30) @(posedge clk); #1;
        chk(led[7:0], 8'd112, "R7 = 100 + 12");
        chk(led[13], 1, "halted again");
        $display("tb_tiny_fpga_top: %0d errors", errors);
        if (errors == 0) $display("tb_tiny_fpga_top: PASS"); else $display("tb_tiny_fpga_top: FAIL");
        $finish;
    end
endmodule
