`timescale 1ns/1ns
`include "assignment1.v"

module tb_assignment1;
reg A,B;
wire O1,O2,O3;

assignment1 temp(.A(A),.B(B),.O1(O1),.O2(O2),.O3(O3));

initial begin 
    $dumpfile("assignment1.vcd");
    $dumpvars(0, tb_assignment1);

    A=0; B=0;
    #10;
    A=0; B=1;
    #10;
    A=1; B=0;
    #10;
    A=1; B=1;

    $finish;
end
endmodule