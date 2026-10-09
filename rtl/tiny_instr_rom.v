`timescale 1ns / 1ps
//------------------------------------------------------------------------------
// 16 x 8-bit instruction ROM.  PROGRAM selects the stored program (so the
// testbench can instantiate several processors with different programs).
//   0 : PDF sample - R7 = R5 + R6                (default / FPGA demo)
//   1 : ISA test   - shifts, INC/DEC, CMP, BR(taken), AND, XRA, CIR/CIL, ASR
//   2 : RET + SUB-borrow + BR(not taken) test
//   3 : MUL test   - {EXT,ACC} = R5 * R6, R7 = low byte
//------------------------------------------------------------------------------
module tiny_instr_rom #(parameter PROGRAM = 0) (
    input  wire [3:0] addr,
    output reg  [7:0] data
);
    always @* begin
        data = 8'h00; // NOP
        case (PROGRAM)
        0: case (addr)
            4'h0: data = 8'h91; // MOV ACC, R1
            4'h1: data = 8'h61; // XRA R1        ; clears ACC
            4'h2: data = 8'h15; // ADD R5
            4'h3: data = 8'h16; // ADD R6        ; ACC = R5 + R6
            4'h4: data = 8'hA7; // MOV R7, ACC
            4'h5: data = 8'hFF; // HLT
            default: data = 8'h00;
        endcase
        1: case (addr)
            4'h0: data = 8'h95; // MOV ACC, R5   ; 8
            4'h1: data = 8'h01; // LSL           ; 16
            4'h2: data = 8'h02; // LSR           ; 8
            4'h3: data = 8'h06; // INC           ; 9
            4'h4: data = 8'h07; // DEC           ; 8
            4'h5: data = 8'h76; // CMP R6        ; 8 < 12 -> C/B = 1
            4'h6: data = 8'h89; // BR 9          ; taken
            4'h7: data = 8'h17; // ADD R7        ; (must be skipped)
            4'h8: data = 8'hFF; // HLT           ; (must be skipped)
            4'h9: data = 8'h56; // AND R6        ; 8 & 12 = 8
            4'hA: data = 8'h66; // XRA R6        ; 8 ^ 12 = 4
            4'hB: data = 8'h03; // CIR           ; 2
            4'hC: data = 8'h04; // CIL           ; 4
            4'hD: data = 8'hA8; // MOV R8, ACC   ; R8 = 4
            4'hE: data = 8'h05; // ASR           ; 2
            4'hF: data = 8'hFF; // HLT
        endcase
        2: case (addr)
            4'h0: data = 8'h95; // MOV ACC, R5   ; 8
            4'h1: data = 8'hB3; // RET 3         ; PC <- 3
            4'h2: data = 8'h06; // INC           ; (must be skipped)
            4'h3: data = 8'h16; // ADD R6        ; 20, C/B = 0
            4'h4: data = 8'h8F; // BR F          ; not taken (C/B = 0)
            4'h5: data = 8'h26; // SUB R6        ; 8, C/B = 0
            4'h6: data = 8'h26; // SUB R6        ; 252, borrow -> C/B = 1
            4'h7: data = 8'h07; // DEC           ; 251, C/B stays 1
            4'h8: data = 8'hA9; // MOV R9, ACC
            4'h9: data = 8'hFF; // HLT
            default: data = 8'h00;
        endcase
        3: case (addr)
            4'h0: data = 8'h95; // MOV ACC, R5
            4'h1: data = 8'h36; // MUL R6        ; {EXT,ACC} = R5*R6
            4'h2: data = 8'hA7; // MOV R7, ACC
            4'h3: data = 8'hFF; // HLT
            default: data = 8'h00;
        endcase
        default: data = 8'h00;
        endcase
    end
endmodule
