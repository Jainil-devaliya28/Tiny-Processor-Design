# Tiny 8-bit Accumulator Processor in Verilog

A small 8-bit accumulator processor written in Verilog-2001, with a modular RTL design, self-checking testbenches, and a Basys-3 FPGA wrapper. Built for the **ES204 Digital Systems** lab exam at IIT Gandhinagar.

- 16 x 8-bit register file, 8-bit accumulator (ACC), 8-bit EXT register, carry/borrow flag (C/B), 4-bit program counter
- 25 instructions (arithmetic, logic, shifts/rotates, compare, branch, move, halt)
- One instruction per clock cycle, PC incremented after every instruction
- 16-byte instruction ROM with four built-in test programs
- Every module has its own self-checking testbench, plus a system-level test


---

## Architecture



| Module | File | Role |
|---|---|---|
| `tiny_processor` | `rtl/tiny_processor.v` | Top level, wiring only |
| `tiny_instr_rom` | `rtl/tiny_instr_rom.v` | 16 x 8 program memory, `PROGRAM` parameter selects program 0-3 |
| `tiny_pc` | `rtl/tiny_pc.v` | 4-bit program counter (+1 or load branch target) |
| `tiny_control` | `rtl/tiny_control.v` | Decodes BR / RET / HLT / MOV Ri,ACC |
| `tiny_alu` | `rtl/tiny_alu.v` | Combinational ALU for all ACC / EXT / C-B updates |
| `tiny_state_regs` | `rtl/tiny_state_regs.v` | ACC, EXT and C/B registers |
| `tiny_register_file` | `rtl/tiny_register_file.v` | 16 x 8 bank, two read ports, CPU write port, external load port |
| `tiny_fpga_top` | `rtl/tiny_fpga_top.v` | Basys-3 wrapper (tick generator, button handling, LEDs) |
| `tiny_btn_pulse` | `rtl/tiny_btn_pulse.v` | Button synchroniser and debouncer |

The processor exposes `src_reg_out` (the register selected by the current instruction) as an output port, and a second independent read port (`view_addr` / `view_data`) for observing any register without hierarchical references.

---

## Instruction set

Instruction format: 8 bits, either `opcode[7:4] | register address[3:0]` or `opcode[7:0]` for operand-less instructions. Two-operand instructions use ACC and the register `Ri`, and write the result to ACC.

| Opcode | Mnemonic | Operation |
|---|---|---|
| `0000 0000` | NOP | No operation |
| `0001 xxxx` | ADD Ri | ACC = ACC + Ri; C/B = carry out |
| `0010 xxxx` | SUB Ri | ACC = ACC - Ri; C/B = borrow (ACC < Ri) |
| `0011 xxxx` | MUL Ri | {EXT, ACC} = ACC x Ri; C/B unchanged |
| `0000 0001` | LSL | Logical shift left ACC |
| `0000 0010` | LSR | Logical shift right ACC |
| `0000 0011` | CIR | Circular rotate right ACC |
| `0000 0100` | CIL | Circular rotate left ACC |
| `0000 0101` | ASR | Arithmetic shift right ACC |
| `0101 xxxx` | AND Ri | ACC = ACC AND Ri |
| `0110 xxxx` | XRA Ri | ACC = ACC XOR Ri |
| `0111 xxxx` | CMP Ri | C/B = (ACC < Ri); ACC unchanged |
| `0000 0110` | INC | ACC = ACC + 1; C/B set to 1 on overflow only |
| `0000 0111` | DEC | ACC = ACC - 1; C/B set to 1 on underflow only |
| `1000 xxxx` | BR a | PC = a if C/B = 1 |
| `1001 xxxx` | MOV ACC, Ri | ACC = Ri |
| `1010 xxxx` | MOV Ri, ACC | Ri = ACC |
| `1011 xxxx` | RET a | PC = a |
| `1111 1111` | HLT | Stop the processor |

Design decisions:
- ADD, SUB and CMP always update C/B. INC and DEC only set C/B when they overflow or underflow, following "updates C/B when overflows" in the specification.
- RET only loads the 4-bit address into the PC.
- Unused opcodes behave as NOP.
- The PC stops at the address of the HLT instruction.

---

## Built-in programs

Selected with the `PROGRAM` parameter of `tiny_processor` / `tiny_instr_rom`.

