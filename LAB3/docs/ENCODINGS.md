# RVX10 Instruction Encodings

This document shows the exact bitfields and encodings for all implemented instructions, including RVX10 ALU extensions.

## R-Type (add, sub, and, or, slt, rol, ror)
| Instruction | opcode   | funct3 | funct7    | Example Encoding |
|------------|----------|--------|-----------|----------------|
| add        | 0110011  | 000    | 0000000   | 0x000101B3      |
| sub        | 0110011  | 000    | 0100000   | 0x400101B3      |
| and        | 0110011  | 111    | 0000000   | 0x000171B3      |
| or         | 0110011  | 110    | 0000000   | 0x000161B3      |
| slt        | 0110011  | 010    | 0000000   | 0x000121B3      |
| rol        | 0110011  | 001    | 0000000   | 0x000081B3      |
| ror        | 0110011  | 101    | 0000000   | 0x0000A1B3      |
| abs        | 0110011  | 000    | 1000000   | 0x400101B3      | 

## I-Type (addi, andi, ori, slti)
| Instruction | opcode   | funct3 | Immediate | Example Encoding |
|------------|----------|--------|-----------|----------------|
| addi       | 0010011  | 000    | imm[11:0] | 0x00100113      |
| andi       | 0010011  | 111    | imm[11:0] | 0x00107113      |
| ori        | 0010011  | 110    | imm[11:0] | 0x00106113      |
| slti       | 0010011  | 010    | imm[11:0] | 0x00102113      |

## S-Type (sw)
| Instruction | opcode   | funct3 | Immediate | Example Encoding |
|------------|----------|--------|-----------|----------------|
| sw         | 0100011  | 010    | imm[11:0] | 0x00212023      |

## B-Type (beq)
| Instruction | opcode   | funct3 | Immediate | Example Encoding |
|------------|----------|--------|-----------|----------------|
| beq        | 1100011  | 000    | imm[12:1] | 0x00010463      |

## J-Type (jal)
| Instruction | opcode   | Immediate | Example Encoding |
|------------|----------|-----------|----------------|
| jal        | 1101111  | imm[20:1] | 0x0000006F      |
