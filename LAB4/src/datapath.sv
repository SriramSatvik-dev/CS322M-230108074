/* --------------------------------------------------------------------------
 * -- Module: datapath
 * -- Implements the core 5-stage pipelined datapath components and interconnects.
 * -------------------------------------------------------------------------- */
module datapath(
  input  logic       clk, reset,
  input  logic [1:0] ResultSrcW,   /* WB: Mux select for final result */
  input  logic       PCSrcE,       /* EX: PC source select (for branch/jump) */
  input  logic       ALUSrcE,      /* EX: ALU Operand B source select */
  input  logic       RegWriteW,    /* WB: Register Write Enable */
  input  logic [1:0] ImmSrcD,      /* ID: Immediate extension type select */
  input  logic [3:0] ALUControlE,  /* EX: ALU operation select code */
  output logic       ZeroE,        /* EX: ALU Zero flag output */
  output logic [31:0] PCF,          /* IF: Program Counter output */
  input  logic [31:0] InstrF,       /* IF: Instruction fetched from memory */
  output logic [31:0] InstrD,       /* ID: Instruction decoded */
  output logic [31:0] ALUResultM,   /* MEM: ALU result (memory address) */
  output logic [31:0] WriteDataM,   /* MEM: Data to write to memory */
  input  logic [31:0] ReadDataM,    /* MEM: Data read from memory */
  input  logic [1:0] ForwardAE,    /* EX: Forwarding Mux A select */
  input  logic [1:0] ForwardBE,    /* EX: Forwarding Mux B select */
  output logic [4:0] Rs1D, Rs2D,    /* ID: Source Register 1 and 2 indices */
  output logic [4:0] Rs1E, Rs2E,    /* EX: Source Register 1 and 2 indices */
  output logic [4:0] RdE, RdM, RdW, /* EX, MEM, WB: Destination Register indices */
  input  logic       StallD, StallF, /* Hazard: Stall signals for ID and IF stages */
  input  logic       FlushD, FlushE  /* Hazard: Flush signals for ID and EX stages */
);

/* Internal Datapath Signals */
  logic [31:0] PCD, PCE, ALUResultE, ALUResultW, ReadDataW;
  logic [31:0] PCNextF, PCPlus4F, PCPlus4D, PCPlus4E, PCPlus4M, PCPlus4W, PCTargetE;
  logic [31:0] WriteDataE;
  logic [31:0] ImmExtD, ImmExtE;
  logic [31:0] SrcAE, SrcBE, RD1D, RD2D, RD1E, RD2E;
  logic [31:0] ResultW;
  logic [4:0] RdD;
    
/* ---------------------------
 * --- Instruction Fetch Stage (IF) ---
 * --------------------------- */
    
  /* Mux to select next PC (PC+4 or Branch/Jump Target) */
  mux2 #(.WIDTH(32)) pcmux(
    .d0 (PCPlus4F),
    .d1 (PCTargetE),
    .s  (PCSrcE),
    .y  (PCNextF)
  );
/* PC Register (flopenr, updates on clock edge if not stalled) */
  flopenr #(.WIDTH(32)) IF(
    .clk   (clk),
    .reset (reset),
    .en    (~StallF), /* PC update enabled unless stalled by Hazard Unit */
    .d     (PCNextF),
    .q     (PCF)
  );
/* Adder for PC + 4 calculation (Sequential address) */
  adder pcadd4(
    .a (PCF),
    .b (32'd4),
    .y (PCPlus4F)
  );

/* ---------------------------------------------------
 * --- IF/ID Pipeline Register (pipreg0) ---
 * --------------------------------------------------- */
    
  IF_ID pipreg0 (
    .clk      (clk),
    .reset    (reset),
    .clear    (FlushD),  /* Clears instruction (Injects NOP) if control hazard detected */
    .enable   (~StallD), /* Holds values if stalled by load-use hazard */
    .InstrF   (InstrF),
    .PCF      (PCF),
    .PCPlus4F (PCPlus4F),
    .InstrD   (InstrD),
    .PCD      (PCD),
    .PCPlus4D (PCPlus4D)
  );

/* ---------------------------
 * --- Decode Stage (ID) ---
 * --------------------------- */
  
/* Decode: Extract register addresses from instruction */
  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];  
  assign RdD  = InstrD[11:7];
  
/* Register File Unit: Reads register values */
  regfile rf (
    .clk (clk),
    .we3 (RegWriteW), /* Write enable controlled by WB stage */
    .a1  (Rs1D),      /* Read Address 1 (rs1) */
    .a2  (Rs2D),      /* Read Address 2 (rs2) */
    .a3  (RdW),       /* Write Address (rdW) */
    .wd3 (ResultW),   /* Write Data (ResultW) */
    .rd1 (RD1D),      /* Read Data 1 */
    .rd2 (RD2D)       /* Read Data 2 */
  );