| # | Purpose | Expected result (default R5 = 8, R6 = 12) |
|---|---|---|
| 0 | Sample program: `MOV ACC,R1; XRA R1; ADD R5; ADD R6; MOV R7,ACC; HLT` | ACC = R7 = 20 |
| 1 | ISA test: shifts, INC/DEC, CMP, taken BR, AND, XRA, CIR/CIL, ASR | ACC = 2, R8 = 4, C/B = 1 |
| 2 | RET, SUB with borrow, BR not taken | ACC = R9 = 251, C/B = 1 |
| 3 | MUL: `MOV ACC,R5; MUL R6; MOV R7,ACC; HLT` | ACC = R7 = 96, EXT = 0 |

With R5 = 200 and R6 = 100 loaded through the external port, program 0 gives 44 with carry, and program 3 gives ACC = 0x20, EXT = 0x4E (20000).

---

## Repository layout

```
.
├── rtl/                 Synthesizable Verilog sources
├── sim/                 Self-checking testbenches
├── constraints/         basys3.xdc (pins + clock)
└── README.md
```

---

## Simulation

### Vivado

1. Create an RTL project (any part is fine for simulation).
2. Add all files in `rtl/` as Design Sources and all files in `sim/` as Simulation Sources.
3. Right-click the testbench you want, choose **Set as Top**, then **Run Simulation > Run Behavioral Simulation**.
4. Use **Run All** (`run all` in the Tcl console) and look for `PASS`.

Or create the whole project from the Tcl console:

```tcl
cd <path to this repository>
source scripts/create_vivado_project.tcl
```

### Icarus Verilog (command line)

```sh
sh scripts/run_sim.sh
```

### Testbenches

| Testbench | What it checks |
|---|---|
| `tb_tiny_alu` | Directed tests for every instruction, plus exhaustive ADD / SUB / MUL / CMP over all 65,536 operand pairs |
| `tb_tiny_register_file` | Power-up values, writes to all 16 registers, write-disable, external-port priority, dual reads |
| `tb_tiny_pc` | Reset, hold, increment, load, wrap-around |
| `tb_tiny_control` | All 512 combinations of instruction and C/B |
| `tb_tiny_processor` | Six processors in parallel running programs 0-3 (default and loaded operands), run gating, halt behaviour, reset and rerun |
| `tb_tiny_fpga_top` | Board wrapper with scaled-down dividers, including a button-driven register load |

All testbenches print `PASS` or `FAIL`. Saved output is in `results/`.

---

## FPGA (Basys-3)

1. Create a project for part `xc7a35tcpg236-1` (Artix-7). The included constraints target this board.
2. Add `rtl/*.v` as sources and `constraints/basys3.xdc` as the constraints file.
3. Set `tiny_fpga_top` as the top module, then run Synthesis, Implementation and Generate Bitstream.

### Controls

| Control | Function |
|---|---|
| `btnC` | Reset PC, ACC, EXT, C/B and halted flag (register bank is kept) |
| `btnL` | Write `sw[7:0]` into register `sw[11:8]` (do this with RUN off) |
| `sw[7:0]` | Data to load |
| `sw[11:8]` | Register number for load, and register shown on the LEDs |
| `sw[12]` | 0: LEDs show the selected register, 1: LEDs show ACC |
| `sw[13]` | RUN |
| `sw[14]` | 0: about 2 instructions per second, 1: full clock speed |

| LED | Meaning |
|---|---|
| `[7:0]` | Selected register or ACC |
| `[11:8]` | PC |
| `[12]` | C/B |
| `[13]` | Halted |
| `[14]` | EXT is non-zero |
| `[15]` | Heartbeat |

### Demo

1. Press `btnC` to reset, then set `sw[11:8] = 0111` (R7).
2. Raise `sw[13]` (RUN). At 2 Hz the PC steps 0 to 5 and R7 becomes `0001 0100` (20), and the halted LED lights.
3. To use other operands: switch RUN off, set `sw[11:8] = 0101`, put a value on `sw[7:0]`, press `btnL`; repeat for R6 (`0110`); press `btnC`; switch RUN on.

To use a different board, change the `PACKAGE_PIN` entries in `constraints/basys3.xdc` and the part in `scripts/create_vivado_project.tcl`.

---

## Known limitations

- The program ROM is 16 bytes (4-bit branch addresses) and is fixed at synthesis time. Changing a program means editing `tiny_instr_rom.v`.
- There is no division instruction, so EXT is only written by MUL.
- RET does not use a return-address stack.
- Constraints are written for a Basys-3. Hardware bring-up on other boards requires pin changes.

---
