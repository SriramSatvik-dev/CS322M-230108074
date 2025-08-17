`timescale 1ns/1ns
`include "q3.v"

module tb_q3;

    reg clk = 0, rst = 1;
    reg [1:0] coin = 2'b00;     // 01 = 5, 10 = 10, 00 = idle
    wire dispense, chg5;

    // DUT instantiation
    q3 dut (
        .clk(clk),
        .rst(rst),
        .coin(coin),
        .dispense(dispense),
        .chg5(chg5)
    );

    // Clock: 10 ns period
    always #5 clk = ~clk;

    // VCD dump for GTKWave
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_q3);
    end

    // Console monitor
    // initial begin
    //     $display(" time | coin dispense chg5");
    //     $monitor("%4t |  %b      %b       %b",
    //              $time, coin, dispense, chg5);
    // end

    // Stimulus
    initial begin
        // Reset for 2 cycles
        repeat(2) @(posedge clk);
        rst = 0;

        // Case 1: 5 + 5 + 10 = 20 (dispense)
        pay5(); pay5(); pay10();
        @(posedge clk);

        // Case 2: 10 + 10 = 20 (dispense)
        pay10(); pay10();
        @(posedge clk);

        // Case 3: 5 + 10 + 10 = 25 (dispense + change)
        pay5(); pay10(); pay10();
        @(posedge clk);

        // Case 4: 10 + 5 + 10 = 25 (dispense + change)
        pay10(); pay5(); pay10();
        @(posedge clk);

        // Case 5: Overpay with (10 + 10 + 5) → should reset after dispense
        pay10(); pay10(); pay5();
        @(posedge clk);

        #30 $finish;
    end

    // --- helper tasks for coins ---
    task pay5; begin
        @(negedge clk); coin = 2'b01;
        @(posedge clk); // sampled
        @(negedge clk); coin = 2'b00; // release
    end endtask

    task pay10; begin
        @(negedge clk); coin = 2'b10;
        @(posedge clk);
        @(negedge clk); coin = 2'b00;
    end endtask

endmodule
