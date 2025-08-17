module q2(
    input wire clk,
    input wire rst,
    output reg ns_g,ns_y,ns_r,
    output reg ew_g,ew_y,ew_r
);

parameter s_ns_g=2'b00,s_ns_y=2'b01,s_ew_g=2'b10,s_ew_y=2'b11;
reg cur_state,next_state;
reg [2:0] timer;

always @ (posedge clk) begin
    if(rst) begin
        cur_state <= s_ns_g;
        timer <= 3'd0;
    end
    else begin
        cur_state <= next_state;
        if(cur_state!=next_state) timer <= 3'd0;
        else timer <= timer+1;
    end
end

always @ (*) begin
    next_state = cur_state;
    case(cur_state)
        s_ns_g: if(timer==3'd4) next_state=s_ns_y;
        s_ns_y: if(timer==3'd1) next_state=s_ew_g;
        s_ew_g: if(timer==3'd4) next_state=s_ew_y;
        s_ew_y: if(timer==3'd1) next_state=s_ns_g;
    endcase
end

always @ (*) begin
    ns_g=0;
    ns_y=0;
    ns_r=0;
    ew_g=0;
    ew_y=0;
    ew_r=0;
    case(cur_state) 
        s_ns_g: begin
            ns_g=1;
            ew_r=1;
        end
        s_ns_y: begin
            ns_y=1;
            ew_r=1;
        end
        s_ew_g: begin
            ew_g=1;
            ns_r=1;
        end
        s_ew_y: begin
            ew_y=1;
            ns_r=1;
        end
    endcase
end
endmodule