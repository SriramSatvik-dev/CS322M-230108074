/* ----------------------------------------------------------------------
 * -- Module: forwarding_unit
 * -- Determines data forwarding paths to resolve data hazards in the EX stage.
 * ---------------------------------------------------------------------- */
module forwarding_unit(
  input  logic [4:0] Rs1E, Rs2E,  // Source register indices needed in the Execute stage
  input  logic [4:0] RdM, RdW,     // Destination register indices of instructions in MEM and WB stages
  input  logic       RegWriteM,   // Control signal: Instruction in MEM stage will write to register file
  input  logic       RegWriteW,   // Control signal: Instruction in WB stage will write to register file
  output logic [1:0] ForwardAE,  // Forwarding selection signal for ALU operand A (Rs1E)
  output logic [1:0] ForwardBE   // Forwarding selection signal for ALU operand B (Rs2E)
);

/* Combinational logic to determine which result (if any) should be forwarded */
  always_comb begin
    /* --- 1. Defaults (No Forwarding) --- */
    ForwardAE = 2'b00; // Default: Read from register file (RD1E)
    ForwardBE = 2'b00; // Default: Read from register file (RD2E)

    /* --- 2. Forwarding Logic for Rs1 (Operand A) --- */
    
    /* EX/MEM Hazard Check: Data is produced by instruction in MEM stage (highest priority)
       The condition checks if Rs1E matches the destination register RdM, if RdM is not r0,
       and if the MEM stage instruction will write back (RegWriteM). */
    if ((Rs1E == RdM) & RegWriteM & (Rs1E != 0))
      ForwardAE = 2'b10; // Select ALUResultM (from the output of the MEM stage)
        
    /* MEM/WB Hazard Check: Data is produced by instruction in WB stage (lower priority)
       This check only runs if the higher priority EX/MEM hazard is NOT present. */
    else if ((Rs1E == RdW) & RegWriteW & (Rs1E != 0))
      ForwardAE = 2'b01; // Select ResultW (from the output of the WB stage)

    /* --- 3. Forwarding Logic for Rs2 (Operand B) --- */
    
    /* EX/MEM Hazard Check (Highest Priority) */
    if ((Rs2E == RdM) & RegWriteM & (Rs2E != 0))
      ForwardBE = 2'b10; // Select ALUResultM
        
    /* MEM/WB Hazard Check (Lower Priority) */
    else if ((Rs2E == RdW) & RegWriteW & (Rs2E != 0))
      ForwardBE = 2'b01; // Select ResultW
  end
endmodule