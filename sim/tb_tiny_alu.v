`timescale 1ns / 1ps
// Self-checking testbench for tiny_alu (Verilog-2001).
module tb_tiny_alu;
    reg  [7:0] acc, reg_data, instruction;
    wire [7:0] result, ext_result;
    wire       cb_result, write_acc, write_ext, write_cb;
    integer errors = 0, tests = 0;

    tiny_alu dut (.acc(acc), .reg_data(reg_data), .instruction(instruction),
        .result(result), .ext_result(ext_result), .cb_result(cb_result),
        .write_acc(write_acc), .write_ext(write_ext), .write_cb(write_cb));

    // exp_flags = {write_acc, write_ext, write_cb}
    task check(input [8*10:1] name, input [7:0] i, input [7:0] a, input [7:0] r,
               input [7:0] exp_res, input [7:0] exp_ext, input exp_cb, input [2:0] exp_flags);
        begin
            instruction = i; acc = a; reg_data = r; #1;
            tests = tests + 1;
            if ({write_acc, write_ext, write_cb} !== exp_flags ||
                (write_acc && result !== exp_res) ||
                (write_ext && ext_result !== exp_ext) ||
                (write_cb  && cb_result !== exp_cb)) begin
                errors = errors + 1;
                $display("FAIL %0s: instr=%h acc=%h reg=%h -> res=%h ext=%h cb=%b wr(acc,ext,cb)=%b%b%b",
                    name, i, a, r, result, ext_result, cb_result, write_acc, write_ext, write_cb);
            end
        end
    endtask

    integer k;
    initial begin
        //            name     instr  acc   reg   res   ext  cb  {wacc,wext,wcb}
        check("NOP    ", 8'h00, 8'h55, 8'hAA, 8'h55, 8'h00, 0, 3'b000);
        check("ADD    ", 8'h15, 8'h08, 8'h0C, 8'h14, 8'h00, 0, 3'b101);
        check("ADD cy ", 8'h15, 8'hC8, 8'h64, 8'h2C, 8'h00, 1, 3'b101);
        check("ADD ff ", 8'h15, 8'hFF, 8'h01, 8'h00, 8'h00, 1, 3'b101);
        check("SUB    ", 8'h26, 8'h14, 8'h0C, 8'h08, 8'h00, 0, 3'b101);
        check("SUB eq ", 8'h26, 8'h0C, 8'h0C, 8'h00, 8'h00, 0, 3'b101);
        check("SUB bw ", 8'h26, 8'h08, 8'h0C, 8'hFC, 8'h00, 1, 3'b101);
        check("MUL    ", 8'h36, 8'h08, 8'h0C, 8'h60, 8'h00, 0, 3'b110);
        check("MUL hi ", 8'h36, 8'hC8, 8'h64, 8'h20, 8'h4E, 0, 3'b110);
        check("MUL ff ", 8'h36, 8'hFF, 8'hFF, 8'h01, 8'hFE, 0, 3'b110);
        check("AND    ", 8'h56, 8'hF0, 8'h3C, 8'h30, 8'h00, 0, 3'b100);
        check("XRA    ", 8'h66, 8'hF0, 8'h3C, 8'hCC, 8'h00, 0, 3'b100);
        check("XRA clr", 8'h61, 8'hA5, 8'hA5, 8'h00, 8'h00, 0, 3'b100);
        check("CMP >= ", 8'h76, 8'h0C, 8'h0C, 8'h00, 8'h00, 0, 3'b001);
        check("CMP >  ", 8'h76, 8'h20, 8'h0C, 8'h00, 8'h00, 0, 3'b001);
        check("CMP <  ", 8'h76, 8'h08, 8'h0C, 8'h00, 8'h00, 1, 3'b001);
        check("LSL    ", 8'h01, 8'hC1, 8'h00, 8'h82, 8'h00, 0, 3'b100);
        check("LSR    ", 8'h02, 8'h83, 8'h00, 8'h41, 8'h00, 0, 3'b100);
        check("CIR    ", 8'h03, 8'h81, 8'h00, 8'hC0, 8'h00, 0, 3'b100);
        check("CIL    ", 8'h04, 8'h81, 8'h00, 8'h03, 8'h00, 0, 3'b100);
        check("ASR neg", 8'h05, 8'h84, 8'h00, 8'hC2, 8'h00, 0, 3'b100);
        check("ASR pos", 8'h05, 8'h44, 8'h00, 8'h22, 8'h00, 0, 3'b100);
        check("INC    ", 8'h06, 8'h09, 8'h00, 8'h0A, 8'h00, 0, 3'b100);
        check("INC ovf", 8'h06, 8'hFF, 8'h00, 8'h00, 8'h00, 1, 3'b101);
        check("DEC    ", 8'h07, 8'h09, 8'h00, 8'h08, 8'h00, 0, 3'b100);
        check("DEC udf", 8'h07, 8'h00, 8'h00, 8'hFF, 8'h00, 1, 3'b101);
        check("MOV A,R", 8'h95, 8'h11, 8'h77, 8'h77, 8'h00, 0, 3'b100);
        check("MOV R,A", 8'hA7, 8'h11, 8'h77, 8'h11, 8'h00, 0, 3'b000); // no ALU action
        check("BR     ", 8'h89, 8'h11, 8'h77, 8'h11, 8'h00, 0, 3'b000);
        check("RET    ", 8'hB3, 8'h11, 8'h77, 8'h11, 8'h00, 0, 3'b000);
        check("HLT    ", 8'hFF, 8'h11, 8'h77, 8'h11, 8'h00, 0, 3'b000);
        check("undef  ", 8'h08, 8'h11, 8'h77, 8'h11, 8'h00, 0, 3'b000);
        check("undef2 ", 8'h40, 8'h11, 8'h77, 8'h11, 8'h00, 0, 3'b000);

        // exhaustive MUL / ADD / SUB / CMP checks against behavioural reference
        for (k = 0; k < 65536; k = k + 1) begin
            acc = k[15:8]; reg_data = k[7:0];
            instruction = 8'h36; #1; tests = tests + 1;
            if ({ext_result, result} !== acc * reg_data) begin errors = errors + 1; $display("FAIL MUL %0d*%0d", acc, reg_data); end
            instruction = 8'h15; #1; tests = tests + 1;
            if ({cb_result, result} !== {1'b0,acc} + {1'b0,reg_data}) begin errors = errors + 1; $display("FAIL ADD %0d+%0d", acc, reg_data); end
            instruction = 8'h26; #1; tests = tests + 1;
            if (result !== acc - reg_data || cb_result !== (acc < reg_data)) begin errors = errors + 1; $display("FAIL SUB %0d-%0d", acc, reg_data); end
            instruction = 8'h76; #1; tests = tests + 1;
            if (cb_result !== (acc < reg_data)) begin errors = errors + 1; $display("FAIL CMP %0d,%0d", acc, reg_data); end
        end

        $display("tb_tiny_alu: %0d checks, %0d errors", tests, errors);
        if (errors == 0) $display("tb_tiny_alu: PASS"); else $display("tb_tiny_alu: FAIL");
        $finish;
    end
endmodule
