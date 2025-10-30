/* --------------------------------------------------------------------------
 * -- Module: riscvpipeline
 * -- Top-level wrapper module: Connects the RISC-V core to external memories.
 * -------------------------------------------------------------------------- */
module riscvpipeline (
  input  logic       clk, reset, 
  output logic [31:0] WriteDataM, DataAdrM, 
  output logic       MemWriteM
);
/* Internal wires for I-Mem and D-Mem connections */
  logic [31:0] PCF, InstrF, ReadDataM;

  /* Instantiate the main RISC-V processor core (Pipelined) */
  riscv rv(
    .clk        (clk),
    .reset      (reset),
    .PCF        (PCF),
    .InstrF     (InstrF),
    .MemWriteM  (MemWriteM),
    .ALUResultM (DataAdrM),   /* ALU result from MEM stage is used as data memory address */
    .WriteDataM (WriteDataM),
    .ReadDataM  (ReadDataM)
  );

/* Instantiate the Instruction Memory (IMEM) */
  imem imem(
    .a  (PCF),      /* Address input from PCF (Fetch stage) */
    .rd (InstrF)    /* Read data (instruction) output to IF stage */
  );
/* Instantiate the Data Memory (DMEM) */
  dmem dmem(
    .clk (clk),
    .we  (MemWriteM),  /* Write enable signal */
    .a   (DataAdrM),   /* Address input (from ALUResultM) */
    .wd  (WriteDataM), /* Write data input (from Register File/Forwarding) */
    .rd  (ReadDataM)   /* Read data output (to WB stage) */
  );
endmodule

/* --------------------------------------------------------------------------
 * -- Module: riscv
 * -- The main RISC-V processor core (connects control, datapath, and hazard logic).
 * -------------------------------------------------------------------------- */
module riscv(
  input  logic       clk, reset,
  output logic [31:0] PCF,         /* Program Counter Address (Fetch stage) */
  output logic       MemWriteM,   /* Data Memory Write Enable (Memory stage) */
  output logic [31:0] ALUResultM,  /* ALU result (used as memory address) */
  input  logic [31:0] InstrF,      /* Instruction fetched from IMEM */
  output logic [31:0] WriteDataM,  /* Data to be written to DMEM (Store instructions) */
  input  logic [31:0] ReadDataM    /* Data read from DMEM (Load instructions) */
);
/* Internal interconnect wires for control and data signals across pipeline stages */
  logic ALUSrcE, RegWriteM, RegWriteW, ZeroE, PCSrcE;
  logic StallD, StallF, FlushD, FlushE, ResultSrcE0;
  logic [1:0] ResultSrcW; 
  logic [1:0] ImmSrcD;
  logic [3:0] ALUControlE;
  logic [31:0] InstrD;
  logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E;
  logic [4:0] RdE, RdM, RdW;
  logic [1:0] ForwardAE, ForwardBE;
  
/* Instantiate the Pipelined Controller Unit */
  controller c(
    .clk        (clk),
    .reset      (reset),
    .op         (InstrD[6:0]),      /* Opcode of instruction in Decode */
    .funct3     (InstrD[14:12]),    /* funct3 of instruction in Decode */
    .funct7b5   (InstrD[30]),       /* Bit 30 of instruction in Decode */
    .funct7_2b  (InstrD[26:25]),    /* Bits 26:25 of instruction in Decode */
    .ZeroE      (ZeroE),            /* ALU Zero flag from Execute stage */
    .FlushE     (FlushE),           /* Flush signal from Hazard Unit */
    .ResultSrcE0(ResultSrcE0),       /* Load instruction flag for Hazard Unit */
    
    .ResultSrcW (ResultSrcW),       /* Mux select for data to write to Register File */
    .MemWriteM  (MemWriteM),        /* Data Memory Write Enable */
    .PCSrcE     (PCSrcE),           /* PC source select (for branch/jump) */
    .ALUSrcE    (ALUSrcE),          /* ALU Operand B select (Reg or Imm) */
    .RegWriteM  (RegWriteM),        /* Register Write Enable in Memory stage (for forwarding logic) */
    .RegWriteW  (RegWriteW),        /* Register Write Enable in WriteBack stage */
    .ImmSrcD    (ImmSrcD),          /* Immediate Extender select */
    .ALUControlE(ALUControlE)       /* ALU operation select */
  );
