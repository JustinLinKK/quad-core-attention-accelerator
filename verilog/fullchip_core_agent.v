module fullchip_core_agent (
    core_clk,
    reset,
    cfg_core_enable,
    cfg_multi_core_inst,
    cfg_sfp_acc_inst,
    cfg_sfp_div_inst,
    cmd_valid,
    cmd_ready,
    cmd_payload,
    load_row_valid,
    load_row_ready,
    load_row_data,
    core_ofifo_valid,
    busy,
    q_load_done,
    k_load_done,
    mem_in,
    inst_word
);

parameter bw = 8;
parameter pr = 8;
parameter spad_rows_max = 16;
parameter mac_settle_cycles = 10;
localparam row_w = pr * bw;
localparam cmd_payload_w = 2 + 1 + 8 + 8;
localparam inst_w = 23;

localparam [1:0] op_none   = 2'b00;
localparam [1:0] op_load   = 2'b01;
localparam [1:0] op_run    = 2'b10;
localparam [1:0] op_cfg_b2 = 2'b11;

localparam [3:0] st_idle          = 4'd0;
localparam [3:0] st_load          = 4'd1;
localparam [3:0] st_run_warm      = 4'd2;
localparam [3:0] st_run_pre       = 4'd3;
localparam [3:0] st_run_mac       = 4'd4;
localparam [3:0] st_run_post      = 4'd5;
localparam [3:0] st_run_pmem      = 4'd6;
localparam [3:0] st_run_pmem_wait = 4'd7;
localparam [3:0] st_cfg_b2        = 4'd8;

input core_clk;
input reset;
input cfg_core_enable;
input cfg_multi_core_inst;
input cfg_sfp_acc_inst;
input cfg_sfp_div_inst;
input cmd_valid;
input [cmd_payload_w-1:0] cmd_payload;
input load_row_valid;
input [row_w-1:0] load_row_data;
input core_ofifo_valid;

output cmd_ready;
output load_row_ready;
output busy;
output q_load_done;
output k_load_done;
output reg [row_w-1:0] mem_in;
output reg [inst_w-1:0] inst_word;

reg [3:0] state;
reg load_is_q_q;
reg [7:0] active_q_len_q;
reg [7:0] active_len_q;
reg [7:0] idx_q;

wire [1:0] cmd_op;
wire cmd_load_is_q;
wire [7:0] cmd_q_len;
wire [7:0] cmd_len;

assign cmd_op = cmd_payload[cmd_payload_w-1 -: 2];
assign cmd_load_is_q = cmd_payload[cmd_payload_w-3];
assign cmd_q_len = cmd_payload[cmd_payload_w-4 -: 8];
assign cmd_len = cmd_payload[cmd_payload_w-12 -: 8];
assign cmd_ready = (state == st_idle);
assign load_row_ready = (state == st_load) || (state == st_cfg_b2);
assign busy = (state != st_idle);
assign q_load_done = (state == st_load) && load_row_valid && load_is_q_q &&
                     (idx_q + 1'b1 >= active_len_q);
assign k_load_done = (state == st_load) && load_row_valid && !load_is_q_q &&
                     (idx_q + 1'b1 >= active_len_q);

always @* begin
    mem_in = {row_w{1'b0}};
    inst_word = {inst_w{1'b0}};
    inst_word[20] = cfg_core_enable;
    inst_word[19] = cfg_multi_core_inst;
    inst_word[18] = cfg_sfp_acc_inst;
    inst_word[17] = cfg_sfp_div_inst;

    case (state)
        st_load: begin
            if (load_row_valid) begin
                mem_in = load_row_data;
                inst_word[15:12] = idx_q[3:0];
                if (load_is_q_q)
                    inst_word[4] = 1'b1;
                else
                    inst_word[2] = 1'b1;
            end
        end

        st_run_warm: begin
            inst_word[6] = 1'b1;
            if ((idx_q >= 1'b1) && (idx_q <= active_len_q)) begin
                inst_word[3] = 1'b1;
                inst_word[15:12] = idx_q - 1'b1;
            end
        end

        st_run_mac: begin
            inst_word[7] = 1'b1;
            inst_word[5] = 1'b1;
            inst_word[15:12] = idx_q[3:0];
        end

        st_run_pmem: begin
            if (core_ofifo_valid) begin
                inst_word[0] = 1'b1;
                inst_word[11:8] = idx_q[3:0];
            end
        end

        st_cfg_b2: begin
            if (load_row_valid) begin
                mem_in = load_row_data;
                inst_word[18] = 1'b0;
                inst_word[17] = 1'b0;
                inst_word[16] = 1'b1;
                inst_word[15:12] = {3'b000, load_is_q_q};
            end
        end

        default: begin
        end
    endcase
end

always @(posedge core_clk) begin
    if (reset) begin
        state <= st_idle;
        load_is_q_q <= 1'b0;
        active_q_len_q <= 8'd0;
        active_len_q <= 8'd0;
        idx_q <= 8'd0;
    end else begin
        case (state)
            st_idle: begin
                if (cmd_valid) begin
                    load_is_q_q <= cmd_load_is_q;
                    active_q_len_q <= cmd_q_len;
                    active_len_q <= cmd_len;
                    idx_q <= 8'd0;

                    if (cmd_op == op_load)
                        state <= st_load;
                    else if (cmd_op == op_run)
                        state <= st_run_warm;
                    else if (cmd_op == op_cfg_b2)
                        state <= st_cfg_b2;
                end
            end

            st_load: begin
                if (load_row_valid) begin
                    if (idx_q + 1'b1 >= active_len_q) begin
                        state <= st_idle;
                    end else begin
                        idx_q <= idx_q + 1'b1;
                    end
                end
            end

            st_run_warm: begin
                if (idx_q >= active_len_q + 1'b1) begin
                    idx_q <= 8'd0;
                    state <= st_run_pre;
                end else begin
                    idx_q <= idx_q + 1'b1;
                end
            end

            st_run_pre: begin
                if (idx_q + 1'b1 >= mac_settle_cycles) begin
                    idx_q <= 8'd0;
                    state <= st_run_mac;
                end else begin
                    idx_q <= idx_q + 1'b1;
                end
            end

            st_run_mac: begin
                if (idx_q + 1'b1 >= active_q_len_q) begin
                    idx_q <= 8'd0;
                    state <= st_run_post;
                end else begin
                    idx_q <= idx_q + 1'b1;
                end
            end

            st_run_post: begin
                if (idx_q + 1'b1 >= mac_settle_cycles) begin
                    idx_q <= 8'd0;
                    state <= st_run_pmem;
                end else begin
                    idx_q <= idx_q + 1'b1;
                end
            end

            st_run_pmem: begin
                if (core_ofifo_valid) begin
                    state <= st_run_pmem_wait;
                end
            end

            st_run_pmem_wait: begin
                if (idx_q + 1'b1 >= active_q_len_q) begin
                    state <= st_idle;
                end else begin
                    idx_q <= idx_q + 1'b1;
                    state <= st_run_pmem;
                end
            end

            st_cfg_b2: begin
                if (load_row_valid)
                    state <= st_idle;
            end

            default: begin
                state <= st_idle;
            end
        endcase
    end
end

endmodule
