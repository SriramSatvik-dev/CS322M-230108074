// Instruction Memory module.
module imem (
  input  logic [31:0] a,  // Address
  output logic [31:0] rd  // Read data (instruction)
);
// Memory array 
  logic [31:0] RAM[63:0];
// Initialize memory from file
  initial begin
    $readmemh("../tests/rvx10_pipeline.txt", RAM); 
  end
    
  // Combinational read
  assign rd = RAM[a[31:2]];
// word-aligned
endmodule

// Data Memory module.
module dmem(
  input  logic       clk, we,
  input  logic [31:0] a, wd,
  output logic [31:0] rd
);
// Memory array 
  logic [31:0] RAM [63:0];
// Combinational read (word-aligned)
  assign rd = RAM[a[31:2]]; 
    
  // Synchronous write (on positive clock edge)
  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
endmodule


// Control Unit Pipeline Register (ID to EX)
module c_ID_IEx (
  input  logic       clk, reset, clear,
  input  logic       RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD,
  input  logic [1:0] ResultSrcD, 
  input  logic [3:0] ALUControlD,  
  output logic       RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE,
  output logic [1:0] ResultSrcE,
  output logic [3:0] ALUControlE
);
  always_ff @( posedge clk, posedge reset ) begin
    if (reset) begin // Asynchronous reset
      RegWriteE   <= 0;
      MemWriteE   <= 0;
      JumpE       <= 0;
      BranchE     <= 0; 
      ALUSrcE     <= 0;
      ResultSrcE  <= 0;
      ALUControlE <= 0;
    end
    else if (clear) begin // Synchronous clear (flushes to 0)
      RegWriteE   <= 0;
      MemWriteE   <= 0;
      JumpE       <= 0;
      BranchE     <= 0; 
      ALUSrcE     <= 0;
      ResultSrcE  <= 0;
      ALUControlE <= 0;
    end
    else begin // Normal operation: latch inputs
      RegWriteE   <= RegWriteD;
      MemWriteE   <= MemWriteD;
      JumpE       <= JumpD;
      BranchE     <= BranchD; 
      ALUSrcE     <= ALUSrcD;
      ResultSrcE  <= ResultSrcD;
      ALUControlE <= ALUControlD; 
    end
  end
endmodule

// Control Unit Pipeline Register (EX to MEM)
module c_IEx_IM (
  input  logic       clk, reset,
  input  logic       RegWriteE, MemWriteE,
  input  logic [1:0] ResultSrcE,  
  output logic       RegWriteM, MemWriteM,
  output logic [1:0] ResultSrcM
);
  always_ff @( posedge clk, posedge reset ) begin
    if (reset) begin // Asynchronous reset
      RegWriteM  <= 0;
      MemWriteM  <= 0;
      ResultSrcM <= 0;
    end
    else begin // Normal operation: latch inputs
      RegWriteM  <= RegWriteE;
      MemWriteM  <= MemWriteE;
      ResultSrcM <= ResultSrcE; 
    end
  end
endmodule

// Control Unit Pipeline Register (MEM to WB)
module c_IM_IW (
  input  logic       clk, reset, 
  input  logic       RegWriteM, 
  input  logic [1:0] ResultSrcM, 
  output logic       RegWriteW, 
  output logic [1:0] ResultSrcW
);
  always_ff @( posedge clk, posedge reset ) begin
    if (reset) begin // Asynchronous reset
      RegWriteW  <= 0;
      ResultSrcW <= 0;
    end
    else begin // Normal operation: latch inputs
      RegWriteW  <= RegWriteM;
      ResultSrcW <= ResultSrcM; 
    end
  end
endmodule

// Parameterized 2-to-1 Multiplexer.
module mux2 #(parameter WIDTH=8)(
  input  logic [WIDTH-1:0] d0, d1, // Data inputs
  input  logic             s,      // Select signal
  output logic [WIDTH-1:0] y       // Data output
);
  assign y = s ? d1 : d0;
endmodule

// Register with asynchronous reset and synchronous enable.
module flopenr #(
  parameter WIDTH = 8
) (
  input  logic             clk,   // Clock
  input  logic             reset, // Asynchronous reset
  input  logic             en,    // Synchronous enable
  input  logic [WIDTH-1:0] d,     // Data input
  output logic [WIDTH-1:0] q      // Data output
);

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      q <= 0;
    else if (en)
      q <= d;
  end
endmodule

