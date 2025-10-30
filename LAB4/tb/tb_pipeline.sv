`timescale 1ns / 1ps
// Testbench for the Pipelined RISC-V Processor (riscvpipeline)
module testbench_pipelined();

  logic        clk;
  logic        reset;
// Wires connected to the top module (riscvpipeline)
  logic [31:0] WriteDataM; // Write data from MEM stage
  logic [31:0] DataAdrM;   // Data address from MEM stage
  logic        MemWriteM;  // Memory write enable from MEM stage

  // Instantiate the Device Under Test (DUT) - the pipelined top module
  riscvpipeline dut(
    .clk        (clk),
    .reset      (reset),
    .WriteDataM (WriteDataM),
    .DataAdrM   (DataAdrM),
    .MemWriteM  (MemWriteM)
  );

// Initialize clock and reset
  initial begin
    clk <= 0;
    reset <= 1; 
    # 22; // Hold reset high
    reset <= 0;
  end

  // Generate clock signal (10ns period)
  always begin
    # 5; clk <= ~clk;
  end
  
// Check results on the Memory Stage signals (M-stage)
// This is the correct check for a pipelined store operation.
  always @(negedge clk) begin
    if (MemWriteM) begin
      // Success criteria: Write 25 to address 100 
      if (DataAdrM === 100 & WriteDataM === 25) begin
        $display("----------------------------------------");
        $display("Simulation succeeded: Data written to memory.");
        $display("WriteDataM=%0d at DataAdrM=%0d (Expected: 25 at 100)", WriteDataM, DataAdrM);
        // Print Performance Counters using the hierarchical path: dut (riscvpipeline) -> rv (riscv)
        $display("--- PERFORMANCE: Cycles=%0d | Retired Instructions=%0d ---", dut.rv.cycle_count, dut.rv.instr_retired);
        // ADD A SMALL DELAY (#1) BEFORE READING THE RAM
        # 10;
        $display("VERIFICATION: Stored value in dmem[100] is %0d (0x%0h)", 
                 dut.dmem.RAM[100/4], dut.dmem.RAM[100/4]); 
        
        $display("----------------------------------------");
        $stop;
      end else if (DataAdrM !== 96) begin
        // If it's a store but not to the expected address
        $display("Simulation failed: Unexpected store operation.");
        $display("DataAdrM=0x%0h WriteDataM=0x%0h", DataAdrM, WriteDataM);
        $stop;
      end
    end
  end
  
  // Display current state every positive clock edge
  always @(posedge clk) begin
    $display("Cycle=%0d | MEM Stage: MemWriteM=%b DataAdrM=0x%0h WriteDataM=0x%0h",
      $time/10, dut.MemWriteM, dut.DataAdrM, dut.WriteDataM);
  end

  // VCD dump
  initial begin
    $dumpfile("wave_pipelined.vcd");
    $dumpvars(0, testbench_pipelined);
   

  end
  
  // Safety stop after 50 cycles if success isn't met
  initial begin
    # 500; 
    $display("Simulation terminated after 50 cycles.");
    $finish;
  end
  
endmodule