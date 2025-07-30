module assignment1(
    input A,B,
    output O1,O2,O3
);

assign O1=A&(~B);
assign O2=~(A^B);
assign O3=(~A)&B;

endmodule;