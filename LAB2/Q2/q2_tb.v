`timescale 1ns/1ns
`include "q2.v"

module q2_tb;

    reg clk, rst;
    wire ns_g, ns_y, ns_r, ew_g, ew_y, ew_r;

    q2 dut (
        .clk(clk),
        .rst(rst),
        .ns_g(ns_g), .ns_y(ns_y), .ns_r(ns_r),
        .ew_g(ew_g), .ew_y(ew_y), .ew_r(ew_r)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, q2_tb);

        clk = 0;
        rst = 1;

        #12;
        rst = 0;

        #300;
        $finish;
    end

    // initial begin
    //     $display("Time\tclk\trst\tNS(g,y,r)\tEW(g,y,r)");
    //     $monitor("%0t\t%b\t%b\t%b %b %b\t%b %b %b",
    //              $time, clk, rst,
    //              ns_g, ns_y, ns_r,
    //              ew_g, ew_y, ew_r);
    // end

endmodule