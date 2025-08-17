module q3(
    input wire clk,
    input wire rst,
    input wire [1:0] coin,
    output reg dispense,
    output reg chg5
);

parameter S0=3'b000,
          S5=3'b001,
          S10=3'b010,
          S15=3'b011,
          S20=3'b100;

reg [2:0] cur_state, next_state;

always @ (posedge clk) begin
    if(rst) begin
        cur_state <= S0;
    end
    else begin
        cur_state <= next_state;
    end
end

always @ (*) begin
    dispense = 0;
    chg5 = 0;
    
    case(cur_state)
        S0: begin
            if(coin == 2'b01)      // 5-unit coin
                next_state = S5;
            else if(coin == 2'b10) // 10-unit coin
                next_state = S10;
            else                   // idle (coin == 2'b00 or invalid)
                next_state = cur_state;
        end
        
        S5: begin
            if(coin == 2'b01)      // 5 + 5 = 10
                next_state = S10;
            else if(coin == 2'b10) // 5 + 10 = 15
                next_state = S15;
            else                   // idle
                next_state = cur_state;
        end
        
        S10: begin
            if(coin == 2'b01)      // 10 + 5 = 15
                next_state = S15;
            else if(coin == 2'b10) // 10 + 10 = 20 (exact payment)
                next_state = S20;
            else                   // idle
                next_state = cur_state;
        end
        
        S15: begin
            if(coin == 2'b01) begin
                next_state = S20;
            end
            else if(coin == 2'b10) begin
                next_state = S0;
                dispense = 1;
                chg5 = 1;
            end
            else
                next_state = cur_state;
        end
        
        S20: begin
            next_state = S0;
            dispense = 1;
        end
        
        default: begin
            next_state = S0;
        end
    endcase
end

endmodule