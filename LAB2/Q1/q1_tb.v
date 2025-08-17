`timescale 1ns/1ns
`include "q1.v"

module tb_q1;

    reg clk, rst, din;
    wire y;

    q1 uut (
        .clk(clk),
        .rst(rst),
        .din(din),
        .y(y)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_q1);

        clk = 0;
        rst = 1;
        din = 0;

        #10;
        rst = 0;

        #10 din = 1;
        #10 din = 1;
        #10 din = 0;
        #10 din = 1;
        #10 din = 0;
        #10 din = 1;
        #10 din = 1;
        #10 din = 1;
        #10 din = 0;
        #10 din = 1;

        #20 $finish;
    end

endmodule
