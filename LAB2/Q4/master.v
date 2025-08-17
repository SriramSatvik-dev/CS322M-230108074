module master_fsm(
    input  wire       clk,
    input  wire       rst,
    input  wire       ack,
    output reg        req,
    output reg  [7:0] data,
    output reg        done 
);

    reg [2:0] state, next_state;
    reg [1:0] byte_cnt;

    localparam IDLE   = 3'd0,
               SEND   = 3'd1,
               WAIT_ACK = 3'd2,
               DROP_REQ = 3'd3,
               WAIT_ACK_LOW = 3'd4,
               FINISH = 3'd5;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            req   <= 0;
            data  <= 8'h00;
            byte_cnt <= 0;
            done  <= 0;
        end else begin
            state <= next_state;
            if (state == FINISH)
                done <= 1;
            else
                done <= 0;
        end
    end

    // Next state and outputs
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                req = 0;
                next_state = SEND;
            end

            SEND: begin
                req = 1;
                next_state = WAIT_ACK;
            end

            WAIT_ACK: begin
                req = 1;
                if (ack)
                    next_state = DROP_REQ;
            end

            DROP_REQ: begin
                req = 0;
                next_state = WAIT_ACK_LOW;
            end

            WAIT_ACK_LOW: begin
                req = 0;
                if (!ack) begin
                    if (byte_cnt == 2'd3)
                        next_state = FINISH;
                    else
                        next_state = SEND;
                end
            end

            FINISH: begin
                req = 0;
                next_state = IDLE;
            end
        endcase
    end

    // Data & byte counter updates
    always @(posedge clk) begin
        if (rst) begin
            byte_cnt <= 0;
            data <= 8'h00;
        end else begin
            if (state == SEND) begin
                data <= {6'b0, byte_cnt};
            end
            if (state == WAIT_ACK_LOW && !ack && state != FINISH) begin
                byte_cnt <= byte_cnt + 1;
            end
            if (state == FINISH)
                byte_cnt <= 0;
        end
    end

endmodule