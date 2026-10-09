`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// tiny_processor : top-level "Tiny" processor (structural wiring only).
//
//   tiny_instr_rom --> tiny_control --> tiny_pc
//                  \-> tiny_alu <--> tiny_state_regs (ACC, EXT, C/B)
//                        ^
//                  tiny_register_file (16 x 8)
//
// One instruction per clock while run=1 and the processor is not halted.
// reset is synchronous; it clears PC/ACC/EXT/C-B/halted but not the register bank.
//------------------------------------------------------------------------------
module tiny_processor #(parameter PROGRAM = 0) (
    input  wire       clk,
    input  wire       reset,
    input  wire       run,          // 1 = execute one instruction this clock
    // external register load (board switches / testbench)
    input  wire       ld_we,
    input  wire [3:0] ld_addr,
    input  wire [7:0] ld_data,
    // observation
    input  wire [3:0] view_addr,
    output wire [7:0] view_data,    // any register, selectable
    output wire [7:0] src_reg_out,  // register named by the current instruction
    output wire [7:0] acc,
    output wire [7:0] ext,
    output wire       cb,
    output wire [3:0] pc,
    output wire [7:0] instruction,
    output reg        halted
);
    wire [7:0] reg_data;
    wire [7:0] alu_result, alu_ext_result;
    wire       alu_cb_result, alu_write_acc, alu_write_ext, alu_write_cb;
    wire       ctl_reg_write, ctl_pc_load, ctl_halt;
    wire [3:0] ctl_pc_target;

    wire step = run & ~halted;

    tiny_instr_rom #(.PROGRAM(PROGRAM)) ROM (.addr(pc), .data(instruction));

    tiny_control CTL (
        .instruction(instruction), .cb(cb),
        .reg_write(ctl_reg_write), .pc_load(ctl_pc_load),
        .halt(ctl_halt), .pc_target(ctl_pc_target)
    );

    tiny_pc PC (
        .clk(clk), .reset(reset),
        .en(step & ~ctl_halt), .load(ctl_pc_load), .target(ctl_pc_target),
        .pc(pc)
    );

    tiny_register_file RF (
        .clk(clk),
        .we(step & ctl_reg_write), .waddr(instruction[3:0]), .wdata(acc),
        .ext_we(ld_we), .ext_waddr(ld_addr), .ext_wdata(ld_data),
        .raddr(instruction[3:0]), .rdata(reg_data),
        .vaddr(view_addr), .vdata(view_data)
    );
    assign src_reg_out = reg_data;

    tiny_alu ALU (
        .acc(acc), .reg_data(reg_data), .instruction(instruction),
        .result(alu_result), .ext_result(alu_ext_result), .cb_result(alu_cb_result),
        .write_acc(alu_write_acc), .write_ext(alu_write_ext), .write_cb(alu_write_cb)
    );

    tiny_state_regs STATE (
        .clk(clk), .reset(reset),
        .acc_we(step & alu_write_acc), .acc_d(alu_result),
        .ext_we(step & alu_write_ext), .ext_d(alu_ext_result),
        .cb_we (step & alu_write_cb),  .cb_d (alu_cb_result),
        .acc(acc), .ext(ext), .cb(cb)
    );

    always @(posedge clk) begin
        if (reset)                halted <= 1'b0;
        else if (step & ctl_halt) halted <= 1'b1;
    end
endmodule
