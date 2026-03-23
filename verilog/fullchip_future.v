// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Modified by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
module fullchip_future (
    clk,
    adder_clk,
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
    use_io_ctrl,
    rx_valid,
    rx_data,
    rx_ready,
    tx_valid,
    tx_data,
    tx_last,
    tx_ready
  );

  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+6;
  parameter sum_out_bw = bw_psum + 4;
  parameter pr = 8;
  parameter num_cores = 4;
  parameter sum_in_bw = sum_out_bw + 2;

  input  clk;
  input  adder_clk;
  input  [num_cores-1:0] core_clk;
  input  [pr*bw-1:0] mem_in;
  input  [num_cores-1:0] mem_in_mask;
  input  [num_cores*23-1:0] core_inst;
  input  reset;
  // half_precision mode is disabled in current Step5 datapath.
  // Keep pin for interface compatibility, but ignore it internally.
  input  half_precision;
  // Encoded topology mode:
  // 3'b000 -> [0][1][2][3]
  // 3'b010 -> [0,1][2][3]
  // 3'b101 -> [0,1][2,3]
  // 3'b111 -> [0,1,2,3]
  input  [num_cores-2:0] group_link;
  input  ext_sum_wr;
  input  [sum_in_bw-1:0] sum_in;
  output [sum_out_bw-1:0] sum_out;
  output sum_valid;
  output ext_sum_empty;
  output [num_cores*bw_psum*col-1:0] out;
  output [num_cores*12-1:0] core_status;

  input  use_io_ctrl;
  input  rx_valid;
  input  [63:0] rx_data;
  output rx_ready;
  output tx_valid;
  output [63:0] tx_data;
  output tx_last;
  input  tx_ready;

  wire [63:0] io_mem_in;
  wire [16:0] io_inst;
  wire [num_cores-1:0] io_multi_core_inst;
  wire [num_cores-1:0] io_mem_in_mask;
  wire [num_cores-1:0] io_core_enable_mask;
  wire [num_cores-2:0] io_group_link;
  wire [num_cores-1:0] io_sfp_acc_inst;
  wire [num_cores-1:0] io_sfp_div_inst;
  wire io_ext_sum_wr;
  wire [sum_in_bw-1:0] io_sum_in;
  wire io_rx_ready;
  wire io_tx_valid;
  wire [63:0] io_tx_data;
  wire io_tx_last;

  wire [pr*bw-1:0] active_mem_in = use_io_ctrl ? io_mem_in[pr*bw-1:0] : mem_in;
  wire [num_cores-1:0] active_mem_in_mask = use_io_ctrl ? io_mem_in_mask : mem_in_mask;
  wire [num_cores*23-1:0] active_core_inst;
  wire [num_cores-1:0] active_multi_core_inst;
  wire [num_cores-1:0] active_core_enable_mask;
  wire [num_cores-2:0] active_group_link = use_io_ctrl ? io_group_link : group_link;
  wire active_ext_sum_wr = use_io_ctrl ? io_ext_sum_wr : ext_sum_wr;
  wire [sum_in_bw-1:0] active_sum_in = use_io_ctrl ? io_sum_in : sum_in;

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
  wire [num_cores-1:0] active_core_enable_mask_adder;
  wire [num_cores-1:0] active_multi_core_inst_adder;
  wire [num_cores-2:0] active_group_link_adder;
  wire [0:0] active_ext_sum_wr_adder_data_unused;
  wire active_ext_sum_wr_adder;
  wire [sum_out_bw-1:0] sum_out_clk;
  wire sum_valid_clk;

  genvar cfgi;
  generate
    for (cfgi = 0; cfgi < num_cores; cfgi = cfgi + 1)
    begin : active_inst_pack
      assign active_core_inst[(23*(cfgi+1))-1 : (23*cfgi)] = use_io_ctrl ? {
        2'b00,
        io_core_enable_mask[cfgi],
        io_multi_core_inst[cfgi],
        io_sfp_acc_inst[cfgi],
        io_sfp_div_inst[cfgi],
        io_inst
      } : core_inst[(23*(cfgi+1))-1 : (23*cfgi)];
      assign active_core_enable_mask[cfgi] = active_core_inst[(23*cfgi)+20];
      assign active_multi_core_inst[cfgi] = active_core_inst[(23*cfgi)+19];
    end
  endgenerate

  workproc_controller #(
                        .num_cores(num_cores),
                        .col(col),
                        .bw(bw),
                        .bw_psum(bw_psum),
                        .sum_out_bw(sum_out_bw),
                        .sum_in_bw(sum_in_bw)
                      ) fullchip_workproc_controller (
                        .clk(clk),
                        .reset(reset),
                        .rx_valid(rx_valid),
                        .rx_data(rx_data),
                        .rx_ready(io_rx_ready),
                        .tx_valid(io_tx_valid),
                        .tx_data(io_tx_data),
                        .tx_last(io_tx_last),
                        .tx_ready(tx_ready),
                        .mem_in(io_mem_in),
                        .inst(io_inst),
                        .mem_in_mask(io_mem_in_mask),
                        .multi_core_inst(io_multi_core_inst),
                        .core_enable_mask(io_core_enable_mask),
                        .group_link(io_group_link),
                        .sfp_acc_inst(io_sfp_acc_inst),
                        .sfp_div_inst(io_sfp_div_inst),
                        .ext_sum_wr(io_ext_sum_wr),
                        .sum_in(io_sum_in),
                        .sum_out(sum_out),
                        .sum_valid(sum_valid),
                        .ext_sum_empty(ext_sum_empty),
                        .out(core_out[bw_psum*col-1:0]),
                        .core_status(core_status)
                      );

  assign rx_ready = use_io_ctrl ? io_rx_ready : 1'b0;
  assign tx_valid = use_io_ctrl ? io_tx_valid : 1'b0;
  assign tx_data  = use_io_ctrl ? io_tx_data  : 64'd0;
  assign tx_last  = use_io_ctrl ? io_tx_last  : 1'b0;

  genvar gi;
  generate
    for (gi = 0; gi < num_cores; gi = gi + 1)
    begin : core_cluster
      wire [22:0] core_inst_word;
      wire core_mem_write_enable;
      wire core_inst_enable;
      wire core_clk_g;
      wire [pr*bw-1:0] core_mem_in;
      reg  core_clk_en_latch;
      assign core_inst_word = active_core_inst[(23*(gi+1))-1 : (23*gi)];
      assign core_mem_write_enable = core_inst_word[4] | core_inst_word[2];
      assign core_inst_enable = core_inst_word[20] & (~core_mem_write_enable | active_mem_in_mask[gi]);
      assign core_mem_in = active_mem_in_mask[gi] ? active_mem_in : {pr*bw{1'b0}};
      assign core_clk_g = core_clk[gi] & (core_clk_en_latch || reset);

      // Latch-based per-core clock gating from decoded core enable.
      always @ (core_clk[gi] or core_inst_enable or reset)
      begin
        if (reset)
          core_clk_en_latch <= 1'b0;
        else if (!core_clk[gi])
          core_clk_en_latch <= core_inst_enable;
      end

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
             .managed_load_mode(1'b0),
             .q_load_done(1'b0),
             .k_load_done(1'b0),
             .mem_in(core_mem_in),
             .inst({core_inst_word[22:21], core_inst_enable, core_inst_word[19:0]}),
             .sum_in(cc_sum_in_core[(sum_in_bw*(gi+1))-1 : (sum_in_bw*gi)]),
             .sum_out(core_sum_out_local[(sum_out_bw*(gi+1))-1 : (sum_out_bw*gi)]),
             .core_status(core_status[(12*(gi+1))-1 : (12*gi)]),
             .out(core_out[(bw_psum*col*(gi+1))-1 : (bw_psum*col*gi)])
           );

      assign core_sum_valid_local[gi] = core_status[(12*gi)+8];
      assign core_ext_sum_empty_local[gi] = core_status[(12*gi)+9];

      cdc_fifo #(.message_w(sum_out_bw), .depth(16), .addr_w(4)) sum_cdc (
                 .src_clk(core_clk_g),
                 .dst_clk(adder_clk),
                 .reset(reset),
                 .src_data(core_sum_out_local[(sum_out_bw*(gi+1))-1 : (sum_out_bw*gi)]),
                 .src_valid(core_sum_valid_local[gi]),
                 .src_ready(sum_cdc_src_ready[gi]),
                 .dst_data(core_sum_out_cc_adder[(sum_out_bw*(gi+1))-1 : (sum_out_bw*gi)]),
                 .dst_valid(core_sum_valid_cc_adder[gi]),
                 .dst_ready(core_sum_pop_ready[gi])
               );

      cdc_fifo #(.message_w(sum_in_bw), .depth(16), .addr_w(4)) cmd_cdc (
                 .src_clk(adder_clk),
                 .dst_clk(core_clk_g),
                 .reset(reset),
                 .src_data(cc_sum_in_cc_adder[(sum_in_bw*(gi+1))-1 : (sum_in_bw*gi)]),
                 .src_valid(cc_ext_sum_wr_cc_adder[gi]),
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
    end
  endgenerate

  genvar aci;
  generate
    for (aci = 0; aci < num_cores; aci = aci + 1)
    begin : adder_cfg_sync
      sync core_enable_sync_to_adder (
             .clk(adder_clk),
             .in(active_core_enable_mask[aci]),
             .out(active_core_enable_mask_adder[aci])
           );

      sync multi_core_sync_to_adder (
             .clk(adder_clk),
             .in(active_multi_core_inst[aci]),
             .out(active_multi_core_inst_adder[aci])
           );
    end
  endgenerate

  genvar agi;
  generate
    for (agi = 0; agi < num_cores-1; agi = agi + 1)
    begin : adder_group_sync
      sync group_link_sync_to_adder (
             .clk(adder_clk),
             .in(active_group_link[agi]),
             .out(active_group_link_adder[agi])
           );
    end
  endgenerate

  cdc_bus_1deep #(.message_w(1)) active_ext_sum_wr_cdc (
      .src_clk(clk),
      .dst_clk(adder_clk),
      .reset(reset),
      .src_data(1'b1),
      .src_valid(active_ext_sum_wr),
      .src_ready(),
      .dst_data(active_ext_sum_wr_adder_data_unused),
      .dst_valid(active_ext_sum_wr_adder),
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
                     .multi_core_inst(active_multi_core_inst_adder),
                     .core_enable_mask(active_core_enable_mask_adder),
                     .group_link(active_group_link_adder),
                     .ext_sum_wr_cmd(active_ext_sum_wr_adder),
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
  assign ext_sum_empty = &(core_ext_sum_empty_cc_adder | ~active_core_enable_mask);
  assign out = core_out;

endmodule