// Simple 32-bit combinational adder.
module adder(
  input  [31:0] a, b, // 32-bit inputs
  output [31:0] y     // 32-bit output (a + b)
);
  assign y = a + b;
endmodule

// Datapath Pipeline register between Fetch and Decode Stage. (valid bit removed)
module IF_ID (
  input  logic       clk, reset, clear, enable,
  input  logic [31:0] InstrF, PCF, PCPlus4F,
  output logic [31:0] InstrD, PCD, PCPlus4D
);
  always_ff @( posedge clk, posedge reset ) begin
    if (reset) begin // Asynchronous Clear
      InstrD   <= 0;
      PCD      <= 0;
      PCPlus4D <= 0;
    end
    else if (enable) begin // Only latch if enabled (not stalled)
      if (clear) begin // Synchronous Clear (flushes to a NOP)
        InstrD   <= 32'h00000033; // add x0,x0,x0 (nop)
        PCD      <= 0;
        PCPlus4D <= 0; 
      end
      else begin // Normal operation
        InstrD   <= InstrF;
        PCD      <= PCF;
        PCPlus4D <= PCPlus4F;
      end
    end
    // If enable is 0, registers hold their previous value (stall)
  end
endmodule

// 3-port Register File (Write on negedge clk).
module regfile (
  input  logic       clk,
  input  logic       we3,      // Write enable (from WB stage)
  input  logic [4:0] a1, a2, a3, // a1,a2=Read addrs, a3=Write addr
  input  logic [31:0] wd3,    // Write data
  output logic [31:0] rd1, rd2 // Read data
);
// The register file storage array
  logic [31:0] rf[31:0];

// Write on negative clock edge
  always_ff @(negedge clk)
    if (we3 & a3 != 0) rf[a3] <= wd3;

// Combinational reads
  assign rd1 = (a1 != 0) ? rf[a1] : 0; // Hardwire x0 to 0
  assign rd2 = (a2 != 0) ? rf[a2] : 0; // Hardwire x0 to 0
endmodule

// Sign-extends immediate values.
module extend(
  input  logic [31:7] instr,   
  input  logic [1:0]  immsrc,  
  output logic [31:0] immext   
);
// Combinational logic to generate the correct immediate
  always_comb
    case(immsrc) 
      // I-type
      2'b00:  immext = {{20{instr[31]}}, instr[31:20]};
      // S-type
      2'b01:  immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      // B-type
      2'b10:  immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
      // J-type
      2'b11:  immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
      default: immext = 32'bx; // undefined
    endcase       
endmodule

// Datapath Pipeline register between Decode and Execution Stage. (valid bit removed)
module ID_IEx  (
  input  logic       clk, reset, clear,
  input  logic [31:0] RD1D, RD2D, PCD, 
  input  logic [4:0] Rs1D, Rs2D, RdD, 
  input  logic [31:0] ImmExtD, PCPlus4D,
  output logic [31:0] RD1E, RD2E, PCE, 
  output logic [4:0] Rs1E, Rs2E, RdE, 
  output logic [31:0] ImmExtE, PCPlus4E
);

  always_ff @( posedge clk, posedge reset ) begin
    if (reset) begin // Asynchronous reset
      RD1E     <= 0;
      RD2E     <= 0;
      PCE      <= 0;
      Rs1E     <= 0;
      Rs2E     <= 0;
      RdE      <= 0;
      ImmExtE  <= 0;
      PCPlus4E <= 0;
    end
    else if (clear) begin // Synchronous clear (flushes to 0)
      RD1E     <= 0;
      RD2E     <= 0;
      PCE      <= 0;
      Rs1E     <= 0;
      Rs2E     <= 0;
      RdE      <= 0;
      ImmExtE  <= 0;
      PCPlus4E <= 0;
    end
    else begin // Normal operation: latch inputs
      RD1E     <= RD1D;
      RD2E     <= RD2D;
      PCE      <= PCD;
      Rs1E     <= Rs1D;
      Rs2E     <= Rs2D;
      RdE      <= RdD;
      ImmExtE  <= ImmExtD;
      PCPlus4E <= PCPlus4D;
    end
  end
endmodule

// Parameterized 3-to-1 Multiplexer.
module mux3 #(parameter WIDTH=8)(
  input  logic [WIDTH-1:0] d0, d1, d2, 
  input  logic [1:0]       s,        
  output logic [WIDTH-1:0] y         
);
  assign y = s[1] ? d2 : (s[0] ? d1: d0);
