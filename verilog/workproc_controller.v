module workproc_controller (
    clk, reset,
    rx_valid, rx_data, rx_ready,
    tx_valid, tx_data, tx_last, tx_ready,
    mem_in, mem_in_mask, inst, multi_core_inst, core_enable_mask, group_link, sfp_acc_inst, sfp_div_inst, ext_sum_wr, sum_in,
    sum_out, sum_valid, ext_sum_empty, out, core_status
);

parameter num_cores = 4;
parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+6;
parameter sum_out_bw = bw_psum + 4;
parameter sum_in_bw = sum_out_bw + 2;

input clk;
input reset;

input rx_valid;
input [63:0] rx_data;
output rx_ready;

output tx_valid;
output [63:0] tx_data;
output tx_last;
input tx_ready;

output [63:0] mem_in;
output [num_cores-1:0] mem_in_mask;
output [16:0] inst;
output [num_cores-1:0] multi_core_inst;
output [num_cores-1:0] core_enable_mask;
output [num_cores-2:0] group_link;
output [num_cores-1:0] sfp_acc_inst;
output [num_cores-1:0] sfp_div_inst;
output ext_sum_wr;
output [sum_in_bw-1:0] sum_in;

input [sum_out_bw-1:0] sum_out;
input sum_valid;
input ext_sum_empty;
input [bw_psum*col-1:0] out;
input [num_cores*12-1:0] core_status;

reg rx_ready;
reg tx_valid;
reg [63:0] tx_data;
reg tx_last;
reg [63:0] mem_in;
reg [num_cores-1:0] mem_in_mask;
reg [16:0] inst;
reg [num_cores-1:0] multi_core_inst;
reg [num_cores-1:0] core_enable_mask;
reg [num_cores-2:0] group_link;
reg [num_cores-1:0] sfp_acc_inst;
reg [num_cores-1:0] sfp_div_inst;
reg ext_sum_wr;
reg [sum_in_bw-1:0] sum_in;

localparam [7:0] opc_cfg         = 8'h01;
localparam [7:0] opc_cfg_b2      = 8'h02;
localparam [7:0] opc_load        = 8'h10;
localparam [7:0] opc_run_mac_acc = 8'h20;
localparam [7:0] opc_run_div_out = 8'h21;

localparam [5:0] st_idle               = 6'd0;
localparam [5:0] st_load_data          = 6'd1;
localparam [5:0] st_run_k_warmup       = 6'd2;
localparam [5:0] st_run_mac            = 6'd3;
localparam [5:0] st_run_mac_flush      = 6'd4;
localparam [5:0] st_run_ofifo_to_pmem  = 6'd5;
localparam [5:0] st_run_ofifo_to_pmem_wait = 6'd6;
localparam [5:0] st_run_sfp_acc        = 6'd7;
localparam [5:0] st_div_wait_empty     = 6'd8;
localparam [5:0] st_div_ext_wr         = 6'd9;
localparam [5:0] st_div_pass           = 6'd10;
localparam [5:0] st_out_req            = 6'd11;
localparam [5:0] st_out_wait           = 6'd12;
localparam [5:0] st_out_cap            = 6'd13;
localparam [5:0] st_out_send           = 6'd14;
localparam [5:0] st_resp               = 6'd15;
localparam [5:0] st_prog_b2           = 6'd16;

reg [5:0] state;

reg [num_cores-1:0] cfg_core_enable_mask;
reg [num_cores-1:0] cfg_multi_core_inst;
reg [num_cores-2:0] cfg_group_link;
reg [num_cores-1:0] cfg_sfp_acc_inst;
reg [num_cores-1:0] cfg_sfp_div_inst;
reg [num_cores-1:0] b2_prog_mask;
reg [sum_out_bw-1:0] b2_prog_threshold;

reg                  load_is_q;
reg [num_cores-1:0]  load_core_mask;
reg [7:0]            load_len;
reg [7:0]            load_idx;

reg [7:0]            run_q_len;
reg [7:0]            run_k_len;
reg [7:0]            run_rows;
reg [7:0]            run_idx;

