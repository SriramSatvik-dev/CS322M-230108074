// --------------------------------------------------------------------------
// -- Module: Pipelined Hazard Detection Unit for Load-Use and Control Hazards
// --------------------------------------------------------------------------
module hazard_unit(
  // ID Stage: Source registers being read by the instruction in Decode
  input  logic [4:0] Rs1D, Rs2D,
  // EX Stage: Destination register of the instruction currently in Execute
  input  logic [4:0] RdE,
  // EX Stage Control: Flag (ResultSrcE[0]) to indicate if the instruction in EX is a load
  input  logic       ResultSrcE0,
  // Branch Control: High if a branch is detected as taken in the EX stage
  input  logic       PCSrcE,
  // Output Stall Signals: Used to prevent register updates (halt IF and ID)
  output logic       StallD, StallF,
  // Output Flush Signals: Used to inject NOPs (squash IF/ID and ID/EX registers)
  output logic       FlushD, FlushE
);

// Internal wire to indicate a critical Load-Use dependency (needs a stall)
  logic lwStall;
// Load-Use Condition: EX instruction is a load AND it targets a register (RdE) that 
// is required as a source (Rs1D or Rs2D) by the instruction in the ID stage.
  assign lwStall = (ResultSrcE0 == 1) & ((RdE == Rs1D) | (RdE == Rs2D));

// ---------------------------------
// -- Pipeline Stall Generation (Bubbling)
// ---------------------------------

// Stall the Fetch stage (halts PC update and IF/ID register write)
  assign StallF = lwStall;
// Stall the Decode stage (halts ID/EX register write)
  assign StallD = lwStall;
    
// ---------------------------------
// -- Pipeline Flush Generation (Squashing)
// ---------------------------------
    
// Flush EX stage: Squash the ID/EX register to inject a NOP.
// This is necessary for both Load-Use stalls and Taken Branches.
  assign FlushE = lwStall | PCSrcE;
    
// Flush ID stage: Squash the IF/ID register to inject a NOP.
// This is ONLY necessary when a branch is taken to discard the incorrect instruction fetched after the branch.
  assign FlushD = PCSrcE;
endmodule