endmodule

// Arithmetic Logic Unit (ALU).
module alu(
  input  logic [31:0] a, b,
  input  logic [3:0]  alucontrol,
  output logic [31:0] result,
  output logic        zero
);
  logic [31:0] condinvb, sum;
  logic        v; // overflow
  logic        isAddSub;
  wire signed [31:0] s1 = a;
  wire signed [31:0] s2 = b;

  // Logic for add/sub/slt
  assign condinvb = alucontrol[0] ? ~b : b; // Invert b for subtraction
  assign sum      = a + condinvb + alucontrol[0]; // Add/Sub
  assign isAddSub = ~alucontrol[2] & ~alucontrol[1] |
                    ~alucontrol[1] & alucontrol[0];

// Main ALU operation logic
  always_comb
    case (alucontrol)
      // ---- original arithmetic/logic ----
      4'b0000:  result = sum; // add
      4'b0001:  result = sum; // subtract
      4'b0010:  result = a & b; // and
      4'b0011:  result = a | b; // or
      4'b0100:  result = a ^ b; // xor
      4'b0101:  result = sum[31] ^ v; // slt 

      // ---- new ops starting from 0110 (RVX10) ----
      4'b0110:  result = a & ~b; // ANDN
      4'b0111:  result = a | ~b; // ORN
      4'b1000:  result = ~(a ^ b); // XNOR 
      4'b1001:  result = (s1 < s2) ? a : b; // MIN (signed)
      4'b1010:  result = (s1 > s2) ? a : b; // MAX (signed)
      4'b1011:  result = (a  < b)  ? a : b; // MINU (unsigned)
      4'b1100:  result = (a  > b)  ? a : b; // MAXU (unsigned)
      4'b1101: begin // ROL (Rotate Left)
          logic [4:0] sh = b[4:0];
          result = (sh == 0) ? a : ((a << sh) | (a >> (32 - sh)));
      end
      4'b1110: begin // ROR (Rotate Right)
          logic [4:0] sh = b[4:0];
          result = (sh == 0) ? a : ((a >> sh) | (a << (32 - sh)));
      end
      4'b1111:  result = (s1 >= 0) ? a : (0 - a); // ABS (Absolute Value)
      default:  result = 32'bx;
  endcase

// Zero flag logic
  assign zero = (result == 32'b0);
// Overflow logic (for 'slt')
  assign v    = ~(alucontrol[0] ^ a[31] ^ b[31]) & (a[31] ^ sum[31]) & isAddSub;
endmodule

// Datapath Pipeline register between Execution and Memory Access Stage. (valid bit removed)
module IEx_IMem(
  input  logic       clk, reset,
  input  logic [31:0] ALUResultE, WriteDataE, 
  input  logic [4:0] RdE, 
  input  logic [31:0] PCPlus4E,
  output logic [31:0] ALUResultM, WriteDataM,
  output logic [4:0] RdM, 
  output logic [31:0] PCPlus4M
);
  always_ff @( posedge clk, posedge reset ) begin 
    if (reset) begin // Asynchronous reset
      ALUResultM <= 0;
      WriteDataM <= 0;
      RdM        <= 0; 
      PCPlus4M   <= 0;
    end
    else begin // Normal operation: latch inputs
      ALUResultM <= ALUResultE;
      WriteDataM <= WriteDataE;
      RdM        <= RdE; 
      PCPlus4M   <= PCPlus4E;
    end
  end
endmodule

// Datapath Pipeline register between Memory Access and WriteBack Stage. (valid bit removed)
module IMem_IW (
  input  logic       clk, reset,
  input  logic [31:0] ALUResultM, ReadDataM,  
  input  logic [4:0] RdM, 
  input  logic [31:0] PCPlus4M,
  output logic [31:0] ALUResultW, ReadDataW,
  output logic [4:0] RdW, 
  output logic [31:0] PCPlus4W
);
  always_ff @( posedge clk, posedge reset ) begin 
    if (reset) begin // Asynchronous reset
      ALUResultW <= 0;
      ReadDataW  <= 0;
      RdW        <= 0; 
      PCPlus4W   <= 0;
    end
    else begin // Normal operation: latch inputs
      ALUResultW <= ALUResultM;
      ReadDataW  <= ReadDataM;
      RdW        <= RdM; 
      PCPlus4W   <= PCPlus4M;
    end
  end
endmodule