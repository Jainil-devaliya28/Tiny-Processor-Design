`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// System-level self-checking testbench.  Six processors run side by side:
//   d0 : program 0 (PDF sample, R7 = R5+R6) with default R5=8,  R6=12
//   d1 : program 1 (ISA test)
//   d2 : program 2 (RET / SUB-borrow / BR-not-taken)
//   d3 : program 3 (MUL) with default operands
//   d4 : program 0 after loading R5=200, R6=100 through the external port (carry)
//   d5 : program 3 after loading R5=200, R6=100 (16-bit product in {EXT,ACC})
// Also checks run=0 gating and halt behaviour.  Writes sample_trace.csv.
//------------------------------------------------------------------------------
module tb_tiny_processor;
    reg clk = 0, reset = 1, run = 0;
    reg        ld_we = 0;
    reg [3:0]  ld_addr = 0;
    reg [7:0]  ld_data = 0;
    reg [3:0]  view = 4'd7;
    integer errors = 0, cyc = 0, fd;

    wire [7:0] acc0, acc1, acc2, acc3, acc4, acc5;
    wire [7:0] ext0, ext1, ext2, ext3, ext4, ext5;
    wire       cb0, cb1, cb2, cb3, cb4, cb5;
    wire [3:0] pc0, pc1, pc2, pc3, pc4, pc5;
    wire       h0, h1, h2, h3, h4, h5;
    wire [7:0] v0, v1, v2, v3, v4, v5, s0, s1, s2, s3, s4, s5, i0, i1, i2, i3, i4, i5;
    wire [7:0] r8_1, r9_2;

    tiny_processor #(.PROGRAM(0)) d0 (.clk(clk), .reset(reset), .run(run), .ld_we(1'b0), .ld_addr(4'd0), .ld_data(8'd0),
        .view_addr(view), .view_data(v0), .src_reg_out(s0), .acc(acc0), .ext(ext0), .cb(cb0), .pc(pc0), .instruction(i0), .halted(h0));
    tiny_processor #(.PROGRAM(1)) d1 (.clk(clk), .reset(reset), .run(run), .ld_we(1'b0), .ld_addr(4'd0), .ld_data(8'd0),
        .view_addr(4'd8), .view_data(r8_1), .src_reg_out(s1), .acc(acc1), .ext(ext1), .cb(cb1), .pc(pc1), .instruction(i1), .halted(h1));
    tiny_processor #(.PROGRAM(2)) d2 (.clk(clk), .reset(reset), .run(run), .ld_we(1'b0), .ld_addr(4'd0), .ld_data(8'd0),
        .view_addr(4'd9), .view_data(r9_2), .src_reg_out(s2), .acc(acc2), .ext(ext2), .cb(cb2), .pc(pc2), .instruction(i2), .halted(h2));
    tiny_processor #(.PROGRAM(3)) d3 (.clk(clk), .reset(reset), .run(run), .ld_we(1'b0), .ld_addr(4'd0), .ld_data(8'd0),
        .view_addr(view), .view_data(v3), .src_reg_out(s3), .acc(acc3), .ext(ext3), .cb(cb3), .pc(pc3), .instruction(i3), .halted(h3));
    tiny_processor #(.PROGRAM(0)) d4 (.clk(clk), .reset(reset), .run(run), .ld_we(ld_we), .ld_addr(ld_addr), .ld_data(ld_data),
        .view_addr(view), .view_data(v4), .src_reg_out(s4), .acc(acc4), .ext(ext4), .cb(cb4), .pc(pc4), .instruction(i4), .halted(h4));
    tiny_processor #(.PROGRAM(3)) d5 (.clk(clk), .reset(reset), .run(run), .ld_we(ld_we), .ld_addr(ld_addr), .ld_data(ld_data),
        .view_addr(view), .view_data(v5), .src_reg_out(s5), .acc(acc5), .ext(ext5), .cb(cb5), .pc(pc5), .instruction(i5), .halted(h5));

    always #5 clk = ~clk;

    task chk8(input [7:0] got, input [7:0] exp, input [8*28:1] msg);
        begin if (got !== exp) begin errors = errors + 1; $display("FAIL %0s: got %0d (0x%h) expected %0d (0x%h)", msg, got, got, exp, exp); end end
    endtask
    task chk1(input got, input exp, input [8*28:1] msg);
        begin if (got !== exp) begin errors = errors + 1; $display("FAIL %0s: got %b expected %b", msg, got, exp); end end
    endtask

    // trace of d0 (sample program) : one line per executed instruction
    initial begin
        fd = $fopen("sample_trace.csv", "w");
        $fdisplay(fd, "cycle,pc,instr,acc,cb,r7_after");
    end
    always @(posedge clk) if (!reset && run && !h0) begin
        cyc = cyc + 1;
        $display("cycle %0d: PC=%0d INSTR=%h ACC=%0d C/B=%b", cyc, pc0, i0, acc0, cb0);
        $fdisplay(fd, "%0d,%0d,%h,%0d,%b,%0d", cyc, pc0, i0, acc0, cb0, v0);
    end

    initial begin
        $display("Starting Tiny Processor system test");
        repeat (3) @(posedge clk);
        // load operands into d4/d5 with run=0
        @(negedge clk); ld_we = 1; ld_addr = 4'd5; ld_data = 8'd200;
        @(negedge clk); ld_addr = 4'd6; ld_data = 8'd100;
        @(negedge clk); ld_we = 0;
        // run=0 gating: nothing may move while run=0
        reset = 0;
        repeat (5) @(posedge clk); #1;
        chk8(pc0, 0, "pc held while run=0"); chk8(acc0, 0, "acc held while run=0"); chk1(h0, 0, "not halted while run=0");
        // go
        @(negedge clk); run = 1;
        repeat (40) @(posedge clk); #1;

        // ---- d0 : R7 = R5 + R6 = 20 -----------------------------------------
        view = 4'd7; #1;
        chk8(acc0, 8'd20, "d0 ACC"); chk8(v0, 8'd20, "d0 R7"); chk1(cb0, 0, "d0 C/B"); chk1(h0, 1, "d0 halted");
        chk8(pc0, 8'd5, "d0 PC stops at HLT");
        // ---- d1 : ISA test --------------------------------------------------
        chk8(acc1, 8'd2, "d1 ACC"); chk8(r8_1, 8'd4, "d1 R8"); chk1(cb1, 1, "d1 C/B (CMP)"); chk1(h1, 1, "d1 halted");
        chk8(pc1, 8'd15, "d1 PC (HLT at F)");
        // ---- d2 : RET / SUB borrow / BR not taken ---------------------------
        chk8(acc2, 8'd251, "d2 ACC"); chk8(r9_2, 8'd251, "d2 R9"); chk1(cb2, 1, "d2 C/B"); chk1(h2, 1, "d2 halted");
        chk8(pc2, 8'd9, "d2 PC");
        // ---- d3 : MUL 8*12 = 96 -------------------------------------------
        chk8(acc3, 8'd96, "d3 ACC"); chk8(ext3, 8'd0, "d3 EXT"); chk8(v3, 8'd96, "d3 R7"); chk1(h3, 1, "d3 halted");
        // ---- d4 : 200 + 100 = 300 -> 44, carry ----------------------------
        chk8(acc4, 8'd44, "d4 ACC"); chk8(v4, 8'd44, "d4 R7"); chk1(cb4, 1, "d4 C/B carry"); chk1(h4, 1, "d4 halted");
        // ---- d5 : 200 * 100 = 20000 = 0x4E20 -------------------------------
        chk8(acc5, 8'h20, "d5 ACC"); chk8(ext5, 8'h4E, "d5 EXT"); chk8(v5, 8'h20, "d5 R7"); chk1(h5, 1, "d5 halted");

        // ---- halted processors must not move even though run=1 -------------
        repeat (5) @(posedge clk); #1;
        chk8(acc0, 8'd20, "d0 ACC stable after HLT"); chk8(pc0, 8'd5, "d0 PC stable after HLT");

        // ---- reset restarts the program; register bank content is kept ----
        @(negedge clk); reset = 1;
        @(negedge clk); #1;
        chk8(pc0, 0, "reset PC"); chk8(acc0, 0, "reset ACC"); chk1(h0, 0, "reset halted"); chk8(v0, 8'd20, "R7 kept over reset");
        @(negedge clk); reset = 0;
        repeat (20) @(posedge clk); #1;
        chk8(acc0, 8'd20, "d0 ACC after rerun"); chk1(h0, 1, "d0 halted after rerun");

        $fclose(fd);
        $display("--------------------------------------------------");
        $display("tb_tiny_processor: %0d errors", errors);
        if (errors == 0) $display("tb_tiny_processor: PASS: all programs verified"); else $display("tb_tiny_processor: FAIL");
        $finish;
    end

    initial begin #20000; $display("TIMEOUT"); $finish; end
endmodule
