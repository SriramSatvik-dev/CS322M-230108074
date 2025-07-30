module q2(
    input [3:0] A,B,
    output z
);

wire [3:0] tempvar;
assign tempvar=~(A^B);
assign z=&tempvar;

endmodule;