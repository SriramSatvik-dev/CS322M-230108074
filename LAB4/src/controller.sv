/* --------------------------------------------------------------------------
 * -- Module: controller
 * -- Pipelined Control Unit: Generates control signals and manages their flow
 * -- across pipeline registers, including hazard response.
 * -------------------------------------------------------------------------- */
module controller(
  input  logic       clk, reset,
  input  logic [6:0] op,         /* Opcode from instruction in Decode stage */
  input  logic [2:0] funct3,     /* funct3 field from instruction in Decode stage */
  input  logic       funct7b5,   /* funct7 bit 5 (for R-type sub instruction) */
  input  logic [1:0] funct7_2b,  /* funct7 bits [26:25] (for RVX10 instructions) */
  input  logic       ZeroE,      /* ALU Zero flag from Execute stage (for branches) */
  input  logic       FlushE,     /* Flush signal from Hazard Unit (for control hazard/load-use) */
  output logic       ResultSrcE0, /* ResultSrc bit 0 in EX stage (for load-use detection) */
  output logic [1:0] ResultSrcW, /* Mux select for data to write back to register file */
  output logic       MemWriteM,  /* Data Memory Write Enable (Memory stage) */
  output logic       PCSrcE,     /* Program Counter Source Select (Branch/Jump target) */
         ALUSrcE,    /* ALU Operand B Source Select (Reg or Imm) */
  output logic       RegWriteM, RegWriteW, /* Register Write Enable in M and W stages */
  output logic [1:0] ImmSrcD,    /* Immediate Extender Source Select */
  output logic [3:0] ALUControlE /* Final ALU Operation Select (Execute stage) */
);
/* Internal wires for control signals in Decode stage and across pipeline registers */
  logic [1:0] ALUOpD;
  logic [1:0] ResultSrcD, ResultSrcE, ResultSrcM;
  logic [3:0] ALUControlD;
  logic BranchD, BranchE, MemWriteD, MemWriteE, JumpD, JumpE;
  logic ZeroOp, ALUSrcD, RegWriteD, RegWriteE;

/* Instantiate the Main Decoder (Generates high-level control signals based on Opcode) */
  maindec md(
    .op        (op),
    .ResultSrc (ResultSrcD),
    .MemWrite  (MemWriteD),
    .Branch    (BranchD),
    .ALUSrc    (ALUSrcD),
    .RegWrite  (RegWriteD),
    .Jump      (JumpD),
    .ImmSrc    (ImmSrcD),
    .ALUOp     (ALUOpD)
  );
/* Instantiate the ALU Decoder (Generates the final ALU operation code) */
  aludec ad(
    .opb5       (op[5]),
    .funct3     (funct3),
    .funct7b5   (funct7b5),
    .funct7_2b  (funct7_2b),
    .ALUOp      (ALUOpD),
    .ALUControl (ALUControlD) /* ALU control code ready for EX stage */
  );
/* Instantiate the ID/EX Control Pipeline Register */
  c_ID_IEx c_pipreg0(
    .clk         (clk),
    .reset       (reset),
    .clear       (FlushE),       /* FlushE signal injects NOP (clears register) */
    .RegWriteD   (RegWriteD),
    .MemWriteD   (MemWriteD),
    .JumpD       (JumpD),
    .BranchD     (BranchD),
    .ALUSrcD     (ALUSrcD),
  
    .ResultSrcD  (ResultSrcD),
    .ALUControlD (ALUControlD), 
    .RegWriteE   (RegWriteE),   /* Control signal propagated to EX stage */
    .MemWriteE   (MemWriteE),
    .JumpE       (JumpE),
    .BranchE     (BranchE),
    .ALUSrcE     (ALUSrcE),
    .ResultSrcE  (ResultSrcE),
    .ALUControlE (ALUControlE)
  );
/* Expose ResultSrcE[0] to the Hazard Unit for load-use stall detection */
  assign ResultSrcE0 = ResultSrcE[0];

/* Instantiate the EX/MEM Control Pipeline Register */
  c_IEx_IM c_pipreg1(
    .clk        (clk),
    .reset      (reset),
    .RegWriteE  (RegWriteE),
    .MemWriteE  (MemWriteE),
    .ResultSrcE (ResultSrcE),
    .RegWriteM  (RegWriteM), /* Control signal propagated to MEM stage */
    .MemWriteM  (MemWriteM),
    .ResultSrcM (ResultSrcM)
  );
/* Instantiate the MEM/WB Control Pipeline Register */
  c_IM_IW c_pipreg2 (
    .clk        (clk),
    .reset      (reset),
    .RegWriteM  (RegWriteM),
    .ResultSrcM (ResultSrcM),
    .RegWriteW  (RegWriteW), /* Final control signal for WB stage */
    .ResultSrcW (ResultSrcW)
  );

/* Logic for PC Source Selection (Control Hazard Resolution in EX stage) */
/* PCSrcE is high if: 1. It's a Branch AND the ALU result is Zero (BranchE & ZeroE) OR 2. It's an unconditional Jump (JumpE). */
  assign PCSrcE = (BranchE & ZeroE) | JumpE;

