`timescale 10ns/10ns
`include "q2.v"

module tb_q2;

reg [3:0] A,B;
wire Z;

q2 temp(.A(A),.B(B),.z(Z));

initial begin
    $dumpfile("q2.vcd");
    $dumpvars(0,tb_q2);

    A = 4'b0000; B = 4'b0000; #10;
    A = 4'b1010; B = 4'b1010; #10;
    A = 4'b1111; B = 4'b0000; #10;
    A = 4'b0101; B = 4'b1101; #10;
    A = 4'b1001; B = 4'b1001; #10;

    $finish;
end
endmodule;