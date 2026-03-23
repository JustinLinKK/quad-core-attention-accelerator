module fullchip_spad_controller (
    clk,
    reset,
    cfg_core_enable_mask,
    load_start,
    load_is_q,
    load_core_mask,
    load_len,
    load_base,
    run_start,
    run_q_len,
    run_k_len,
    b2_cfg_start,
    b2_cfg_core_mask,
    b2_cfg_addr,
    core_agent_busy,
    cmd_valid,
    cmd_ready,
    cmd_core_mask,
    cmd_payload_bus,
    load_row_valid,
    load_row_ready,
    load_row_core_mask,
    busy,
    done,
    spad_rd_req_valid,
    spad_rd_req_ready,
    spad_rd_addr,
    spad_rd_rsp_valid,
    spad_rd_rsp_ready
);

parameter num_cores = 4;
parameter bw = 8;
parameter pr = 8;
parameter spad_rows_max = 16;
localparam cmd_payload_w = 2 + 1 + 8 + 8;

localparam [1:0] op_none   = 2'b00;
localparam [1:0] op_load   = 2'b01;
localparam [1:0] op_run    = 2'b10;
localparam [1:0] op_cfg_b2 = 2'b11;

localparam [2:0] st_idle      = 3'd0;
localparam [2:0] st_load_req  = 3'd1;
localparam [2:0] st_load_wait = 3'd2;
localparam [2:0] st_issue     = 3'd3;
localparam [2:0] st_wait_busy = 3'd4;
localparam [2:0] st_done      = 3'd5;

input clk;
input reset;
input [num_cores-1:0] cfg_core_enable_mask;
input load_start;
input load_is_q;
input [num_cores-1:0] load_core_mask;
input [7:0] load_len;
input [7:0] load_base;
input run_start;
input [7:0] run_q_len;
input [7:0] run_k_len;
input b2_cfg_start;
input [num_cores-1:0] b2_cfg_core_mask;
input [7:0] b2_cfg_addr;
input [num_cores-1:0] core_agent_busy;
input cmd_ready;
input load_row_ready;
input spad_rd_req_ready;
input spad_rd_rsp_valid;

output busy;
output reg done;
output reg cmd_valid;
output reg [num_cores-1:0] cmd_core_mask;
output reg [num_cores*cmd_payload_w-1:0] cmd_payload_bus;
output reg load_row_valid;
output reg [num_cores-1:0] load_row_core_mask;
output reg spad_rd_req_valid;
output reg [7:0] spad_rd_addr;
output spad_rd_rsp_ready;

reg [2:0] state;
reg active_load_is_q;
reg [num_cores-1:0] active_cmd_mask;
reg [7:0] active_load_len;
reg [7:0] active_load_base;
reg [7:0] active_run_q_len;
reg [7:0] active_run_k_len;
reg [7:0] idx_q;
reg [1:0] active_op;
reg busy_seen_any;
integer core_idx;

assign busy = (state != st_idle);
assign spad_rd_rsp_ready = (state == st_load_wait) && load_row_ready;

always @(posedge clk) begin
    if (reset) begin
        state <= st_idle;
        active_load_is_q <= 1'b0;
        active_cmd_mask <= {num_cores{1'b0}};
        active_load_len <= 8'd0;
        active_load_base <= 8'd0;
        active_run_q_len <= 8'd0;
        active_run_k_len <= 8'd0;
        idx_q <= 8'd0;
        active_op <= op_none;
        busy_seen_any <= 1'b0;

        done <= 1'b0;
        cmd_valid <= 1'b0;
        cmd_core_mask <= {num_cores{1'b0}};
        cmd_payload_bus <= {num_cores*cmd_payload_w{1'b0}};
        load_row_valid <= 1'b0;
        load_row_core_mask <= {num_cores{1'b0}};
        spad_rd_req_valid <= 1'b0;
        spad_rd_addr <= 8'd0;
    end else begin
        done <= 1'b0;
        cmd_valid <= 1'b0;
        cmd_core_mask <= {num_cores{1'b0}};
        cmd_payload_bus <= {num_cores*cmd_payload_w{1'b0}};
        load_row_valid <= 1'b0;
        load_row_core_mask <= {num_cores{1'b0}};
        spad_rd_req_valid <= 1'b0;

        case (state)
            st_idle: begin
                busy_seen_any <= 1'b0;
                if (load_start && (load_len != 8'd0)) begin
                    active_load_is_q <= load_is_q;
                    active_cmd_mask <= load_core_mask & cfg_core_enable_mask;
                    active_load_len <= load_len;
                    active_load_base <= load_base;
                    active_run_q_len <= 8'd0;
                    active_run_k_len <= 8'd0;
                    idx_q <= 8'd0;
                    active_op <= op_load;
                    state <= st_issue;
                end else if (run_start && (run_q_len != 8'd0) && (run_k_len != 8'd0)) begin
                    active_load_is_q <= 1'b0;
                    active_cmd_mask <= cfg_core_enable_mask;
                    active_load_len <= 8'd0;
                    active_load_base <= 8'd0;
                    active_run_q_len <= run_q_len;
                    active_run_k_len <= run_k_len;
                    idx_q <= 8'd0;
                    active_op <= op_run;
                    state <= st_issue;
                end else if (b2_cfg_start) begin
                    active_load_is_q <= b2_cfg_addr[0];
                    active_cmd_mask <= b2_cfg_core_mask & cfg_core_enable_mask;
                    active_load_len <= 8'd1;
                    active_load_base <= {2'b00, b2_cfg_addr[5:0]};
                    active_run_q_len <= 8'd0;
                    active_run_k_len <= 8'd0;
                    idx_q <= 8'd0;
                    active_op <= op_cfg_b2;
                    state <= st_issue;
                end
            end

            st_issue: begin
                cmd_valid <= 1'b1;
                cmd_core_mask <= active_cmd_mask;
                for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1) begin
                    cmd_payload_bus[(core_idx*cmd_payload_w) +: cmd_payload_w] <= {
                        active_op,
                        active_load_is_q,
                        active_run_q_len,
                        (active_op == op_run) ? active_run_k_len : active_load_len
                    };
                end

                if (cmd_ready) begin
                    busy_seen_any <= 1'b0;
                    if ((active_op != op_run) && (active_cmd_mask != {num_cores{1'b0}}))
                        state <= st_load_req;
                    else
                        state <= st_wait_busy;
                end
            end

            st_load_req: begin
                spad_rd_req_valid <= 1'b1;
                spad_rd_addr <= active_load_base + idx_q;
                if (spad_rd_req_ready)
                    state <= st_load_wait;
            end

            st_load_wait: begin
                if (spad_rd_rsp_valid && load_row_ready) begin
                    load_row_valid <= 1'b1;
                    load_row_core_mask <= active_cmd_mask;
                    if (idx_q + 1'b1 >= active_load_len) begin
                        state <= st_wait_busy;
                    end else begin
                        idx_q <= idx_q + 1'b1;
                        state <= st_load_req;
                    end
                end
            end

            st_wait_busy: begin
                if (|(core_agent_busy & active_cmd_mask))
                    busy_seen_any <= 1'b1;

                if ((active_cmd_mask == {num_cores{1'b0}}) ||
                    (busy_seen_any &&
                     ((core_agent_busy & active_cmd_mask) == {num_cores{1'b0}}))) begin
                    state <= st_done;
                end
            end

            st_done: begin
                done <= 1'b1;
                state <= st_idle;
            end

            default: begin
                state <= st_idle;
            end
        endcase
    end
end

endmodule
