`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// tiny_fpga_top : Basys-3 (Artix-7, 100 MHz) wrapper.
//
//  btnC      reset (clears PC/ACC/EXT/C-B/halted; register bank is kept)
//  btnL      load sw[7:0] into register number sw[11:8]   (do it with run=0)
//  sw[7:0]   data to load
//  sw[11:8]  register number: load target AND register shown on LED[7:0]
//  sw[12]    0 = LED[7:0] shows selected register,  1 = shows ACC
//  sw[13]    RUN  (1 = execute)
//  sw[14]    speed: 0 = ~2 instructions/s, 1 = full clock speed
//  LED[7:0]  selected register / ACC       LED[11:8] PC
//  LED[12]   C/B                           LED[13]   HALTED
//  LED[14]   EXT != 0                      LED[15]   heartbeat (instruction tick)
//
// Demo: reset, set sw[13]=1 -> program 0 runs, R7 = R5 + R6 (8+12 = 20).
//       Select sw[11:8]=0111 to see R7 = 0001 0100.
//------------------------------------------------------------------------------
module tiny_fpga_top #(
    parameter PROGRAM  = 0,
    parameter SLOW_DIV = 50_000_000,   // 100 MHz / 50e6 = 2 Hz
    parameter DEBOUNCE = 2_000_000
) (
    input  wire        clk,
    input  wire        btnC,
    input  wire        btnL,
    input  wire [15:0] sw,
    output wire [15:0] led
);
    // reset synchroniser
    reg r0 = 1'b1, r1 = 1'b1;
    always @(posedge clk) begin r0 <= btnC; r1 <= r0; end
    wire reset = r1;

    wire load_pulse;
    tiny_btn_pulse #(.DEBOUNCE(DEBOUNCE)) LOADBTN (.clk(clk), .btn(btnL), .pulse(load_pulse));

    // instruction tick generator
    reg [31:0] div = 32'd0;
    reg        slow_tick = 1'b0;
    reg        heartbeat = 1'b0;
    always @(posedge clk) begin
        if (div == SLOW_DIV - 1) begin div <= 32'd0; slow_tick <= 1'b1; heartbeat <= ~heartbeat; end
        else begin div <= div + 32'd1; slow_tick <= 1'b0; end
    end
    wire tick = sw[14] ? 1'b1 : slow_tick;
    wire run  = sw[13] & tick;

    wire [7:0] acc, ext, view_data, src_reg_out, instruction;
    wire       cb, halted;
    wire [3:0] pc;

    tiny_processor #(.PROGRAM(PROGRAM)) CPU (
        .clk(clk), .reset(reset), .run(run),
        .ld_we(load_pulse), .ld_addr(sw[11:8]), .ld_data(sw[7:0]),
        .view_addr(sw[11:8]), .view_data(view_data), .src_reg_out(src_reg_out),
        .acc(acc), .ext(ext), .cb(cb), .pc(pc),
        .instruction(instruction), .halted(halted)
    );

    assign led[7:0]  = sw[12] ? acc : view_data;
    assign led[11:8] = pc;
    assign led[12]   = cb;
    assign led[13]   = halted;
    assign led[14]   = |ext;
    assign led[15]   = heartbeat;
endmodule
