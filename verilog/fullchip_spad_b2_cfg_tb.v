`timescale 1ns/1ps

module fullchip_spad_b2_cfg_tb;

  localparam integer bw = 8;
  localparam integer pr = 8;
  localparam integer col = 8;
  localparam integer num_cores = 4;
  localparam integer bw_psum = 2*bw + 6;
  localparam integer sum_out_bw = bw_psum + 4;
  localparam integer sum_in_bw = sum_out_bw + 2;
  localparam integer core_inst_w = 23;
  localparam integer ctrl_timeout_cycles = 128;
  localparam integer spad_core_stride = 64;
  localparam integer spad_tile_stride = 24;
  localparam integer spad_q_offset = 0;

  integer errors;
  integer wait_ctr;
  integer core_idx;
  integer row_idx;

  reg clk;
  reg adder_clk;
  reg spad_clk;
  reg reset;
  reg [pr*bw-1:0] mem_in;
  reg [num_cores-1:0] mem_in_mask;
  reg qmem_rd;
  reg qmem_wr;
  reg kmem_rd;
  reg kmem_wr;
  reg pmem_rd;
  reg pmem_wr;
  reg execute;
  reg load;
  reg [num_cores-1:0] multi_core_inst;
  reg [num_cores-1:0] core_enable_mask;
  reg [num_cores-2:0] group_link;
  reg [num_cores-1:0] sfp_acc_inst;
  reg [num_cores-1:0] sfp_div_inst;
  reg ext_sum_wr;
  reg [sum_in_bw-1:0] sum_in;
  reg [3:0] qkmem_add;
  reg [3:0] pmem_add;
  reg use_spad_ctrl;
  reg spad_wr_en;
  reg [7:0] spad_wr_addr;
  reg [pr*bw-1:0] spad_wr_data;
  reg ctrl_load_start;
  reg ctrl_load_is_q;
  reg [num_cores-1:0] ctrl_load_core_mask;
  reg [7:0] ctrl_load_len;
  reg [7:0] ctrl_load_base;
  reg ctrl_run_start;
  reg [7:0] ctrl_run_q_len;
  reg [7:0] ctrl_run_k_len;
  reg ctrl_b2_cfg_start;
  reg [num_cores-1:0] ctrl_b2_cfg_core_mask;
  reg [7:0] ctrl_b2_cfg_addr;
  reg [num_cores-1:0] ctrl_core_enable_mask_cfg;
  reg [num_cores-1:0] ctrl_multi_core_inst_cfg;
  reg [num_cores-2:0] ctrl_group_link_cfg;
  reg [num_cores-1:0] ctrl_sfp_acc_inst_cfg;
  reg [num_cores-1:0] ctrl_sfp_div_inst_cfg;

  wire [num_cores-1:0] core_clk = {num_cores{clk}};
  wire [16:0] inst;
  wire [num_cores*core_inst_w-1:0] core_inst_bus;
  wire [sum_out_bw-1:0] sum_out;
  wire sum_valid;
  wire ext_sum_empty;
  wire [num_cores*bw_psum*col-1:0] out;
  wire [num_cores*12-1:0] core_status;
  wire [num_cores*10-1:0] core_ctrl_status;
  wire [num_cores-1:0] group_sum_valid;
  wire [num_cores*sum_in_bw-1:0] group_sum_out;
  wire ctrl_busy;
  wire ctrl_done;

  assign inst[16] = 1'b0;
  assign inst[15:12] = qkmem_add;
  assign inst[11:8] = pmem_add;
  assign inst[7] = execute;
  assign inst[6] = load;
  assign inst[5] = qmem_rd;
  assign inst[4] = qmem_wr;
  assign inst[3] = kmem_rd;
  assign inst[2] = kmem_wr;
  assign inst[1] = pmem_rd;
  assign inst[0] = pmem_wr;

  genvar gi;
  generate
    for (gi = 0; gi < num_cores; gi = gi + 1) begin : core_inst_pack
      assign core_inst_bus[(core_inst_w*(gi+1))-1 : (core_inst_w*gi)] = {
        2'b00,
        core_enable_mask[gi],
        multi_core_inst[gi],
        sfp_acc_inst[gi],
        sfp_div_inst[gi],
        inst
      };
    end
  endgenerate

  fullchip #(
    .bw(bw),
    .bw_psum(bw_psum),
    .col(col),
    .pr(pr),
    .num_cores(num_cores),
    .sum_out_bw(sum_out_bw),
    .sum_in_bw(sum_in_bw)
  ) dut (
    .reset(reset),
    .clk(clk),
    .adder_clk(adder_clk),
    .spad_clk(spad_clk),
    .core_clk(core_clk),
    .mem_in(mem_in),
    .mem_in_mask(mem_in_mask),
    .core_inst(core_inst_bus),
    .half_precision(1'b0),
    .group_link(group_link),
    .ext_sum_wr(ext_sum_wr),
    .sum_in(sum_in),
    .sum_out(sum_out),
    .sum_valid(sum_valid),
    .ext_sum_empty(ext_sum_empty),
    .out(out),
    .core_status(core_status),
    .core_ctrl_status(core_ctrl_status),
    .group_sum_valid(group_sum_valid),
    .group_sum_out(group_sum_out),
    .use_spad_ctrl(use_spad_ctrl),
    .spad_wr_en(spad_wr_en),
    .spad_wr_addr(spad_wr_addr),
    .spad_wr_data(spad_wr_data),
    .ctrl_load_start(ctrl_load_start),
    .ctrl_load_is_q(ctrl_load_is_q),
    .ctrl_load_core_mask(ctrl_load_core_mask),
    .ctrl_load_len(ctrl_load_len),
    .ctrl_load_base(ctrl_load_base),
    .ctrl_run_start(ctrl_run_start),
    .ctrl_run_q_len(ctrl_run_q_len),
    .ctrl_run_k_len(ctrl_run_k_len),
    .ctrl_b2_cfg_start(ctrl_b2_cfg_start),
    .ctrl_b2_cfg_core_mask(ctrl_b2_cfg_core_mask),
    .ctrl_b2_cfg_addr(ctrl_b2_cfg_addr),
    .ctrl_core_enable_mask(ctrl_core_enable_mask_cfg),
    .ctrl_multi_core_inst(ctrl_multi_core_inst_cfg),
    .ctrl_group_link(ctrl_group_link_cfg),
    .ctrl_sfp_acc_inst(ctrl_sfp_acc_inst_cfg),
    .ctrl_sfp_div_inst(ctrl_sfp_div_inst_cfg),
    .ctrl_busy(ctrl_busy),
    .ctrl_done(ctrl_done)
  );

  always #5 clk = ~clk;
  always #4 adder_clk = ~adder_clk;
  always #3 spad_clk = ~spad_clk;

  task tick;
    input integer n;
    integer t;
    begin
      for (t = 0; t < n; t = t + 1) begin
        @(posedge clk);
        #1;
      end
    end
  endtask

  task tick_spad;
    input integer n;
    integer t;
    begin
      for (t = 0; t < n; t = t + 1) begin
        @(posedge spad_clk);
        #1;
      end
    end
  endtask

  task clear_controls;
    begin
      mem_in = {pr*bw{1'b0}};
      mem_in_mask = {num_cores{1'b0}};
      qmem_rd = 1'b0;
      qmem_wr = 1'b0;
      kmem_rd = 1'b0;
      kmem_wr = 1'b0;
      pmem_rd = 1'b0;
      pmem_wr = 1'b0;
      execute = 1'b0;
      load = 1'b0;
      multi_core_inst = {num_cores{1'b0}};
      core_enable_mask = {num_cores{1'b0}};
      group_link = {num_cores-1{1'b0}};
      sfp_acc_inst = {num_cores{1'b0}};
      sfp_div_inst = {num_cores{1'b0}};
      ext_sum_wr = 1'b0;
      sum_in = {sum_in_bw{1'b0}};
      qkmem_add = 4'd0;
      pmem_add = 4'd0;
      use_spad_ctrl = 1'b0;
      spad_wr_en = 1'b0;
      spad_wr_addr = 8'd0;
      spad_wr_data = {pr*bw{1'b0}};
      ctrl_load_start = 1'b0;
      ctrl_load_is_q = 1'b0;
      ctrl_load_core_mask = {num_cores{1'b0}};
      ctrl_load_len = 8'd0;
      ctrl_load_base = 8'd0;
      ctrl_run_start = 1'b0;
      ctrl_run_q_len = 8'd0;
      ctrl_run_k_len = 8'd0;
      ctrl_b2_cfg_start = 1'b0;
      ctrl_b2_cfg_core_mask = {num_cores{1'b0}};
      ctrl_b2_cfg_addr = 8'd0;
      ctrl_core_enable_mask_cfg = {num_cores{1'b0}};
      ctrl_multi_core_inst_cfg = {num_cores{1'b0}};
      ctrl_group_link_cfg = {num_cores-1{1'b0}};
      ctrl_sfp_acc_inst_cfg = {num_cores{1'b0}};
      ctrl_sfp_div_inst_cfg = {num_cores{1'b0}};
    end
  endtask

  task apply_reset;
    begin
      reset = 1'b1;
      tick(4);
      reset = 1'b0;
      tick(4);
    end
  endtask

  function [7:0] spad_addr;
    input integer core_id;
    input integer tile_idx;
    input integer kind_offset;
    input integer row;
    integer addr_tmp;
    begin
      addr_tmp = (core_id * spad_core_stride) +
                 (tile_idx * spad_tile_stride) +
                 kind_offset + row;
      spad_addr = addr_tmp[7:0];
    end
  endfunction

  function [bw-1:0] multicore_q_lane_seed;
    input integer core_id;
    input integer row;
    input integer lane_idx;
    integer lane_seed;
    begin
      lane_seed = (core_id * 8'h20) + (row * 8'h08) + lane_idx + 1;
      multicore_q_lane_seed = lane_seed[bw-1:0];
    end
  endfunction

  function [pr*bw-1:0] multicore_q_row_seed;
    input integer core_id;
    input integer row;
    integer lane_idx;
    reg [pr*bw-1:0] row_bits;
    begin
      row_bits = {pr*bw{1'b0}};
      for (lane_idx = 0; lane_idx < pr; lane_idx = lane_idx + 1)
        row_bits[(lane_idx*bw) +: bw] = multicore_q_lane_seed(core_id, row, lane_idx);
      multicore_q_row_seed = row_bits;
    end
  endfunction

  function [pr*bw-1:0] core_qmem_bank1_row;
    input integer core_id;
    input integer row;
    begin
      case (core_id)
        0:
          case (row)
            0: core_qmem_bank1_row = dut.core_cluster[0].core_instance.qmem_instance_1.memory0;
            1: core_qmem_bank1_row = dut.core_cluster[0].core_instance.qmem_instance_1.memory1;
            default: core_qmem_bank1_row = {pr*bw{1'b0}};
          endcase
        1:
          case (row)
            0: core_qmem_bank1_row = dut.core_cluster[1].core_instance.qmem_instance_1.memory0;
            1: core_qmem_bank1_row = dut.core_cluster[1].core_instance.qmem_instance_1.memory1;
            default: core_qmem_bank1_row = {pr*bw{1'b0}};
          endcase
        2:
          case (row)
            0: core_qmem_bank1_row = dut.core_cluster[2].core_instance.qmem_instance_1.memory0;
            1: core_qmem_bank1_row = dut.core_cluster[2].core_instance.qmem_instance_1.memory1;
            default: core_qmem_bank1_row = {pr*bw{1'b0}};
          endcase
        default:
          case (row)
            0: core_qmem_bank1_row = dut.core_cluster[3].core_instance.qmem_instance_1.memory0;
            1: core_qmem_bank1_row = dut.core_cluster[3].core_instance.qmem_instance_1.memory1;
            default: core_qmem_bank1_row = {pr*bw{1'b0}};
          endcase
      endcase
    end
  endfunction

  task wait_ctrl_done_pulse;
    begin
      wait_ctr = 0;
      while ((ctrl_done !== 1'b1) && (wait_ctr < ctrl_timeout_cycles)) begin
        tick(1);
        wait_ctr = wait_ctr + 1;
      end

      if (ctrl_done !== 1'b1) begin
        $display("FAIL controller timeout busy=%0d state=%0d idx=%0d busy_seen=%0d",
                 ctrl_busy,
                 dut.fullchip_spad_ctrl.state,
                 dut.fullchip_spad_ctrl.idx_q,
                 dut.fullchip_spad_ctrl.busy_seen_any);
        errors = errors + 1;
      end

      clear_controls();
      tick(1);
    end
  endtask

  task spad_write_threshold_all;
    input integer bank_sel;
    input integer threshold;
    reg [5:0] local_row;
    begin
      local_row = bank_sel ? 6'd49 : 6'd48;
      for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1) begin
        spad_wr_data = {{(pr*bw-sum_out_bw){1'b1}}, threshold[sum_out_bw-1:0]};
        spad_wr_addr = {core_idx[1:0], local_row};
        spad_wr_en = 1'b1;
        tick_spad(1);
        spad_wr_en = 1'b0;
        tick_spad(1);
      end
      spad_wr_data = {pr*bw{1'b0}};
      spad_wr_addr = 8'd0;
    end
  endtask

  task spad_write_multicore_q_row;
    input integer core_id;
    input integer row;
    begin
      spad_wr_data = multicore_q_row_seed(core_id, row);
      spad_wr_addr = spad_addr(core_id, 0, spad_q_offset, row);
      spad_wr_en = 1'b1;
      tick_spad(1);
      spad_wr_en = 1'b0;
      tick_spad(1);
    end
  endtask

  task controller_cfg_b2_from_spad;
    input [num_cores-1:0] core_mask;
    input [7:0] threshold_addr;
    begin
      clear_controls();
      use_spad_ctrl = 1'b1;
      ctrl_core_enable_mask_cfg = core_mask;
      ctrl_b2_cfg_core_mask = core_mask;
      ctrl_b2_cfg_addr = threshold_addr;
      ctrl_b2_cfg_start = 1'b1;
      tick(1);
      clear_controls();
      use_spad_ctrl = 1'b1;
      ctrl_core_enable_mask_cfg = core_mask;
      wait_ctrl_done_pulse();
    end
  endtask

  task controller_load_from_spad;
    input integer is_q_load;
    input [num_cores-1:0] core_mask;
    input [7:0] base_addr;
    input [7:0] row_len;
    begin
      clear_controls();
      use_spad_ctrl = 1'b1;
      ctrl_core_enable_mask_cfg = core_mask;
      ctrl_load_is_q = is_q_load[0];
      ctrl_load_core_mask = core_mask;
      ctrl_load_len = row_len;
      ctrl_load_base = base_addr;
      ctrl_load_start = 1'b1;
      tick(1);
      clear_controls();
      use_spad_ctrl = 1'b1;
      ctrl_core_enable_mask_cfg = core_mask;
      wait_ctrl_done_pulse();
    end
  endtask

  task check_thresholds_bank0;
    input integer exp0;
    input integer exp1;
    input integer exp2;
    input integer exp3;
    begin
      if (dut.core_cluster[0].core_instance.threshold_bank0_q !== exp0[sum_out_bw-1:0]) begin
        $display("FAIL core0 threshold bank0 got=%0d exp=%0d",
                 dut.core_cluster[0].core_instance.threshold_bank0_q, exp0);
        errors = errors + 1;
      end
      if (dut.core_cluster[1].core_instance.threshold_bank0_q !== exp1[sum_out_bw-1:0]) begin
        $display("FAIL core1 threshold bank0 got=%0d exp=%0d",
                 dut.core_cluster[1].core_instance.threshold_bank0_q, exp1);
        errors = errors + 1;
      end
      if (dut.core_cluster[2].core_instance.threshold_bank0_q !== exp2[sum_out_bw-1:0]) begin
        $display("FAIL core2 threshold bank0 got=%0d exp=%0d",
                 dut.core_cluster[2].core_instance.threshold_bank0_q, exp2);
        errors = errors + 1;
      end
      if (dut.core_cluster[3].core_instance.threshold_bank0_q !== exp3[sum_out_bw-1:0]) begin
        $display("FAIL core3 threshold bank0 got=%0d exp=%0d",
                 dut.core_cluster[3].core_instance.threshold_bank0_q, exp3);
        errors = errors + 1;
      end
    end
  endtask

  task check_thresholds_bank1;
    input integer exp0;
    input integer exp1;
    input integer exp2;
    input integer exp3;
    begin
      if (dut.core_cluster[0].core_instance.threshold_bank1_q !== exp0[sum_out_bw-1:0]) begin
        $display("FAIL core0 threshold bank1 got=%0d exp=%0d",
                 dut.core_cluster[0].core_instance.threshold_bank1_q, exp0);
        errors = errors + 1;
      end
      if (dut.core_cluster[1].core_instance.threshold_bank1_q !== exp1[sum_out_bw-1:0]) begin
        $display("FAIL core1 threshold bank1 got=%0d exp=%0d",
                 dut.core_cluster[1].core_instance.threshold_bank1_q, exp1);
        errors = errors + 1;
      end
      if (dut.core_cluster[2].core_instance.threshold_bank1_q !== exp2[sum_out_bw-1:0]) begin
        $display("FAIL core2 threshold bank1 got=%0d exp=%0d",
                 dut.core_cluster[2].core_instance.threshold_bank1_q, exp2);
        errors = errors + 1;
      end
      if (dut.core_cluster[3].core_instance.threshold_bank1_q !== exp3[sum_out_bw-1:0]) begin
        $display("FAIL core3 threshold bank1 got=%0d exp=%0d",
                 dut.core_cluster[3].core_instance.threshold_bank1_q, exp3);
        errors = errors + 1;
      end
    end
  endtask

  initial begin
    $dumpfile("fullchip_spad_b2_cfg_tb.vcd");
    $dumpvars(0, fullchip_spad_b2_cfg_tb);

    clk = 1'b0;
    adder_clk = 1'b0;
    spad_clk = 1'b0;
    reset = 1'b1;
    errors = 0;
    clear_controls();

    apply_reset();

    spad_write_threshold_all(0, 400);
    controller_cfg_b2_from_spad(4'b0001, 8'd48);
    check_thresholds_bank0(400, 0, 0, 0);
    check_thresholds_bank1(0, 0, 0, 0);

    spad_write_threshold_all(0, 123);
    controller_cfg_b2_from_spad(4'b1111, 8'd48);
    check_thresholds_bank0(123, 123, 123, 123);

    spad_write_threshold_all(1, 77);
    controller_cfg_b2_from_spad(4'b1111, 8'd49);
    check_thresholds_bank0(123, 123, 123, 123);
    check_thresholds_bank1(77, 77, 77, 77);

    for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1)
      for (row_idx = 0; row_idx < 2; row_idx = row_idx + 1)
        spad_write_multicore_q_row(core_idx, row_idx);

    controller_load_from_spad(1, 4'b1111, spad_addr(0, 0, spad_q_offset, 0), 8'd2);
    tick(2);

    for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1) begin
      for (row_idx = 0; row_idx < 2; row_idx = row_idx + 1) begin
        if (core_qmem_bank1_row(core_idx, row_idx) !== multicore_q_row_seed(core_idx, row_idx)) begin
          $display("FAIL qload core=%0d row=%0d got=%h exp=%h",
                   core_idx,
                   row_idx,
                   core_qmem_bank1_row(core_idx, row_idx),
                   multicore_q_row_seed(core_idx, row_idx));
          errors = errors + 1;
        end
      end
    end

    check_thresholds_bank0(123, 123, 123, 123);
    check_thresholds_bank1(77, 77, 77, 77);

    if (errors == 0)
      $display("fullchip_spad_b2_cfg_tb PASS");
    else
      $display("fullchip_spad_b2_cfg_tb FAIL count=%0d", errors);

    #20 $finish;
  end

endmodule
