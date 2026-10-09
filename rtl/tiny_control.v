`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// tiny_control : combinational instruction decoder for control-flow / register
// write.  (Data-path decode lives in tiny_alu.)
//   BR  <a> (8x) : PC <- a  if C/B = 1
//   RET <a> (Bx) : PC <- a  (the lab PDF only requires "PC is updated")
//   MOV Ri,ACC (Ax) : register write enable
//   HLT (FF)     : stop the processor
//------------------------------------------------------------------------------
module tiny_control (
    input  wire [7:0] instruction,
    input  wire       cb,
    output reg        reg_write,
    output reg        pc_load,
    output reg        halt,
    output wire [3:0] pc_target
);
    assign pc_target = instruction[3:0];

    always @* begin
        reg_write = 1'b0;
        pc_load   = 1'b0;
        halt      = 1'b0;
        case (instruction[7:4])
            4'h8: pc_load   = cb;
            4'hA: reg_write = 1'b1;
            4'hB: pc_load   = 1'b1;
            4'hF: halt      = (instruction == 8'hFF);
            default: begin end
        endcase
    end
endmodule
