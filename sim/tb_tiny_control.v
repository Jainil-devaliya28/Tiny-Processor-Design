`timescale 1ns / 1ps
module tb_tiny_control;
    reg [7:0] instruction; reg cb;
    wire reg_write, pc_load, halt; wire [3:0] pc_target;
    integer errors = 0, k;
    tiny_control dut (.instruction(instruction), .cb(cb), .reg_write(reg_write),
        .pc_load(pc_load), .halt(halt), .pc_target(pc_target));
    initial begin
        for (k = 0; k < 512; k = k + 1) begin
            instruction = k[7:0]; cb = k[8]; #1;
            if (reg_write !== (instruction[7:4] == 4'hA) ||
                pc_load   !== ((instruction[7:4] == 4'h8 && cb) || instruction[7:4] == 4'hB) ||
                halt      !== (instruction == 8'hFF) ||
                pc_target !== instruction[3:0]) begin
                errors = errors + 1;
                $display("FAIL instr=%h cb=%b -> rw=%b pl=%b h=%b tgt=%h", instruction, cb, reg_write, pc_load, halt, pc_target);
            end
        end
        $display("tb_tiny_control: %0d errors", errors);
        if (errors == 0) $display("tb_tiny_control: PASS"); else $display("tb_tiny_control: FAIL");
        $finish;
    end
endmodule