endmodule


/* --------------------------------------------------------------------------
 * -- Module: maindec
 * -- Main Instruction Decoder: Generates primary control signals based on Opcode.
 * -------------------------------------------------------------------------- */
module maindec(
  input  logic [6:0] op,           /* Opcode of the instruction */
  output logic [1:0] ResultSrc,    /* Mux select for WriteBack data source */
  output logic       MemWrite,     /* Data Memory Write Enable */
  output logic       Branch, ALUSrc, /* Branch Type instruction & ALU Operand B source */
  output logic       RegWrite, Jump, /* Register Write Enable & Jump Type instruction */
  output logic [1:0] ImmSrc,       /* Immediate Extension Type */
  output logic [1:0] ALUOp         /* ALU operation type (for sub-decoding) */
);
/* Internal wire to compactly assign all control signals */
  logic [10:0] controls;
/* Concatenate and assign the internal controls wire to the output ports */
  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump} = controls;
/* Combinational logic to decode the opcode and assert control signals */
  always_comb
    case(op)
    /* Control Bit Assignment Order: 
        RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump */
      7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; /* lw (Load Word) */
      7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; /* sw (Store Word) */
      7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; /* R-type (Register-to-Register operations) */
      7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; /* beq (Branch Equal) */
      7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; /* I-type ALU (Immediate Arithmetic) */
      7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; /* jal (Jump and Link) */
      7'b0001011: controls = 11'b1_xx_0_0_00_0_11_0; /* R-type_newly_added_instructions (RVX10 extension) */
      default:    controls = 11'bx_xx_x_x_xx_x_xx_x; /* Default for non-implemented instructions */
    endcase
endmodule

/* --------------------------------------------------------------------------
 * -- Module: aludec
 * -- ALU Decoder: Generates the 4-bit ALU control code based on ALUOp, funct3,
 * -- and funct7 fields for R-type and I-type instructions.
 * -------------------------------------------------------------------------- */
module aludec(
  input  logic       opb5,           /* Opcode bit 5 (to distinguish R-type sub) */
  input  logic [2:0] funct3,         /* Instruction funct3 field */
  input  logic       funct7b5,       /* Instruction funct7 bit 5 */
  input  logic [1:0] funct7_2b,      /* Instruction funct7 bits [26:25] (for RVX10) */
  input  logic [1:0] ALUOp,          /* High-level ALU operation type from maindec */
  output logic [3:0] ALUControl      /* 4-bit ALU operation code */
);
  logic  RtypeSub;
  /* RtypeSub is true if the instruction is an R-type (opb5=1) and funct7b5 is set (0x40000000) */
  assign RtypeSub = funct7b5 & opb5;  

  /* Combinational logic to set the final ALUControl code */
  always_comb
    case(ALUOp)
      2'b00:            ALUControl = 4'b0000; /* ALUOp 00: Addition (used for lw, sw address calculation) */
      2'b01:            ALUControl = 4'b0001; /* ALUOp 01: Subtraction (used for beq comparison) */
      2'b10: case(funct3) /* ALUOp 10: R-type or I-type ALU operations */
               3'b000:  if (RtypeSub) 
                          ALUControl = 4'b0001; /* R-type sub */
                        else        
                          ALUControl = 4'b0000; /* add, addi */
               3'b010:    ALUControl = 4'b0101; /* slt, slti (Set Less Than) */
               3'b110:    ALUControl = 4'b0011; /* or, ori (Bitwise OR) */
               3'b111:    ALUControl = 4'b0010; /* and, andi (Bitwise AND) */
               default:   ALUControl = 4'bxxxx; /* Unimplemented R/I type */
             endcase
      2'b11: case(funct7_2b) /* ALUOp 11: Extended R-type operations (RVX10) */
               2'b00:  case (funct3)
                         3'b000: ALUControl = 4'b0110; /* andn */
                         3'b001: ALUControl = 4'b0111; /* orn */
                         3'b010: ALUControl = 4'b1000; /* xorn */
                         default: ALUControl = 4'bxxxx;
                       endcase
               2'b01:  case (funct3)
                         3'b000: ALUControl = 4'b1001; /* min */
                         3'b001: ALUControl = 4'b1010; /* max */
                         3'b010: ALUControl = 4'b1011; /* minu */
                         3'b011: ALUControl = 4'b1100; /* maxu */
                         default: ALUControl = 4'bxxxx;
                       endcase
               2'b10:  case (funct3)
                         3'b000: ALUControl = 4'b1101; /* rol */
                         3'b001: ALUControl = 4'b1110; /* ror */
                         default: ALUControl = 4'bxxxx;
                       endcase
               2'b11:  case (funct3)
                         3'b000: ALUControl = 4'b1111; /* abs */
                         default: ALUControl = 4'bxxxx;
                       endcase
               default: ALUControl = 4'bxxxx;
             endcase
      default: ALUControl = 4'bxxxx; /* Default for non-decoded ALUOp */
  endcase
endmodule