reg [sum_out_bw-1:0] last_sum_value;
reg [255:0]          out_row_buf;
reg [1:0]            out_word_idx;
reg                  cmd_done_ok;
wire [31:0]          last_sum_32;
wire [sum_in_bw-1:0] last_sum_ext;

generate
if (sum_in_bw >= sum_out_bw) begin : gen_sum_ext_pad
    assign last_sum_ext = {{(sum_in_bw-sum_out_bw){1'b0}}, last_sum_value};
end else begin : gen_sum_ext_trunc
    assign last_sum_ext = last_sum_value[sum_in_bw-1:0];
end
endgenerate

wire [63:0] status_word = {
    8'hA0,
    cmd_done_ok,
    ext_sum_empty,
    2'b00,
    core_status[3:0],
    last_sum_32,
    16'd0
};

function [31:0] pack_sum32;
    input [sum_out_bw-1:0] v;
    integer j;
    begin
        pack_sum32 = 32'd0;
        for (j = 0; (j < 32) && (j < sum_out_bw); j = j + 1)
            pack_sum32[j] = v[j];
    end
endfunction

assign last_sum_32 = pack_sum32(last_sum_value);

always @(posedge clk) begin
    if (reset) begin
        state <= st_idle;

        rx_ready <= 1'b1;
        tx_valid <= 1'b0;
        tx_data <= 64'd0;
        tx_last <= 1'b0;

        mem_in <= 64'd0;
        mem_in_mask <= {num_cores{1'b1}};
        inst <= 17'd0;
        multi_core_inst <= {num_cores{1'b0}};
        core_enable_mask <= {num_cores{1'b0}};
        group_link <= {(num_cores-1){1'b0}};
        sfp_acc_inst <= {num_cores{1'b0}};
        sfp_div_inst <= {num_cores{1'b0}};
        ext_sum_wr <= 1'b0;
        sum_in <= {sum_in_bw{1'b0}};

        cfg_core_enable_mask <= {num_cores{1'b1}};
        cfg_multi_core_inst <= {num_cores{1'b0}};
        cfg_group_link <= {(num_cores-1){1'b0}};
        cfg_sfp_acc_inst <= {num_cores{1'b0}};
        cfg_sfp_div_inst <= {num_cores{1'b0}};
        b2_prog_mask <= {num_cores{1'b0}};
        b2_prog_threshold <= {sum_out_bw{1'b0}};

        load_is_q <= 1'b0;
        load_core_mask <= {num_cores{1'b0}};
        load_len <= 8'd0;
        load_idx <= 8'd0;

        run_q_len <= 8'd0;
        run_k_len <= 8'd0;
        run_rows <= 8'd0;
        run_idx <= 8'd0;

        last_sum_value <= {sum_out_bw{1'b0}};
        out_row_buf <= 256'd0;
        out_word_idx <= 2'd0;
        cmd_done_ok <= 1'b1;
    end else begin
        if (sum_valid)
            last_sum_value <= sum_out;

        // Default one-cycle controls.
        inst <= 17'd0;
        ext_sum_wr <= 1'b0;
        tx_last <= 1'b0;

        // Default configured masks.
        mem_in_mask <= {num_cores{1'b1}};
        multi_core_inst <= cfg_multi_core_inst;
        core_enable_mask <= cfg_core_enable_mask;
        group_link <= cfg_group_link;
        sfp_acc_inst <= cfg_sfp_acc_inst;
        sfp_div_inst <= cfg_sfp_div_inst;

        case (state)
            st_idle: begin
                rx_ready <= 1'b1;
                tx_valid <= 1'b0;

                if (rx_valid) begin
                    case (rx_data[63:56])
                        opc_cfg: begin
                            cfg_core_enable_mask <= rx_data[3:0];
                            cfg_multi_core_inst <= rx_data[7:4];
                            cfg_group_link <= rx_data[10:8];
                            cfg_sfp_acc_inst <= rx_data[14:11];
                            cfg_sfp_div_inst <= rx_data[18:15];
                            cmd_done_ok <= 1'b1;
                            state <= st_resp;
                        end

                        opc_cfg_b2: begin
                            b2_prog_threshold <= rx_data[sum_out_bw-1:0];
                            b2_prog_mask <= rx_data[sum_out_bw+num_cores-1:sum_out_bw];
                            cmd_done_ok <= |rx_data[sum_out_bw+num_cores-1:sum_out_bw];
                            if (|rx_data[sum_out_bw+num_cores-1:sum_out_bw])
                                state <= st_prog_b2;
                            else
                                state <= st_resp;
                        end

                        opc_load: begin
                            load_is_q <= rx_data[0];
                            load_core_mask <= rx_data[4:1];
                            load_len <= rx_data[12:5];
                            load_idx <= 8'd0;
                            cmd_done_ok <= (rx_data[12:5] != 8'd0);
                            rx_ready <= 1'b1;
                            if (rx_data[12:5] == 8'd0)
                                state <= st_resp;
                            else
                                state <= st_load_data;
                        end

                        opc_run_mac_acc: begin
                            run_q_len <= rx_data[7:0];
                            run_k_len <= rx_data[15:8];
                            run_idx <= 8'd0;
                            cmd_done_ok <= (rx_data[7:0] != 8'd0) && (rx_data[15:8] != 8'd0);
                            if ((rx_data[7:0] == 8'd0) || (rx_data[15:8] == 8'd0))
                                state <= st_resp;
                            else
                                state <= st_run_k_warmup;
                        end

                        opc_run_div_out: begin
                            run_rows <= rx_data[7:0];
                            run_idx <= 8'd0;
                            cmd_done_ok <= (rx_data[7:0] != 8'd0);
                            if (rx_data[7:0] == 8'd0)
                                state <= st_resp;
                            else
                                state <= st_div_wait_empty;
                        end

                        default: begin
                            cmd_done_ok <= 1'b0;
                            state <= st_resp;
                        end
                    endcase
                end
            end

            st_load_data: begin
                rx_ready <= 1'b1;
                tx_valid <= 1'b0;

                if (rx_valid) begin
                    mem_in <= rx_data;
                    mem_in_mask <= load_core_mask & cfg_core_enable_mask;
                    core_enable_mask <= load_core_mask & cfg_core_enable_mask;
                    inst[15:12] <= load_idx[3:0];
                    if (load_is_q)
                        inst[4] <= 1'b1; // qmem_wr
                    else
                        inst[2] <= 1'b1; // kmem_wr

                    if (load_idx + 1'b1 >= load_len)
                        state <= st_resp;

                    load_idx <= load_idx + 1'b1;
                end
            end

            st_prog_b2: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                mem_in <= {{(64-sum_out_bw){1'b0}}, b2_prog_threshold};
                core_enable_mask <= b2_prog_mask;
                inst[16] <= 1'b1; // b2_cfg_wr
                state <= st_resp;
            end

            st_run_k_warmup: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                core_enable_mask <= cfg_core_enable_mask;

                inst[6] <= 1'b1; // load
                if (run_idx != 0) begin
                    inst[3] <= 1'b1; // kmem_rd
                    inst[15:12] <= run_idx - 1'b1;
                end

                if (run_idx >= run_k_len) begin
                    run_idx <= 8'd0;
                    state <= st_run_mac;
                end else begin
                    run_idx <= run_idx + 1'b1;
                end
            end

            st_run_mac: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                core_enable_mask <= cfg_core_enable_mask;

                inst[7] <= 1'b1; // execute
                inst[5] <= 1'b1; // qmem_rd
                inst[15:12] <= run_idx[3:0];

                if (run_idx + 1'b1 >= run_q_len) begin
                    run_idx <= 8'd0;
                    state <= st_run_mac_flush;
                end else begin
                    run_idx <= run_idx + 1'b1;
                end
            end

            st_run_mac_flush: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                core_enable_mask <= cfg_core_enable_mask;

                inst[7] <= 1'b1; // execute
                inst[15:12] <= run_idx[3:0];

                if (run_idx + 1'b1 >= run_q_len) begin
                    run_idx <= 8'd0;
                    state <= st_run_ofifo_to_pmem;
                end else begin
                    run_idx <= run_idx + 1'b1;
                end
            end

            st_run_ofifo_to_pmem: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                core_enable_mask <= cfg_core_enable_mask;

                inst[0] <= 1'b1;  // pmem_wr
                inst[11:8] <= run_idx[3:0];

                state <= st_run_ofifo_to_pmem_wait;
            end

            st_run_ofifo_to_pmem_wait: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                core_enable_mask <= cfg_core_enable_mask;

                if (run_idx + 1'b1 >= run_q_len) begin
                    run_idx <= 8'd0;
                    state <= st_run_sfp_acc;
                end else begin
                    run_idx <= run_idx + 1'b1;
                    state <= st_run_ofifo_to_pmem;
                end
            end

            st_run_sfp_acc: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                core_enable_mask <= cfg_core_enable_mask;
                sfp_acc_inst <= cfg_sfp_acc_inst & cfg_core_enable_mask;

                inst[1] <= 1'b1; // pmem_rd
                inst[11:8] <= run_idx[3:0];

                if (run_idx + 1'b1 >= run_q_len) begin
                    state <= st_resp;
                end
                run_idx <= run_idx + 1'b1;
            end

            st_div_wait_empty: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                core_enable_mask <= cfg_core_enable_mask;

                // Wait until all selected cores can accept ext sum token.
                if (ext_sum_empty)
                    state <= st_div_ext_wr;
            end

            st_div_ext_wr: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                core_enable_mask <= cfg_core_enable_mask;

                ext_sum_wr <= 1'b1;
                if (last_sum_ext == {sum_in_bw{1'b0}})
                    sum_in <= {{(sum_in_bw-1){1'b0}}, 1'b1};
                else
                    sum_in <= last_sum_ext;

                run_idx <= 8'd0;
                state <= st_div_pass;
            end

            st_div_pass: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                core_enable_mask <= cfg_core_enable_mask;
                sfp_div_inst <= cfg_sfp_div_inst & cfg_core_enable_mask;

                inst[1] <= 1'b1;  // pmem_rd
                inst[0] <= 1'b1;  // pmem_wr
                inst[11:8] <= run_idx[3:0];

                if (run_idx + 1'b1 >= run_rows) begin
                    run_idx <= 8'd0;
                    state <= st_out_req;
                end else begin
                    run_idx <= run_idx + 1'b1;
                end
            end

            st_out_req: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                core_enable_mask <= cfg_core_enable_mask;

                inst[1] <= 1'b1; // pmem_rd
                inst[11:8] <= run_idx[3:0];
                state <= st_out_wait;
            end

            st_out_wait: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                state <= st_out_cap;
            end

            st_out_cap: begin
                rx_ready <= 1'b0;
                tx_valid <= 1'b0;
                out_row_buf <= {16'd0, out};
                out_word_idx <= 2'd0;
                state <= st_out_send;
            end

            st_out_send: begin
                rx_ready <= 1'b0;

                if (!tx_valid || (tx_valid && tx_ready)) begin
                    tx_valid <= 1'b1;
                    case (out_word_idx)
                        2'd0: tx_data <= out_row_buf[63:0];
                        2'd1: tx_data <= out_row_buf[127:64];
                        2'd2: tx_data <= out_row_buf[191:128];
                        default: tx_data <= out_row_buf[255:192];
                    endcase

                    if ((out_word_idx == 2'd3) && (run_idx + 1'b1 >= run_rows))
                        tx_last <= 1'b1;
                    else
                        tx_last <= 1'b0;

                    if (out_word_idx == 2'd3) begin
                        tx_valid <= 1'b1;
                        if (run_idx + 1'b1 >= run_rows) begin
                            state <= st_resp;
                        end else begin
                            run_idx <= run_idx + 1'b1;
                            state <= st_out_req;
                        end
                    end

                    out_word_idx <= out_word_idx + 1'b1;
                end
            end

            st_resp: begin
                rx_ready <= 1'b0;

                if (!tx_valid || (tx_valid && tx_ready)) begin
                    tx_valid <= 1'b1;
                    tx_data <= status_word;
                    tx_last <= 1'b1;
                    state <= st_idle;
                end
            end

            default: begin
                state <= st_idle;
            end
        endcase
    end
end

endmodule
