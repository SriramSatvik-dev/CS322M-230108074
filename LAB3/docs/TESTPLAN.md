# RVX10 Test Plan

## Test Environment
- Simulator: iverilog + vvp
- Memory image: tests/rvx10.hex
- Reset cycle: 22
- Check success: Write 25 to address 100

---

## Register-ALU Instructions

| Instruction | Inputs (regs/imm) | Expected Result | Notes |
|------------|-----------------|----------------|------|
| add x1,x2,x3 | x2=5, x3=10 | x1=15 | basic addition |
| sub x4,x5,x6 | x5=20, x6=7 | x4=13 | basic subtraction |
| and x7,x8,x9 | x8=0xF0F0, x9=0x0FF0 | x7=0x00F0 | bitwise AND |
| or x10,x11,x12 | x11=0xF00F, x12=0x0FF0 | x10=0xFFFF | bitwise OR |
| slt x13,x14,x15 | x14=5, x15=10 | x13=1 | x14 < x15 |
| addi x16,x17,7 | x17=3 | x16=10 | immediate addition |
| abs x18,x19 | x19=0x80000000 | x18=0x80000000 | edge case: INT_MIN |
| rol x20,x21,4 | x21=0x12345678 | x20=0x23456781 | rotate left |
| rol x22,x23,0 | x23=0xABCDEF01 | x22=0xABCDEF01 | rotate 0 returns rs1 |
| ror x24,x25,8 | x25=0x12345678 | x24=0x78123456 | rotate right |
| ror x26,x27,0 | x27=0x87654321 | x26=0x87654321 | rotate 0 returns rs1 |

---

## Memory Instructions

| Instruction | Inputs | Expected Result | Notes |
|------------|--------|----------------|------|
| lw x1,0(x2) | x2=0, mem[0]=0xDEADBEEF | x1=0xDEADBEEF | load word |
| sw x3,4(x4) | x4=0, x3=0x12345678 | mem[1]=0x12345678 | store word |

---

## Branch / Jump Instructions

| Instruction | Inputs | Expected Result | Notes |
|------------|--------|----------------|------|
| beq x5,x6,label | x5=10, x6=10 | PC = label | branch taken |
| jal x7,label | PC=100 | x7=PC+4, PC=label | jump and link |

---

## Success Condition

- Simulation prints: `"Simulation succeeded"`  
- Memory[100] = 25  