/* --- Datapath Enhancement Units (Handling Hazards) --- */
  
/* Instantiate the Forwarding Unit (Data Hazard Resolution) */
  forwarding_unit fu (
    .Rs1E     (Rs1E),              /* Source register 1 in EX */
    .Rs2E     (Rs2E),              /* Source register 2 in EX */
    .RdM      (RdM),               /* Destination register in MEM */
    .RdW      (RdW),               /* Destination register in WB */
    .RegWriteM(RegWriteM),          /* RegWrite control in MEM */
    .RegWriteW(RegWriteW),          /* RegWrite control in WB */
    .ForwardAE(ForwardAE),          /* Forwarding Mux A select */
    .ForwardBE(ForwardBE)           /* Forwarding Mux B select */
  );
/* Instantiate the Hazard Unit (Stalls and Flushes) */
  hazard_unit hu (
    .Rs1D       (Rs1D),              /* Source register 1 in ID */
    .Rs2D       (Rs2D),              /* Source register 2 in ID */
    .RdE        (RdE),               /* Destination register in EX */
    .ResultSrcE0(ResultSrcE0),        /* Load Instruction Flag in EX */
    .PCSrcE     (PCSrcE),            /* Taken Branch Flag in EX */
    .StallD     (StallD),            /* Stall signal for ID/EX register */
    .StallF     (StallF),            /* Stall signal for PC and IF/ID register */
    .FlushD     (FlushD),            /* Flush signal for IF/ID register */
    .FlushE     (FlushE)             /* Flush signal for ID/EX register */
  );
/* --- End of Unit Instantiations --- */

/* Instantiate the 5-Stage Pipelined Datapath Core */
  datapath dp(
    .clk        (clk),
    .reset      (reset),
    .ResultSrcW (ResultSrcW),
    .PCSrcE     (PCSrcE),
    .ALUSrcE    (ALUSrcE),
    .RegWriteW  (RegWriteW),
    .ImmSrcD    (ImmSrcD),
    .ALUControlE(ALUControlE),
    .ZeroE      (ZeroE),
    .PCF        (PCF),
    .InstrF     (InstrF),
    .InstrD     (InstrD),
    .ALUResultM (ALUResultM),
    .WriteDataM (WriteDataM),
    .ReadDataM  (ReadDataM),
    .ForwardAE  (ForwardAE),
    .ForwardBE  (ForwardBE),
    .Rs1D       (Rs1D),
    .Rs2D       (Rs2D),
    .Rs1E       (Rs1E),
    .Rs2E       (Rs2E),
    .RdE        (RdE),
    .RdM        (RdM),
    .RdW        (RdW),
    .StallD     (StallD),
    .StallF     (StallF),
    .FlushD     (FlushD),
    .FlushE     (FlushE)
  );
/* --- Performance Counters (for simulation/analysis) --- */
  logic [31:0] cycle_count;
  logic [31:0] instr_retired;

  /* Synchronous logic for counters */
  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      cycle_count   <= '0;
      instr_retired <= '0;
    end
    else begin
      /* Increment total cycle count every clock edge */
      cycle_count <= cycle_count + 1;
      /* Instruction Counter: Tracks instructions that complete WriteBack/Memory access.
         This condition (RegWriteW | MemWriteM | PCSrcE) ensures counting a completed
         R/I-type, Store, or Taken Branch/Jump (which completes WB or MEM stage work). */
      if (RegWriteW | MemWriteM | PCSrcE) begin
          instr_retired <= instr_retired + 1;
      end
    end
  end
endmodule