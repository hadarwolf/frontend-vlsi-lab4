module sin_gen(
    input logic clk,
    input logic resetb,
    input logic en,
    input logic [7:0] period_sel,
    output logic signed [8:0] sin_out);


typedef enum logic [1:0] {IDLE,START, RUN} state_t;
state_t cur_state, next_state;

logic [7:0] period_reg, period_reg_next;
logic [7:0] hold_cnt, hold_cnt_next;


logic [9:0] phase_cnt, phase_cnt_next;

logic sample_tick;

//ROM interfae



logic [7:0] lut_addr;
logic [7:0] lut_dout;
logic neg;

logic signed [8:0] sin_next;

sin_lut u_sin_lut(
    .address(lut_addr),
    .dout(lut_dout)
);

always_comb begin
    unique case (phase_cnt[9:8])
        2'b00:begin lut_addr =  phase_cnt[7:0]; 
                neg = 1'b0;
                end
        2'b01:begin neg = 1'b0;
            lut_addr = 8'hFF - phase_cnt[7:0];
            end
        2'b10:begin neg = 1'b1; 
                lut_addr = phase_cnt[7:0]; 
                end
        2'b11:begin neg = 1'b1; 
                lut_addr = 8'hFF - phase_cnt[7:0]; 
                end
    endcase
end

always_ff @(posedge clk or negedge resetb) begin
    if (~resetb) begin
        cur_state <= IDLE;
        period_reg <= 8'h00;
        hold_cnt <= 8'h00;
        phase_cnt <= 8'h00;
    end else begin
        cur_state <= next_state;
        period_reg <= period_reg_next;
        hold_cnt <= hold_cnt_next;
        phase_cnt <= phase_cnt_next;
        sin_out <= sin_next;
    end
end

always_comb begin
    next_state = cur_state;
    period_reg_next = period_reg;
    hold_cnt_next = hold_cnt;
    phase_cnt_next = phase_cnt;
    sin_next = sin_out;
    sample_tick = 1'b0;
    unique case (cur_state)
        IDLE: begin
            sin_next = '0;
            hold_cnt_next = 8'h00;
            phase_cnt_next = 8'h00;
            if (en) begin
                next_state = START;
            end
            end
        START: begin
            period_reg_next = period_sel;
            hold_cnt_next = 8'h00;
            phase_cnt_next = 8'h00;
            if(neg)
                sin_next = -$signed({1'b0,lut_dout});
            else
                sin_next = $signed({1'b0,lut_dout});
            if (en)
                next_state = RUN;
            else
                next_state = IDLE;
        end
        RUN: begin
            if(hold_cnt == period_reg) begin
                sample_tick = 1'b1;
                hold_cnt_next = 8'h00;

                if(phase_cnt == 10'd1023) begin
                    phase_cnt_next = 10'd0;

                    if(neg)
                        sin_next = -$signed({1'b0,lut_dout});
                    else
                        sin_next = $signed({1'b0,lut_dout});

                    if (en)
                        next_state = START;
                    else
                        next_state = IDLE;
                end else begin
                    phase_cnt_next = phase_cnt + 1;
                    if(neg)
                        sin_next = -$signed({1'b0,lut_dout});
                    else
                        sin_next = $signed({1'b0,lut_dout});
                end
            end else begin
                hold_cnt_next = hold_cnt + 1;
            end
        end
        default: begin
            next_state = IDLE;
        end
    endcase
end

endmodule