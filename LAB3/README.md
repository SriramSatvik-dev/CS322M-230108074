# RVX10 - RISC-V Custom Instruction Extension

## Overview

This project implements **RVX10**, a custom instruction set extension for the RV32I single-cycle processor. RVX10 adds 10 new instructions using the RISC-V CUSTOM-0 opcode space (0x0B), maintaining full compatibility with the base RV32I ISA.

## New Instructions

RVX10 provides the following operations:

### Bitwise Operations
- **ANDN** - AND with inverted operand: `rd = rs1 & ~rs2`
- **ORN** - OR with inverted operand: `rd = rs1 | ~rs2`
- **XNOR** - NOT XOR: `rd = ~(rs1 ^ rs2)`

### Min/Max Operations
- **MIN** - Signed minimum: `rd = min(rs1, rs2)` (signed)
- **MAX** - Signed maximum: `rd = max(rs1, rs2)` (signed)
- **MINU** - Unsigned minimum: `rd = min(rs1, rs2)` (unsigned)
- **MAXU** - Unsigned maximum: `rd = max(rs1, rs2)` (unsigned)

### Rotation Operations
- **ROL** - Rotate left: `rd = (rs1 << s) | (rs1 >> (32-s))` where s = rs2[4:0]
- **ROR** - Rotate right: `rd = (rs1 >> s) | (rs1 << (32-s))` where s = rs2[4:0]

### Unary Operations
- **ABS** - Absolute value: `rd = |rs1|` (signed, rs2 ignored)

## Project Structure

```
.
├── src/
│   └── riscvsingle.sv       # Modified RV32I processor with RVX10 support
├── tests/
│   └── rvx10.hex            # Test program in hex format
├── docs/
│   ├── ENCODINGS.md         # Instruction encoding details
│   └── TESTPLAN.md          # Test cases and expected results
└── README.md                # This file
```

## Building and Running

### Prerequisites
- Icarus Verilog (iverilog) version 11.0 or later with SystemVerilog support
- VVP (Verilog simulation runtime)

### Compilation

```bash
iverilog -g2012 -o cpu_tb riscvsingle.sv
```

**Note:** You may see warnings about constant selects in `always_*` processes. These are informational warnings from Icarus Verilog and do not affect functionality.

### Simulation

```bash
vvp cpu_tb
```

### Expected Output

On successful execution, the simulator will output:
```
PC=76  MemWrite=1  DataAdr=100  WriteData=25
Simulation succeeded
```

This indicates that all RVX10 instructions executed correctly and the final validation check (storing value 25 to address 100) passed.

## Implementation Details

### Hardware Modifications

1. **Controller (`maindec`)**
   - Added case for opcode `7'b0001011` (CUSTOM-0)
   - Sets ALUOp to `2'b11` to signal RVX10 instructions

2. **ALU Decoder (`aludec`)**
   - Added ALUOp `2'b11` case with nested decoding based on funct7 and funct3
   - Generates 5-bit ALU control signals (extended from original 3-bit)

3. **ALU (`alu`)**
   - Implemented 10 new operations with control codes `5'b01000` through `5'b10001`
   - Special handling for:
     - Rotate-by-zero (returns input unchanged)
     - ABS overflow (INT_MIN wraps to itself)

### Design Constraints Met

✅ No architectural state changes beyond registers  
✅ Single-cycle execution (no stalls or multi-cycle operations)  
✅ Uses only existing datapath blocks  
✅ Self-checking testbench validates all operations  
✅ Writes to x0 properly ignored by register file  

## Test Coverage

The test program (`riscvtest.txt`) validates:
- All 10 RVX10 instructions with representative test cases
- Edge cases: rotate-by-zero, ABS(INT_MIN), signed/unsigned boundaries
- x0 hardwiring (writes to x0 are ignored)
- Final checksum validation

See `docs/TESTPLAN.md` for detailed test cases and expected results.

## Known Limitations

1. **Icarus Verilog Warnings**: The simulator generates warnings about constant selects in always blocks. This is a known limitation of Icarus Verilog's SystemVerilog support and does not affect correctness.

2. **Memory File Warning**: You may see a warning about `$readmemh` behavior. This relates to SystemVerilog standard changes and does not impact functionality.

## Compliance Notes

- **RV32I Compatibility**: RVX10 uses reserved custom opcode space and does not conflict with standard RV32I instructions
- **Encoding**: All instructions follow standard R-type format
- **Semantics**: Operations behave consistently with similar instructions in RISC-V extension proposals (Zbb, Zba)

For detailed encoding information, see `docs/ENCODINGS.md`.  
For test case details, see `docs/TESTPLAN.md`.