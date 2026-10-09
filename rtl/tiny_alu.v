`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// tiny_alu : purely combinational ALU / ACC-update unit.
//   Handles every instruction that changes ACC, EXT or C/B:
//   ADD SUB MUL AND XRA CMP INC DEC LSL LSR CIR CIL ASR and MOV ACC,Ri.
//   Control-flow (BR/RET/HLT) and MOV Ri,ACC are handled in tiny_control.
//
// C/B conventions (per lab PDF):
//   ADD : C/B = carry out          SUB : C/B = borrow (ACC < Reg)
//   CMP : ACC >= Reg -> 0, else 1  (ACC is NOT modified by CMP)
//   INC : C/B set to 1 only when ACC overflows (FF -> 00), otherwise unchanged
//   DEC : C/B set to 1 only when ACC underflows (00 -> FF), otherwise unchanged
//   MUL : {EXT,ACC} = ACC * Reg, C/B unchanged
//   Shifts/rotates/AND/XRA/MOV : C/B unchanged
//------------------------------------------------------------------------------
module tiny_alu (
    input  wire [7:0] acc,
    input  wire [7:0] reg_data,
    input  wire [7:0] instruction,
    output reg  [7:0] result,
    output reg  [7:0] ext_result,
    output reg        cb_result,
    output reg        write_acc,
    output reg        write_ext,
    output reg        write_cb
);
    reg [8:0]  sum;
    reg [15:0] product;

    always @* begin
        result     = acc;
        ext_result = 8'h00;
        cb_result  = 1'b0;
        write_acc  = 1'b0;
        write_ext  = 1'b0;
        write_cb   = 1'b0;
        sum        = 9'h000;
        product    = 16'h0000;

        case (instruction[7:4])
            4'h1: begin                                  // ADD Ri
                sum       = {1'b0, acc} + {1'b0, reg_data};
                result    = sum[7:0];
                cb_result = sum[8];
                write_acc = 1'b1;
                write_cb  = 1'b1;
            end
            4'h2: begin                                  // SUB Ri
                result    = acc - reg_data;
                cb_result = (acc < reg_data);
                write_acc = 1'b1;
                write_cb  = 1'b1;
            end
            4'h3: begin                                  // MUL Ri
                product    = acc * reg_data;
                result     = product[7:0];
                ext_result = product[15:8];
                write_acc  = 1'b1;
                write_ext  = 1'b1;
            end
            4'h5: begin                                  // AND Ri
                result    = acc & reg_data;
                write_acc = 1'b1;
            end
            4'h6: begin                                  // XRA Ri
                result    = acc ^ reg_data;
                write_acc = 1'b1;
            end
            4'h7: begin                                  // CMP Ri (ACC unchanged)
                cb_result = (acc < reg_data);
                write_cb  = 1'b1;
            end
            4'h9: begin                                  // MOV ACC, Ri
                result    = reg_data;
                write_acc = 1'b1;
            end
            4'h0: begin
                case (instruction[3:0])
                    4'h1: begin result = {acc[6:0], 1'b0};     write_acc = 1'b1; end // LSL
                    4'h2: begin result = {1'b0, acc[7:1]};     write_acc = 1'b1; end // LSR
                    4'h3: begin result = {acc[0], acc[7:1]};   write_acc = 1'b1; end // CIR
                    4'h4: begin result = {acc[6:0], acc[7]};   write_acc = 1'b1; end // CIL
                    4'h5: begin result = {acc[7], acc[7:1]};   write_acc = 1'b1; end // ASR
                    4'h6: begin                                                      // INC
                        result    = acc + 8'd1;
                        write_acc = 1'b1;
                        if (acc == 8'hFF) begin cb_result = 1'b1; write_cb = 1'b1; end
                    end
                    4'h7: begin                                                      // DEC
                        result    = acc - 8'd1;
                        write_acc = 1'b1;
                        if (acc == 8'h00) begin cb_result = 1'b1; write_cb = 1'b1; end
                    end
                    default: begin end                                               // NOP
                endcase
            end
            default: begin end                           // BR, MOV Ri,ACC, RET, HLT: no ALU action
        endcase
    end
endmodule