/* Sign/Immediate Extension Unit: Generates immediate values */
  extend ext(
    .instr  (InstrD[31:7]), /* Instruction fields used for immediate */
    .immsrc (ImmSrcD),      /* Control signal for extension type */
    .immext (ImmExtD)      /* 32-bit immediate value output */
  );

/* ------------------------------------------------
 * --- ID/EX Pipeline Register (pipreg1) ---
 * ------------------------------------------------ */
    
  ID_IEx pipreg1 (
    .clk      (clk),
    .reset    (reset),
    .clear    (FlushE), /* Clears register (Injects NOP) */
    .RD1D     (RD1D),
    .RD2D     (RD2D),
    .PCD      (PCD),
    .Rs1D     (Rs1D),
    .Rs2D     (Rs2D),
    .RdD      (RdD),
    .ImmExtD  (ImmExtD),
    .PCPlus4D (PCPlus4D),
    .RD1E     (RD1E),
    .RD2E     (RD2E),
    .PCE      (PCE),
    .Rs1E     (Rs1E),
    .Rs2E     (Rs2E),
    .RdE      (RdE),
    .ImmExtE  (ImmExtE),
    .PCPlus4E (PCPlus4E)
  );

/* ---------------------------
 * --- Execute Stage (EX) ---
 * --------------------------- */
  
/* Forwarding Mux for ALU Operand A (Rs1) */
  mux3 #(.WIDTH(32)) forwardMuxA (
    .d0 (RD1E),       /* 00: Register File (default) */
    .d1 (ResultW),    /* 01: Forwarded from WB stage */
    .d2 (ALUResultM), /* 10: Forwarded from MEM stage */
    .s  (ForwardAE),
    .y  (SrcAE)
  );
/* Forwarding Mux for ALU Operand B (Rs2 / Store Data) */
  mux3 #(.WIDTH(32)) forwardMuxB (
    .d0 (RD2E),       /* 00: Register File (default) */
    .d1 (ResultW),    /* 01: Forwarded from WB stage */
    .d2 (ALUResultM), /* 10: Forwarded from MEM stage */
    .s  (ForwardBE),
    .y  (WriteDataE)  /* Data for Store instruction (sw) */
  );
/* Mux to select ALU Operand B (Forwarded Reg data or Immediate) */
  mux2 #(.WIDTH(32)) srcbmux(
    .d0 (WriteDataE), /* Register data (after forwarding check) */
    .d1 (ImmExtE),    /* Immediate value */
    .s  (ALUSrcE),
    .y  (SrcBE)
  );
/* Adder for calculating Branch/Jump Target Address (PCE + Immediate) */
  adder pcaddbranch(
    .a (PCE),
    .b (ImmExtE),
    .y (PCTargetE)
  );
/* The main Arithmetic Logic Unit (ALU) */
  alu alu(
    .a          (SrcAE),
    .b          (SrcBE),
    .alucontrol (ALUControlE),
    .result     (ALUResultE),
    .zero       (ZeroE) /* Zero flag for conditional branches */
  );

/* ----------------------------------------------------
 * --- EX/MEM Pipeline Register (pipreg2) ---
 * ---------------------------------------------------- */
  
  IEx_IMem pipreg2 (
    .clk        (clk),
    .reset      (reset),
    .ALUResultE (ALUResultE), /* ALU result (Address for memory) */
    .WriteDataE (WriteDataE), /* Data to write to memory */
    .RdE        (RdE),        /* Destination register index */
    .PCPlus4E   (PCPlus4E),
    .ALUResultM (ALUResultM),
    .WriteDataM (WriteDataM),
    .RdM        (RdM),
    .PCPlus4M   (PCPlus4M)
  );

/* ---------------------------
 * --- Memory Stage (MEM) ---
 * --------------------------- */
/* This module only provides the address/data for external memory access */
    
/* --------------------------------------------------
 * --- MEM/WB Pipeline Register (pipreg3) ---
 * -------------------------------------------------- */
  
  IMem_IW pipreg3 (
    .clk        (clk),
    .reset      (reset),
    .ALUResultM (ALUResultM),
    .ReadDataM  (ReadDataM),
    .RdM        (RdM),
    .PCPlus4M   (PCPlus4M),
    .ALUResultW (ALUResultW),
    .ReadDataW  (ReadDataW),
    .RdW        (RdW),
    .PCPlus4W   (PCPlus4W)
  );

/* ---------------------------
 * --- Writeback Stage (WB) ---
 * --------------------------- */
  
/* Mux to select the final result (ResultW) to write back to the register file */
  mux3 #(.WIDTH(32)) resultmux(
    .d0 (ALUResultW), /* 00: ALU operation result */
    .d1 (ReadDataW),  /* 01: Data loaded from memory */
    .d2 (PCPlus4W),   /* 10: PC+4 (for JAL return address) */
    .s  (ResultSrcW),
    .y  (ResultW)
  );
endmodule