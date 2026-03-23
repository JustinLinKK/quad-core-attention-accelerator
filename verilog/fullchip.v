// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Modified by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
module fullchip (
    clk,
    adder_clk,
    spad_clk,
    core_clk,
    mem_in,
    mem_in_mask,
    core_inst,
    reset,
    half_precision,
    group_link,
    ext_sum_wr,
    sum_in,
    sum_out,
    sum_valid,
    ext_sum_empty,
    out,
    core_status,
    core_ctrl_status,
    group_sum_valid,
    group_sum_out,
    use_spad_ctrl,
    spad_wr_en,
    spad_wr_addr,
    spad_wr_data,
    ctrl_load_start,
    ctrl_load_is_q,
    ctrl_load_core_mask,
    ctrl_load_len,
    ctrl_load_base,
    ctrl_run_start,
    ctrl_run_q_len,
    ctrl_run_k_len,
    ctrl_b2_cfg_start,
    ctrl_b2_cfg_core_mask,
    ctrl_b2_cfg_addr,
    ctrl_core_enable_mask,
    ctrl_multi_core_inst,
    ctrl_group_link,
    ctrl_sfp_acc_inst,
    ctrl_sfp_div_inst,
    ctrl_busy,
    ctrl_done
  );

  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+6;
  parameter sum_out_bw = bw_psum + 4;
  parameter pr = 8;
  parameter num_cores = 4;
  parameter sum_in_bw = sum_out_bw + 2;
  localparam core_inst_w = 23;
  localparam spad_rows_max = 16;
  localparam agent_cmd_w = 2 + 1 + 8 + 8;

  input  clk;
  input  adder_clk;
  input  spad_clk;
  input  [num_cores-1:0] core_clk;
  input  [pr*bw-1:0] mem_in;
  input  [num_cores-1:0] mem_in_mask;
  input  [num_cores*core_inst_w-1:0] core_inst;
  input  reset;
  input  half_precision;
  input  [num_cores-2:0] group_link;
  input  ext_sum_wr;
  input  [sum_in_bw-1:0] sum_in;
  // Integrated scratchpad plan:
  // - external ingress stays 64-bit wide (one core row per write)
  // - internal storage uses shared 256-bit rows, one 64-bit slice per core
  // - one controller read returns the same logical row for all cores in parallel
  //
  // Per-core logical region layout:
  //   rows [0:7]   tile0 Q
  //   rows [8:15]  tile0 K
  //   rows [16:23] tile0 V
  //   rows [24:31] tile1 Q
  //   rows [32:39] tile1 K
  //   rows [40:47] tile1 V
  //   row  [48]    tile0 B2 threshold metadata
  //   row  [49]    tile1 B2 threshold metadata
  //   rows [50:63] reserved
  input  use_spad_ctrl;
  input  spad_wr_en;
  input  [7:0] spad_wr_addr;
  input  [pr*bw-1:0] spad_wr_data;
  input  ctrl_load_start;
  input  ctrl_load_is_q;
  input  [num_cores-1:0] ctrl_load_core_mask;
  input  [7:0] ctrl_load_len;
  input  [7:0] ctrl_load_base;
  input  ctrl_run_start;
  input  [7:0] ctrl_run_q_len;
  input  [7:0] ctrl_run_k_len;
  input  ctrl_b2_cfg_start;
  input  [num_cores-1:0] ctrl_b2_cfg_core_mask;
  input  [7:0] ctrl_b2_cfg_addr;
  input  [num_cores-1:0] ctrl_core_enable_mask;
  input  [num_cores-1:0] ctrl_multi_core_inst;
  input  [num_cores-2:0] ctrl_group_link;
  input  [num_cores-1:0] ctrl_sfp_acc_inst;
  input  [num_cores-1:0] ctrl_sfp_div_inst;

  output [sum_out_bw-1:0] sum_out;
  output sum_valid;
  output ext_sum_empty;
  output [num_cores*bw_psum*col-1:0] out;
  output [num_cores*12-1:0] core_status;
  output [num_cores*10-1:0] core_ctrl_status;
  output [num_cores-1:0] group_sum_valid;
  output [num_cores*sum_in_bw-1:0] group_sum_out;
  output ctrl_busy;
  output ctrl_done;

  wire [num_cores*sum_out_bw-1:0] core_sum_out_local;
  wire [num_cores-1:0] core_sum_valid_local;
  wire [num_cores-1:0] core_ext_sum_empty_local;
  wire [num_cores*sum_out_bw-1:0] core_sum_out_cc_adder;
  wire [num_cores-1:0] core_sum_valid_cc_adder;
  wire [num_cores-1:0] core_ext_sum_empty_cc_adder;
  wire [num_cores*bw_psum*col-1:0] core_out;
  wire [num_cores*sum_in_bw-1:0] combined_sum_out;
  wire [num_cores-1:0] combined_sum_valid;
  wire [num_cores-1:0] cc_ext_sum_wr_cc_adder;
  wire [num_cores*sum_in_bw-1:0] cc_sum_in_cc_adder;
  wire [num_cores-1:0] cc_ext_sum_wr_core;
  wire [num_cores*sum_in_bw-1:0] cc_sum_in_core;
  wire [num_cores-1:0] sum_cdc_src_ready;
  wire [num_cores-1:0] cmd_cdc_src_ready;
  wire [num_cores-1:0] core_sum_pop_ready;
  wire [num_cores-1:0] core_enable_mask;
  wire [num_cores-1:0] multi_core_inst;
  wire [num_cores-2:0] fullchip_group_link;
  wire fullchip_ext_sum_wr;
  wire [sum_in_bw-1:0] fullchip_sum_in;
  wire [num_cores-1:0] ctrl_multi_core_inst_w;
  wire [num_cores-1:0] ctrl_core_enable_mask_w;
  wire [num_cores-2:0] ctrl_group_link_w;
  wire [num_cores-1:0] ctrl_sfp_acc_inst_w;
  wire [num_cores-1:0] ctrl_sfp_div_inst_w;
  wire ctrl_spad_rd_req_valid;
  wire ctrl_spad_rd_req_ready;
  wire [7:0] ctrl_spad_rd_addr;
  wire ctrl_spad_rd_rsp_valid;
  wire ctrl_spad_rd_rsp_ready_w;
  wire [num_cores*pr*bw-1:0] ctrl_spad_rd_rsp_data;
  wire ctrl_load_row_valid_w;
  wire ctrl_load_row_ready_w;
  wire [num_cores-1:0] ctrl_load_row_core_mask_w;
  wire [num_cores*pr*bw-1:0] ctrl_load_row_data_bus_w;
  wire [5:0] spad_rd_addr_spad;
  wire spad_rd_req_valid_spad;
  wire spad_rd_req_ready_spad;
  wire spad_rd_rsp_src_ready;
  wire [num_cores*pr*bw-1:0] scratchpad_rdata_spad;
  wire [5:0] scratchpad_addr_local;
  wire scratchpad_rd_issue_spad;
  wire [1:0] scratchpad_wr_core_sel;
  wire [num_cores*4-1:0] core_phase_local;
  wire [num_cores-1:0] core_busy_local;
  wire [num_cores-1:0] core_mac_done_local;
  wire [num_cores-1:0] core_acc_done_local;
  wire [num_cores-1:0] core_div_done_local;
  wire [num_cores-1:0] core_tile_ready_valid_local;
  wire [num_cores-1:0] core_tile_ready_bank_local;
  wire [num_cores-1:0] core_ofifo_valid_local;
  wire [num_cores-1:0] core_ofifo_valid_sync;
  wire [num_cores-1:0] core_agent_busy_local;
  wire [num_cores-1:0] core_agent_busy_sync;
  wire [num_cores*4-1:0] core_phase_sync;
  wire [num_cores-1:0] core_busy_sync;
  wire [num_cores-1:0] core_mac_done_sync;
  wire [num_cores-1:0] core_acc_done_sync;
  wire [num_cores-1:0] core_div_done_sync;
  wire [num_cores-1:0] core_tile_ready_valid_sync;
  wire [num_cores-1:0] core_tile_ready_bank_sync;
  wire ctrl_cmd_valid_w;
  wire ctrl_cmd_ready_w;
  wire [num_cores-1:0] ctrl_cmd_core_mask_w;
  wire [num_cores*agent_cmd_w-1:0] ctrl_cmd_payload_bus_w;
  wire [num_cores-1:0] agent_cmd_src_ready;
  wire [num_cores-1:0] agent_cmd_dst_valid;
  wire [num_cores*agent_cmd_w-1:0] agent_cmd_dst_data;
  wire [num_cores-1:0] agent_load_row_src_ready;
  wire [num_cores-1:0] agent_load_row_dst_valid;
  wire [num_cores*pr*bw-1:0] agent_load_row_dst_data;
  wire [num_cores-1:0] core_enable_mask_adder;
  wire [num_cores-1:0] multi_core_inst_adder;
  wire [num_cores-2:0] group_link_adder;
  wire [0:0] ext_sum_wr_adder_data_unused;
  wire ext_sum_wr_adder;
  wire ext_sum_wr_adder_src_ready;
  wire [sum_out_bw-1:0] sum_out_clk;
  wire sum_valid_clk;
  reg ext_sum_wr_pending_q;
  reg scratchpad_rd_capture_q;
  reg scratchpad_rsp_pending_q;
  reg [num_cores*pr*bw-1:0] scratchpad_rsp_data_q;

  assign ctrl_cmd_ready_w = (!ctrl_cmd_valid_w) ||
                            &((~ctrl_cmd_core_mask_w) | agent_cmd_src_ready);

  assign scratchpad_rd_issue_spad = spad_rd_req_valid_spad &&
                                    spad_rd_req_ready_spad &&
                                    !spad_wr_en;
  assign spad_rd_req_ready_spad = !spad_wr_en &&
                                  !scratchpad_rd_capture_q &&
                                  !scratchpad_rsp_pending_q &&
                                  spad_rd_rsp_src_ready;
  assign scratchpad_wr_core_sel = spad_wr_addr[7:6];
  assign scratchpad_addr_local = spad_wr_en ? spad_wr_addr[5:0] : spad_rd_addr_spad;

  assign ctrl_multi_core_inst_w = ctrl_multi_core_inst;
  assign ctrl_core_enable_mask_w = ctrl_core_enable_mask;
  assign ctrl_group_link_w = ctrl_group_link;
  assign ctrl_sfp_acc_inst_w = ctrl_sfp_acc_inst;
  assign ctrl_sfp_div_inst_w = ctrl_sfp_div_inst;
  assign fullchip_group_link = use_spad_ctrl ? ctrl_group_link_w : group_link;
  assign fullchip_ext_sum_wr = use_spad_ctrl ? 1'b0 : ext_sum_wr;
  assign fullchip_sum_in = use_spad_ctrl ? {sum_in_bw{1'b0}} : sum_in;
  assign ctrl_load_row_data_bus_w = ctrl_spad_rd_rsp_data;
  assign ctrl_load_row_ready_w = &((~ctrl_load_row_core_mask_w) | agent_load_row_src_ready);

  fullchip_spad_controller #(
      .num_cores(num_cores),
      .bw(bw),
      .pr(pr)
  ) fullchip_spad_ctrl (
      .clk(clk),
      .reset(reset),
      .cfg_core_enable_mask(ctrl_core_enable_mask),
      .load_start(ctrl_load_start),
      .load_is_q(ctrl_load_is_q),
      .load_core_mask(ctrl_load_core_mask),
      .load_len(ctrl_load_len),
      .load_base(ctrl_load_base),
      .run_start(ctrl_run_start),
      .run_q_len(ctrl_run_q_len),
      .run_k_len(ctrl_run_k_len),
      .b2_cfg_start(ctrl_b2_cfg_start),
      .b2_cfg_core_mask(ctrl_b2_cfg_core_mask),
      .b2_cfg_addr(ctrl_b2_cfg_addr),
      .core_agent_busy(core_agent_busy_sync),
      .cmd_valid(ctrl_cmd_valid_w),
      .cmd_ready(ctrl_cmd_ready_w),
      .cmd_core_mask(ctrl_cmd_core_mask_w),
      .cmd_payload_bus(ctrl_cmd_payload_bus_w),
      .load_row_valid(ctrl_load_row_valid_w),
      .load_row_ready(ctrl_load_row_ready_w),
      .load_row_core_mask(ctrl_load_row_core_mask_w),
      .busy(ctrl_busy),
      .done(ctrl_done),
      .spad_rd_req_valid(ctrl_spad_rd_req_valid),
      .spad_rd_req_ready(ctrl_spad_rd_req_ready),
      .spad_rd_addr(ctrl_spad_rd_addr),
      .spad_rd_rsp_valid(ctrl_spad_rd_rsp_valid),
      .spad_rd_rsp_ready(ctrl_spad_rd_rsp_ready_w)
  );

  cdc_bus_1deep #(.message_w(6)) ctrl_spad_req_cdc (
      .src_clk(clk),
      .dst_clk(spad_clk),
      .reset(reset),
      .src_data(ctrl_spad_rd_addr[5:0]),
      .src_valid(ctrl_spad_rd_req_valid),
      .src_ready(ctrl_spad_rd_req_ready),
      .dst_data(spad_rd_addr_spad),
      .dst_valid(spad_rd_req_valid_spad),
      .dst_ready(spad_rd_req_ready_spad)
  );

  cdc_bus_1deep #(.message_w(num_cores*pr*bw)) ctrl_spad_rsp_cdc (
      .src_clk(spad_clk),
      .dst_clk(clk),
      .reset(reset),
      .src_data(scratchpad_rsp_data_q),
      .src_valid(scratchpad_rsp_pending_q),
      .src_ready(spad_rd_rsp_src_ready),
      .dst_data(ctrl_spad_rd_rsp_data),
      .dst_valid(ctrl_spad_rd_rsp_valid),
      .dst_ready(ctrl_spad_rd_rsp_ready_w)
  );

  sram_256b_w64 scratchpad_instance (
      .CLK(spad_clk),
      .D(spad_wr_data),
      .Q(scratchpad_rdata_spad),
      .CEN(!(spad_wr_en || scratchpad_rd_issue_spad)),
      .WEN(!spad_wr_en),
      .A(scratchpad_addr_local),
      .SEL(scratchpad_wr_core_sel)
  );

  always @(posedge spad_clk) begin
    if (reset) begin
      scratchpad_rd_capture_q <= 1'b0;
      scratchpad_rsp_pending_q <= 1'b0;
      scratchpad_rsp_data_q <= {num_cores*pr*bw{1'b0}};
    end else begin
      scratchpad_rd_capture_q <= scratchpad_rd_issue_spad;

      if (scratchpad_rd_capture_q) begin
        scratchpad_rsp_data_q <= scratchpad_rdata_spad;
        scratchpad_rsp_pending_q <= 1'b1;
      end else if (scratchpad_rsp_pending_q && spad_rd_rsp_src_ready) begin
        scratchpad_rsp_pending_q <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      ext_sum_wr_pending_q <= 1'b0;
    end else begin
      if (ext_sum_wr_pending_q)
        ext_sum_wr_pending_q <= !ext_sum_wr_adder_src_ready;
      if (fullchip_ext_sum_wr)
        ext_sum_wr_pending_q <= 1'b1;
    end
  end

  genvar gi;
  generate
    for (gi = 0; gi < num_cores; gi = gi + 1)
    begin : core_cluster
      wire [22:0] core_inst_word;
      wire [22:0] agent_inst_word;
      wire [22:0] active_core_inst_word;
      wire direct_mem_write_enable;
      wire direct_core_clk_req;
      wire core_clk_req;
      wire core_inst_enable;
      wire core_clk_g;
      wire [pr*bw-1:0] core_mem_in;
      wire [pr*bw-1:0] agent_mem_in;
      wire agent_cmd_ready_local;
      wire agent_load_row_ready_local;
      wire agent_q_load_done;
      wire agent_k_load_done;
      reg  sum_cdc_hold_valid_q;
      reg  [sum_out_bw-1:0] sum_cdc_hold_data_q;
      reg  cmd_cdc_hold_valid_q;
      reg  [sum_in_bw-1:0] cmd_cdc_hold_data_q;
      reg  core_clk_en_latch;
      assign core_inst_word = core_inst[(core_inst_w*(gi+1))-1 : (core_inst_w*gi)];
      assign direct_mem_write_enable = core_inst_word[4] | core_inst_word[2];
      assign direct_core_clk_req = core_inst_word[20] & (~direct_mem_write_enable | mem_in_mask[gi]);
      assign active_core_inst_word = use_spad_ctrl ? agent_inst_word : core_inst_word;
      assign core_clk_req = use_spad_ctrl ?
                            (ctrl_core_enable_mask_w[gi] | core_agent_busy_local[gi]) :
                            (direct_core_clk_req | sum_cdc_hold_valid_q);
      assign core_inst_enable = use_spad_ctrl ?
                                ctrl_core_enable_mask_w[gi] :
                                (active_core_inst_word[20] &
                                 (~direct_mem_write_enable | mem_in_mask[gi]));
      assign core_enable_mask[gi] = use_spad_ctrl ? ctrl_core_enable_mask_w[gi] : core_inst_word[20];
      assign multi_core_inst[gi] = use_spad_ctrl ? ctrl_multi_core_inst_w[gi] : core_inst_word[19];
      assign core_mem_in = use_spad_ctrl ? agent_mem_in :
                           (mem_in_mask[gi] ? mem_in : {pr*bw{1'b0}});
      assign core_clk_g = core_clk[gi] & (core_clk_en_latch || reset);

      always @ (core_clk[gi] or core_clk_req or reset)
      begin
        if (reset)
          core_clk_en_latch <= 1'b0;
        else if (!core_clk[gi])
          core_clk_en_latch <= core_clk_req;
      end

      always @(posedge core_clk_g) begin
        if (reset) begin
          sum_cdc_hold_valid_q <= 1'b0;
          sum_cdc_hold_data_q <= {sum_out_bw{1'b0}};
        end else begin
          if (sum_cdc_hold_valid_q && sum_cdc_src_ready[gi])
            sum_cdc_hold_valid_q <= 1'b0;
          if (core_sum_valid_local[gi] && !sum_cdc_hold_valid_q) begin
            sum_cdc_hold_valid_q <= 1'b1;
            sum_cdc_hold_data_q <= core_sum_out_local[(sum_out_bw*(gi+1))-1 : (sum_out_bw*gi)];
          end
        end
      end

      always @(posedge adder_clk) begin
        if (reset) begin
          cmd_cdc_hold_valid_q <= 1'b0;
          cmd_cdc_hold_data_q <= {sum_in_bw{1'b0}};
        end else begin
          if (cmd_cdc_hold_valid_q && cmd_cdc_src_ready[gi])
            cmd_cdc_hold_valid_q <= 1'b0;
          if (cc_ext_sum_wr_cc_adder[gi] && !cmd_cdc_hold_valid_q) begin
            cmd_cdc_hold_valid_q <= 1'b1;
            cmd_cdc_hold_data_q <= cc_sum_in_cc_adder[(sum_in_bw*(gi+1))-1 : (sum_in_bw*gi)];
          end
        end
      end

      cdc_bus_1deep #(.message_w(agent_cmd_w)) ctrl_cmd_cdc (
                 .src_clk(clk),
                 .dst_clk(core_clk[gi]),
                 .reset(reset),
                 .src_data(ctrl_cmd_payload_bus_w[(gi*agent_cmd_w) +: agent_cmd_w]),
                 .src_valid(use_spad_ctrl && ctrl_cmd_valid_w && ctrl_cmd_ready_w && ctrl_cmd_core_mask_w[gi]),
                 .src_ready(agent_cmd_src_ready[gi]),
                 .dst_data(agent_cmd_dst_data[(agent_cmd_w*(gi+1))-1 : (agent_cmd_w*gi)]),
                 .dst_valid(agent_cmd_dst_valid[gi]),
                 .dst_ready(agent_cmd_ready_local)
               );

      cdc_bus_1deep #(.message_w(pr*bw)) ctrl_load_row_cdc (
                 .src_clk(clk),
                 .dst_clk(core_clk[gi]),
                 .reset(reset),
                 .src_data(ctrl_load_row_data_bus_w[(gi*pr*bw) +: (pr*bw)]),
                 .src_valid(use_spad_ctrl && ctrl_load_row_valid_w && ctrl_load_row_core_mask_w[gi]),
                 .src_ready(agent_load_row_src_ready[gi]),
                 .dst_data(agent_load_row_dst_data[(pr*bw*(gi+1))-1 : (pr*bw*gi)]),
                 .dst_valid(agent_load_row_dst_valid[gi]),
                 .dst_ready(agent_load_row_ready_local)
               );

      fullchip_core_agent #(
             .bw(bw),
             .pr(pr),
             .spad_rows_max(spad_rows_max)
           ) core_agent (
             .core_clk(core_clk[gi]),
             .reset(reset),
             .cfg_core_enable(ctrl_core_enable_mask_w[gi]),
             .cfg_multi_core_inst(ctrl_multi_core_inst_w[gi]),
             .cfg_sfp_acc_inst(ctrl_sfp_acc_inst_w[gi]),
             .cfg_sfp_div_inst(ctrl_sfp_div_inst_w[gi]),
             .cmd_valid(agent_cmd_dst_valid[gi]),
             .cmd_ready(agent_cmd_ready_local),
             .cmd_payload(agent_cmd_dst_data[(agent_cmd_w*(gi+1))-1 : (agent_cmd_w*gi)]),
             .load_row_valid(agent_load_row_dst_valid[gi]),
             .load_row_ready(agent_load_row_ready_local),
             .load_row_data(agent_load_row_dst_data[(pr*bw*(gi+1))-1 : (pr*bw*gi)]),
             .core_ofifo_valid(core_ofifo_valid_local[gi]),
             .busy(core_agent_busy_local[gi]),
             .q_load_done(agent_q_load_done),
             .k_load_done(agent_k_load_done),
             .mem_in(agent_mem_in),
             .inst_word(agent_inst_word)
           );

      core #(
             .bw(bw),
             .bw_psum(bw_psum),
             .sum_out_bw(sum_out_bw),
             .col(col),
             .pr(pr),
             .sum_in_bw(sum_in_bw)
           ) core_instance (
             .reset(reset),
             .clk(core_clk_g),
             .ext_sum_wr(cc_ext_sum_wr_core[gi]),
             .managed_load_mode(use_spad_ctrl),
             .q_load_done(agent_q_load_done),
             .k_load_done(agent_k_load_done),
             .mem_in(core_mem_in),
             .inst({active_core_inst_word[22:21], core_inst_enable, active_core_inst_word[19:0]}),
             .sum_in(cc_sum_in_core[(sum_in_bw*(gi+1))-1 : (sum_in_bw*gi)]),
             .sum_out(core_sum_out_local[(sum_out_bw*(gi+1))-1 : (sum_out_bw*gi)]),
             .core_status(core_status[(12*(gi+1))-1 : (12*gi)]),
             .core_phase(core_phase_local[(4*(gi+1))-1 : (4*gi)]),
             .core_busy(core_busy_local[gi]),
             .mac_done(core_mac_done_local[gi]),
             .acc_done(core_acc_done_local[gi]),
             .div_done(core_div_done_local[gi]),
             .tile_ready_valid(core_tile_ready_valid_local[gi]),
             .tile_ready_bank(core_tile_ready_bank_local[gi]),
             .ofifo_valid(core_ofifo_valid_local[gi]),
             .out(core_out[(bw_psum*col*(gi+1))-1 : (bw_psum*col*gi)])
           );

      assign core_ctrl_status[(10*(gi+1))-1 : (10*gi)] = {
        core_tile_ready_bank_sync[gi],
        core_tile_ready_valid_sync[gi],
        core_div_done_sync[gi],
        core_acc_done_sync[gi],
        core_mac_done_sync[gi],
        core_busy_sync[gi],
        core_phase_sync[(4*(gi+1))-1 : (4*gi)]
      };

      assign core_sum_valid_local[gi] = core_status[(12*gi)+8];
      assign core_ext_sum_empty_local[gi] = core_status[(12*gi)+9];

      cdc_fifo #(.message_w(sum_out_bw), .depth(16), .addr_w(4)) sum_cdc (
                 .src_clk(core_clk_g),
                 .dst_clk(adder_clk),
                 .reset(reset),
                 .src_data(sum_cdc_hold_data_q),
                 .src_valid(sum_cdc_hold_valid_q),
                 .src_ready(sum_cdc_src_ready[gi]),
                 .dst_data(core_sum_out_cc_adder[(sum_out_bw*(gi+1))-1 : (sum_out_bw*gi)]),
                 .dst_valid(core_sum_valid_cc_adder[gi]),
                 .dst_ready(core_sum_pop_ready[gi])
               );

      cdc_fifo #(.message_w(sum_in_bw), .depth(16), .addr_w(4)) cmd_cdc (
                 .src_clk(adder_clk),
                 .dst_clk(core_clk_g),
                 .reset(reset),
                 .src_data(cmd_cdc_hold_data_q),
                 .src_valid(cmd_cdc_hold_valid_q),
                 .src_ready(cmd_cdc_src_ready[gi]),
                 .dst_data(cc_sum_in_core[(sum_in_bw*(gi+1))-1 : (sum_in_bw*gi)]),
                 .dst_valid(cc_ext_sum_wr_core[gi]),
                 .dst_ready(core_ext_sum_empty_local[gi])
               );

      sync ext_empty_sync (
             .clk(clk),
             .in(core_ext_sum_empty_local[gi]),
             .out(core_ext_sum_empty_cc_adder[gi])
           );

      sync ofifo_valid_sync (
             .clk(clk),
             .in(core_ofifo_valid_local[gi]),
             .out(core_ofifo_valid_sync[gi])
           );

      sync agent_busy_sync (
             .clk(clk),
             .in(core_agent_busy_local[gi]),
             .out(core_agent_busy_sync[gi])
           );

      sync core_busy_status_sync (
             .clk(clk),
             .in(core_busy_local[gi]),
             .out(core_busy_sync[gi])
           );

      sync mac_done_status_sync (
             .clk(clk),
             .in(core_mac_done_local[gi]),
             .out(core_mac_done_sync[gi])
           );

      sync acc_done_status_sync (
             .clk(clk),
             .in(core_acc_done_local[gi]),
             .out(core_acc_done_sync[gi])
           );

      sync div_done_status_sync (
             .clk(clk),
             .in(core_div_done_local[gi]),
             .out(core_div_done_sync[gi])
           );

      sync tile_ready_valid_status_sync (
             .clk(clk),
             .in(core_tile_ready_valid_local[gi]),
             .out(core_tile_ready_valid_sync[gi])
           );

      sync tile_ready_bank_status_sync (
             .clk(clk),
             .in(core_tile_ready_bank_local[gi]),
             .out(core_tile_ready_bank_sync[gi])
           );

      sync core_phase_bit0_sync (
             .clk(clk),
             .in(core_phase_local[(4*gi)+0]),
             .out(core_phase_sync[(4*gi)+0])
           );

      sync core_phase_bit1_sync (
             .clk(clk),
             .in(core_phase_local[(4*gi)+1]),
             .out(core_phase_sync[(4*gi)+1])
           );

      sync core_phase_bit2_sync (
             .clk(clk),
             .in(core_phase_local[(4*gi)+2]),
             .out(core_phase_sync[(4*gi)+2])
           );

      sync core_phase_bit3_sync (
             .clk(clk),
             .in(core_phase_local[(4*gi)+3]),
             .out(core_phase_sync[(4*gi)+3])
           );
    end
  endgenerate

  genvar aci;
  generate
    for (aci = 0; aci < num_cores; aci = aci + 1)
    begin : adder_cfg_sync
      sync core_enable_sync_to_adder (
             .clk(adder_clk),
             .in(core_enable_mask[aci]),
             .out(core_enable_mask_adder[aci])
           );

      sync multi_core_sync_to_adder (
             .clk(adder_clk),
             .in(multi_core_inst[aci]),
             .out(multi_core_inst_adder[aci])
           );
    end
  endgenerate

  genvar agi;
  generate
    for (agi = 0; agi < num_cores-1; agi = agi + 1)
    begin : adder_group_sync
      sync group_link_sync_to_adder (
             .clk(adder_clk),
             .in(fullchip_group_link[agi]),
             .out(group_link_adder[agi])
           );
    end
  endgenerate

  cdc_bus_1deep #(.message_w(1)) ext_sum_wr_cdc (
      .src_clk(clk),
      .dst_clk(adder_clk),
      .reset(reset),
      .src_data(1'b1),
      .src_valid(ext_sum_wr_pending_q),
      .src_ready(ext_sum_wr_adder_src_ready),
      .dst_data(ext_sum_wr_adder_data_unused),
      .dst_valid(ext_sum_wr_adder),
      .dst_ready(1'b1)
  );

  cdc_bus_1deep #(.message_w(sum_out_bw)) sum_out_cdc (
      .src_clk(adder_clk),
      .dst_clk(clk),
      .reset(reset),
      .src_data(combined_sum_out[sum_out_bw-1:0]),
      .src_valid(combined_sum_valid[0]),
      .src_ready(),
      .dst_data(sum_out_clk),
      .dst_valid(sum_valid_clk),
      .dst_ready(1'b1)
  );

  cross_core_adder #(
                     .bw_psum(bw_psum),
                     .sum_out_bw(sum_out_bw),
                     .num_cores(num_cores),
                     .sum_in_bw(sum_in_bw)
                   ) cross_core_adder_instance (
                     .clk(adder_clk),
                     .reset(reset),
                     .multi_core_inst(multi_core_inst_adder),
                     .core_enable_mask(core_enable_mask_adder),
                     .group_link(group_link_adder),
                     .ext_sum_wr_cmd(ext_sum_wr_adder),
                     .core_sum_in(core_sum_out_cc_adder),
                     .sum_valid_in(core_sum_valid_cc_adder),
                     .core_sum_pop_ready(core_sum_pop_ready),
                     .core_sum_to_cores(cc_sum_in_cc_adder),
                     .core_ext_sum_wr(cc_ext_sum_wr_cc_adder),
                     .sum_out(combined_sum_out),
                     .sum_valid_out(combined_sum_valid)
                   );

  assign sum_out = sum_out_clk;
  assign sum_valid = sum_valid_clk;
  assign ext_sum_empty = &(core_ext_sum_empty_cc_adder | ~core_enable_mask);
  assign group_sum_valid = combined_sum_valid;
  assign group_sum_out = combined_sum_out;
  assign out = core_out;

endmodule
