# Simple RISC Processor in Verilog

A compact, accumulator-based RISC processor implemented in Verilog HDL. The design demonstrates the core principles of CPU organization, including instruction fetch, instruction decode, arithmetic and logic execution, memory access, program-counter control, and finite-state-machine-based control.

This repository contains the RTL source code, module-level testbenches, CPU integration testbenches, a Python-based simulation runner, waveform-oriented verification assets, and a LaTeX project report.

---

## Table of Contents

- [Simple RISC Processor in Verilog](#simple-risc-processor-in-verilog)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Architecture](#architecture)
  - [Instruction Set](#instruction-set)
  - [Repository Structure](#repository-structure)
  - [Modules](#modules)
    - [`PC.v` - Program Counter](#pcv---program-counter)
    - [`ADD_MUX.v` - Address Multiplexer](#add_muxv---address-multiplexer)
    - [`Memory.v` - Memory](#memoryv---memory)
    - [`IR.v` - Instruction Register](#irv---instruction-register)
    - [`AC.v` - Accumulator](#acv---accumulator)
    - [`ALU.v` - Arithmetic Logic Unit](#aluv---arithmetic-logic-unit)
    - [`Controller.v` - Control Unit](#controllerv---control-unit)
    - [`CPU.v` - Top-Level Processor](#cpuv---top-level-processor)
  - [Requirements](#requirements)
  - [Getting Started](#getting-started)
  - [Running Tests](#running-tests)
  - [Waveform Simulation](#waveform-simulation)
  - [Verification Coverage](#verification-coverage)
  - [Documentation](#documentation)
  - [Limitations](#limitations)
  - [License](#license)

---

## Overview

The processor uses an 8-bit instruction format composed of a 3-bit opcode and a 5-bit operand field. This format supports eight instructions and provides access to a 32-location memory space. The datapath is built around an 8-bit accumulator register, an 8-bit bidirectional data bus, a 5-bit program counter, and a 32 × 8-bit memory.

The CPU operates synchronously with a clock signal and an active-high reset signal. Program execution continues until the `HLT` instruction is decoded and the controller asserts the `halt` signal.

Key characteristics:

- 8-bit instruction width
- 3-bit opcode and 5-bit operand
- 8 supported instructions
- 32-address memory space
- 8-bit accumulator-based datapath
- Multi-cycle instruction execution
- 8-state controller finite state machine
- Modular RTL implementation
- Unit and integration testbenches
- Automated simulation runner for Icarus Verilog and Vivado Simulator

---

## Architecture

The top-level processor is implemented in `src/CPU.v` and integrates the following components:

```text
              +----------------+
              |   Controller   |
              +----------------+
                 | control signals
                 v

+------+     +-------------+     +----------+
|  PC  | --> | Address MUX | --> |  Memory  |
+------+     +-------------+     +----------+
                                  ^      |
                                  |      v
                              +----------------+
                              | Instruction IR |
                              +----------------+
                                  | opcode / operand
                                  v
+--------------+     +------+     +------------+
| Accumulator  | --> | ALU  | --> | Accumulator|
+--------------+     +------+     +------------+
```

The CPU execution flow is divided into two main phases:

1. **Instruction Fetch Phase**
   - `INST_ADDR`
   - `INST_FETCH`
   - `INST_LOAD`
   - `IDLE`

2. **Execution Phase**
   - `OP_ADDR`
   - `OP_FETCH`
   - `ALU_OP`
   - `STORE`

A standard instruction is executed over these eight controller states. Control-flow instructions such as `SKZ`, `JMP`, and `HLT` update the program counter or halt state according to the opcode and ALU zero flag.

---

## Instruction Set

| Opcode | Mnemonic | Description | ALU Output |
|---|---:|---|---|
| `000` | `HLT` | Halt processor execution | `inA` |
| `001` | `SKZ` | Skip next instruction when the accumulator is zero | `inA` |
| `010` | `ADD` | Add memory operand to accumulator | `inA + inB` |
| `011` | `AND` | Bitwise AND between accumulator and memory operand | `inA & inB` |
| `100` | `XOR` | Bitwise XOR between accumulator and memory operand | `inA ^ inB` |
| `101` | `LDA` | Load memory operand into accumulator | `inB` |
| `110` | `STO` | Store accumulator value into memory | `inA` |
| `111` | `JMP` | Jump to operand address | `inA` |

Instruction format:

```text
bit[7:5]  opcode
bit[4:0]  operand / address
```

Example program:

```assembly
LDA 20    ; AC <- MEM[20]
ADD 21    ; AC <- AC + MEM[21]
STO 22    ; MEM[22] <- AC
HLT       ; Stop execution
```

---

## Repository Structure

```text
.
├── src/
│   ├── AC.v
│   ├── ADD_MUX.v
│   ├── ALU.v
│   ├── CPU.v
│   ├── Controller.v
│   ├── IR.v
│   ├── Memory.v
│   └── PC.v
├── testbench/
│   ├── run_tests.py
│   ├── test_001/
│   │   ├── PC_tb.v
│   │   └── expected.txt
│   ├── test_002/
│   │   ├── AM_tb.v
│   │   └── expected.txt
│   ├── test_003/
│   │   ├── ALU_tb.v
│   │   └── expected.txt
│   ├── test_004/
│   │   ├── Controller_tb.v
│   │   └── expected.txt
│   ├── test_005/
│   │   ├── IR_tb.v
│   │   └── expected.txt
│   ├── test_006/
│   │   ├── AC_tb.v
│   │   └── expected.txt
│   ├── test_007/
│   │   ├── Memory_tb.v
│   │   └── expected.txt
│   ├── test_008/
│   │   ├── CPU_tb.v
│   │   └── expected.txt
│   ├── test_009/
│   │   ├── CPU2_tb.v
│   │   └── expected.txt
│   └── test_010/
│       └── CPU_tb_wave.v
├── report/
│   ├── chapters/
│   ├── figures/
│   ├── riscReport.tex
│   └── riscReport.pdf
├── flake.nix
├── flake.lock
├── run_tests.py
└── README.md
```

---

## Modules

### `PC.v` - Program Counter

The program counter stores the address of the current instruction. It supports reset, address loading, and increment operations.

Priority order:

```text
rst > ld_pc > inc_pc > hold
```

### `ADD_MUX.v` - Address Multiplexer

The address multiplexer selects the source address for memory access:

- `sel = 1`: select program counter address
- `sel = 0`: select instruction operand address

The module is parameterized through `WIDTH`.

### `Memory.v` - Memory

The memory module provides a 32 × 8-bit storage array with a single bidirectional data port. Read and write operations are controlled by `rd` and `wr`.

- Read: `rd = 1`, `wr = 0`
- Write: `rd = 0`, `wr = 1`
- High impedance: otherwise

### `IR.v` - Instruction Register

The instruction register stores the current 8-bit instruction and separates it into:

- `opcode = instruction[7:5]`
- `operand = instruction[4:0]`

### `AC.v` - Accumulator

The accumulator stores the main working data value of the CPU. It receives ALU output when `ld_ac` is asserted.

### `ALU.v` - Arithmetic Logic Unit

The ALU performs arithmetic, logic, and data-transfer operations based on the opcode. It also generates the `zero` flag based on whether the accumulator input is zero.

### `Controller.v` - Control Unit

The controller is implemented as an 8-state finite state machine. It generates all datapath control signals, including memory read/write, instruction loading, accumulator loading, program-counter increment/loading, bus enable, and halt control.

### `CPU.v` - Top-Level Processor

The top-level CPU connects the datapath modules and controller into a complete processor system. It exposes the following interface:

```verilog
module CPU (
    input  clk,
    input  rst,
    output halt
);
```

---

## Requirements

At least one Verilog simulator is required:

- [Icarus Verilog](https://steveicarus.github.io/iverilog/) for `iverilog` and `vvp`
- AMD/Xilinx Vivado Simulator for `xvlog`, `xelab`, and `xsim`

Python is also required for the automated test runner.

Optional development environment:

- Nix with flakes enabled
- The provided `flake.nix` defines a development shell containing Verilog, Python, and LaTeX-related tooling.

---

## Getting Started

Clone the repository:

```bash
git clone <repository-url>
cd Verilog-Simple-Risc-Processor
```

If Nix is available, enter the development shell:

```bash
nix develop .#risc
```

Alternatively, install the required tools manually:

```bash
# Ubuntu/Debian example
sudo apt update
sudo apt install iverilog python3
```

---

## Running Tests

The repository includes an automated Python test runner that can use either Icarus Verilog or Vivado Simulator.

Run all testbenches with simulator auto-detection:

```bash
python run_tests.py --src src --testbench testbench
```

Run all tests with Icarus Verilog:

```bash
python run_tests.py --src src --testbench testbench --sim icarus
```

Run all tests with Vivado Simulator:

```bash
python run_tests.py --src src --testbench testbench --sim vivado
```

Run selected tests only:

```bash
python run_tests.py --src src --testbench testbench --filter test_001 test_008
```

Use loose output comparison:

```bash
python run_tests.py --src src --testbench testbench --loose
```

For Vivado installations that are not available through `PATH`, specify the Vivado binary directory:

```bash
python run_tests.py --src src --testbench testbench --sim vivado --vivado-bin "C:/Xilinx/Vivado/2024.2/bin"
```

---

## Waveform Simulation

The waveform-oriented CPU integration testbench is located at:

```text
testbench/test_010/CPU_tb_wave.v
```

This testbench is intended for signal inspection and waveform debugging. It exposes internal CPU signals as top-level aliases and generates waveform output.

Example using Icarus Verilog:

```bash
iverilog -g2005 -o CPU_tb_wave.vvp src/*.v testbench/test_010/CPU_tb_wave.v
vvp CPU_tb_wave.vvp
```

Open the generated waveform file with a waveform viewer such as GTKWave, Surfer, or another compatible tool.

> Note: `test_010` does not include an `expected.txt` file, so the automated test runner treats it as a waveform-oriented test rather than a standard output-comparison test.

---

## Verification Coverage

The verification suite includes both module-level and CPU-level tests.

| Test | Target | Purpose |
|---|---|---|
| `test_001` | Program Counter | Reset, increment, load, hold, priority, wrap-around |
| `test_002` | Address MUX | Address selection, parameter override, stability |
| `test_003` | ALU | Opcode behavior, zero flag, arithmetic and logic operations |
| `test_004` | Controller | FSM state transitions and control signal generation |
| `test_005` | Instruction Register | Reset, load, hold, opcode and operand extraction |
| `test_006` | Accumulator | Reset, load, hold, boundary values |
| `test_007` | Memory | Read, write, high impedance, conflict prevention |
| `test_008` | CPU Integration | Basic program: `LDA`, `ADD`, `STO`, `HLT` |
| `test_009` | CPU Integration | Extended instruction-flow verification |
| `test_010` | CPU Waveform | Waveform inspection and full instruction demonstration |

---

## Documentation

The `report/` directory contains the LaTeX source and compiled PDF report for the project. The report describes the design approach, implementation details, simulation results, RTL schematics, and waveform captures.

Main report files:

```text
report/riscReport.tex
report/riscReport.pdf
report/chapters/
report/figures/
```

---

## Limitations

This processor is designed as an educational RTL project and intentionally remains compact. Current limitations include:

- Small instruction set
- 5-bit address space limited to 32 memory locations
- Fixed multi-cycle execution sequence
- No pipelining
- No interrupt support
- No general-purpose register file
- No separate instruction and data memories

---

## License

No license file is currently included in this repository. Add a license before distributing, modifying, or reusing the code in public or commercial projects.
