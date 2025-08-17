module slave_fsm(
    input  wire       clk,
    input  wire       rst,
    input  wire       req,
    input  wire [7:0] data_in,
    output reg        ack,
    output reg [7:0]  last_byte
);

    reg [1:0] state, next_state;
    reg [1:0] ack_cnt;

    localparam IDLE    = 2'd0,
               ACK_HI  = 2'd1,
               ACK_HOLD = 2'd2,
               ACK_LO  = 2'd3;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            ack   <= 0;
            last_byte <= 8'h00;
            ack_cnt <= 0;
        end else begin
            state <= next_state;
            if (state == ACK_HI) begin
                ack <= 1;
                last_byte <= data_in;
                ack_cnt <= 2;
            end else if (state == ACK_HOLD && ack_cnt > 0) begin
                ack_cnt <= ack_cnt - 1;
                ack <= 1;
            end else if (state == ACK_LO) begin
                ack <= 0;
            end
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (req) next_state = ACK_HI;
            ACK_HI: next_state = ACK_HOLD;
            ACK_HOLD: if (ack_cnt == 0) next_state = ACK_LO;
            ACK_LO: if (!req) next_state = IDLE;
        endcase
    end

endmodule