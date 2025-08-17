`timescale 1ns/1ns
`include "top.v"

module tb_link_top;
    reg clk, rst;
    wire done;

    link_top dut(.clk(clk), .rst(rst), .done(done));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        #12 rst = 0;
        wait(done);
        #10 $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_link_top);
    end
endmodule