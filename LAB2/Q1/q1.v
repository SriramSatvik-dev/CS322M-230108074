module q1(
    input wire clk,
    input wire rst,
    input wire din,
    output reg y
);

parameter S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;
reg [1:0] cur_state, next_state;

always @ (posedge clk) 
begin
    if(rst) cur_state <= S0;
    else cur_state <= next_state;
end

always @ (*) begin
    case(cur_state)
        S0: begin
            if(din) begin
                next_state = S1;
                y=0;
            end
            else begin
                next_state = S0;
                y=0;
            end
        end
        S1: begin
            if(din) begin
                next_state = S2;
                y=0;
            end
            else begin
                next_state = S0;
                y=0;
            end
        end
        S2: begin
            if(din) begin
                next_state = S2;
                y=0;
            end
            else begin
                next_state = S3;
                y=0;
            end
        end
        S3: begin
            if(din) begin
                next_state = S1;
                y=1;
            end
            else begin
                next_state = S0;
                y=0;
            end
        end
        default: begin
            next_state = cur_state;
            y=0;
        end
    endcase
end
endmodule