`timescale 1ns/1ps

module fullchip_b2_tb;

  localparam integer total_cycle = 8;
  localparam integer num_tiles = 2;
  localparam integer bw = 8;
  localparam integer pr = 8;
  localparam integer col = 8;
  localparam integer num_cores = 4;
  localparam integer bw_psum = 2*bw + 6;
  localparam integer sum_out_bw = bw_psum + 4;
  localparam integer sum_in_bw = sum_out_bw + 2;
  localparam integer core_inst_w = 23;

  integer qk_file;
  integer keep_file;
  integer norm_file;
  integer thresh_file;
  integer scan_ok;
  integer captured_data;
  integer i;
  integer j;
  integer k;
  integer wait_ctr;
  integer got_lane;
  integer exp_lane;
  integer got_sum;
  integer exp_sum;
  integer errors;
  integer tile_idx;
  integer core_idx;
  integer row_idx;

  integer qk_raw [0:num_tiles-1][0:num_cores-1][0:total_cycle-1][0:col-1];
  integer row_abs [0:num_tiles-1][0:num_cores-1][0:total_cycle-1];
  integer b2_keep [0:num_tiles-1][0:num_cores-1][0:total_cycle-1];
  integer norm_b2_only [0:num_tiles-1][0:num_cores-1][0:total_cycle-1][0:col-1];
  integer b2_threshold [0:num_tiles-1][0:num_cores-1];
  reg [bw_psum*col-1:0] forced_pmem_row;
  reg [bw_psum*col-1:0] forced_pmem_row_core0;
  reg [bw_psum*col-1:0] forced_pmem_row_core1;
  reg [bw_psum*col-1:0] forced_pmem_row_core2;
  reg [bw_psum*col-1:0] forced_pmem_row_core3;
  string dataset_name;

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
  reg b2_cfg_wr;
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

  assign inst[16] = b2_cfg_wr;
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

  function automatic integer core_sum_valid_value;
    input integer core_id;
    begin
      case (core_id)
        0: core_sum_valid_value = dut.core_cluster[0].core_instance.sfp_row_inst.sum_valid_q;
        1: core_sum_valid_value = dut.core_cluster[1].core_instance.sfp_row_inst.sum_valid_q;
        2: core_sum_valid_value = dut.core_cluster[2].core_instance.sfp_row_inst.sum_valid_q;
        default: core_sum_valid_value = dut.core_cluster[3].core_instance.sfp_row_inst.sum_valid_q;
      endcase
    end
  endfunction

  function automatic integer core_sum_value;
    input integer core_id;
    begin
      case (core_id)
        0: core_sum_value = $unsigned(dut.core_cluster[0].core_instance.sfp_row_inst.sum_q);
        1: core_sum_value = $unsigned(dut.core_cluster[1].core_instance.sfp_row_inst.sum_q);
        2: core_sum_value = $unsigned(dut.core_cluster[2].core_instance.sfp_row_inst.sum_q);
        default: core_sum_value = $unsigned(dut.core_cluster[3].core_instance.sfp_row_inst.sum_q);
      endcase
    end
  endfunction

  function automatic integer core_threshold_bank_value;
    input integer core_id;
    input integer bank_sel;
    begin
      case (core_id)
        0: core_threshold_bank_value = bank_sel ?
            dut.core_cluster[0].core_instance.threshold_bank1_q :
            dut.core_cluster[0].core_instance.threshold_bank0_q;
        1: core_threshold_bank_value = bank_sel ?
            dut.core_cluster[1].core_instance.threshold_bank1_q :
            dut.core_cluster[1].core_instance.threshold_bank0_q;
        2: core_threshold_bank_value = bank_sel ?
            dut.core_cluster[2].core_instance.threshold_bank1_q :
            dut.core_cluster[2].core_instance.threshold_bank0_q;
        default: core_threshold_bank_value = bank_sel ?
            dut.core_cluster[3].core_instance.threshold_bank1_q :
            dut.core_cluster[3].core_instance.threshold_bank0_q;
      endcase
    end
  endfunction

  function automatic integer core_active_threshold_value;
    input integer core_id;
    begin
      case (core_id)
        0: core_active_threshold_value = dut.core_cluster[0].core_instance.sfp_row_inst.threshold_sum_q;
        1: core_active_threshold_value = dut.core_cluster[1].core_instance.sfp_row_inst.threshold_sum_q;
        2: core_active_threshold_value = dut.core_cluster[2].core_instance.sfp_row_inst.threshold_sum_q;
        default: core_active_threshold_value = dut.core_cluster[3].core_instance.sfp_row_inst.threshold_sum_q;
      endcase
    end
  endfunction

  function automatic integer all_core_sum_valid;
    begin
      all_core_sum_valid = core_sum_valid_value(0) &&
                           core_sum_valid_value(1) &&
                           core_sum_valid_value(2) &&
                           core_sum_valid_value(3);
    end
  endfunction

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
      b2_cfg_wr = 1'b0;
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

  task automatic load_core_tile_dataset;
    input integer tile_id;
    input integer core_id;
    begin
      $sformat(dataset_name, "Step6/datafiles/fullchip_b2_case/tile%02d_core%0d_qk_full.txt", tile_id, core_id);
      qk_file = $fopen(dataset_name, "r");
      if (qk_file == 0) begin
        $display("FAIL: cannot open %0s", dataset_name);
        errors = errors + 1;
      end else begin
        for (i = 0; i < total_cycle; i = i + 1) begin
          for (j = 0; j < col; j = j + 1) begin
            scan_ok = $fscanf(qk_file, "%d", captured_data);
            if (scan_ok != 1) begin
              $display("FAIL malformed qk_full tile=%0d core=%0d row=%0d lane=%0d", tile_id, core_id, i, j);
              errors = errors + 1;
              captured_data = 0;
            end
            qk_raw[tile_id][core_id][i][j] = captured_data;
          end
        end
        $fclose(qk_file);
      end

      $sformat(dataset_name, "Step6/datafiles/fullchip_b2_case/tile%02d_core%0d_b2_only_keep_mask.txt", tile_id, core_id);
      keep_file = $fopen(dataset_name, "r");
      if (keep_file == 0) begin
        $display("FAIL: cannot open %0s", dataset_name);
        errors = errors + 1;
      end else begin
        for (i = 0; i < total_cycle; i = i + 1) begin
          scan_ok = $fscanf(keep_file, "%d", captured_data);
          if (scan_ok != 1) begin
            $display("FAIL malformed keep mask tile=%0d core=%0d row=%0d", tile_id, core_id, i);
            errors = errors + 1;
            captured_data = 0;
          end
          b2_keep[tile_id][core_id][i] = captured_data;
        end
        $fclose(keep_file);
      end

      $sformat(dataset_name, "Step6/datafiles/fullchip_b2_case/tile%02d_core%0d_norm_b2_only.txt", tile_id, core_id);
      norm_file = $fopen(dataset_name, "r");
      if (norm_file == 0) begin
        $display("FAIL: cannot open %0s", dataset_name);
        errors = errors + 1;
      end else begin
        for (i = 0; i < total_cycle; i = i + 1) begin
          for (j = 0; j < col; j = j + 1) begin
            scan_ok = $fscanf(norm_file, "%d", captured_data);
            if (scan_ok != 1) begin
              $display("FAIL malformed norm tile=%0d core=%0d row=%0d lane=%0d", tile_id, core_id, i, j);
              errors = errors + 1;
              captured_data = 0;
            end
            norm_b2_only[tile_id][core_id][i][j] = captured_data;
          end
        end
        $fclose(norm_file);
      end

      $sformat(dataset_name, "Step6/datafiles/fullchip_b2_case/tile%02d_core%0d_b2_only_threshold.txt", tile_id, core_id);
      thresh_file = $fopen(dataset_name, "r");
      if (thresh_file == 0) begin
        $display("FAIL: cannot open %0s", dataset_name);
        errors = errors + 1;
      end else begin
        scan_ok = $fscanf(thresh_file, "%d", captured_data);
        if (scan_ok != 1) begin
          $display("FAIL malformed threshold tile=%0d core=%0d", tile_id, core_id);
          errors = errors + 1;
          captured_data = 0;
        end
        b2_threshold[tile_id][core_id] = captured_data;
        $fclose(thresh_file);
      end
    end
  endtask

  task load_dataset;
    begin
      for (tile_idx = 0; tile_idx < num_tiles; tile_idx = tile_idx + 1)
        for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1)
          load_core_tile_dataset(tile_idx, core_idx);
    end
  endtask

  task build_expected_model;
    integer keep_expected;
    begin
      for (tile_idx = 0; tile_idx < num_tiles; tile_idx = tile_idx + 1) begin
        for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1) begin
          for (row_idx = 0; row_idx < total_cycle; row_idx = row_idx + 1) begin
            row_abs[tile_idx][core_idx][row_idx] = 0;
            for (j = 0; j < col; j = j + 1) begin
              if (qk_raw[tile_idx][core_idx][row_idx][j] < 0)
                row_abs[tile_idx][core_idx][row_idx] =
                  row_abs[tile_idx][core_idx][row_idx] - qk_raw[tile_idx][core_idx][row_idx][j];
              else
                row_abs[tile_idx][core_idx][row_idx] =
                  row_abs[tile_idx][core_idx][row_idx] + qk_raw[tile_idx][core_idx][row_idx][j];
            end

            keep_expected = (row_abs[tile_idx][core_idx][row_idx] >= b2_threshold[tile_idx][core_idx]) ? 1 : 0;
            if (b2_keep[tile_idx][core_idx][row_idx] !== keep_expected) begin
              $display("FAIL keep mismatch tile=%0d core=%0d row=%0d got=%0d exp=%0d threshold=%0d row_abs=%0d",
                       tile_idx,
                       core_idx,
                       row_idx,
                       b2_keep[tile_idx][core_idx][row_idx],
                       keep_expected,
                       b2_threshold[tile_idx][core_idx],
                       row_abs[tile_idx][core_idx][row_idx]);
              errors = errors + 1;
            end
          end
        end
      end
    end
  endtask

  task automatic pack_dataset_row;
    input integer tile_id;
    input integer core_id;
    input integer row_id;
    input integer use_norm;
    integer lane_idx;
    integer lane_value;
    begin
      forced_pmem_row = {bw_psum*col{1'b0}};
      for (lane_idx = 0; lane_idx < col; lane_idx = lane_idx + 1) begin
        lane_value = use_norm ?
                     norm_b2_only[tile_id][core_id][row_id][lane_idx] :
                     qk_raw[tile_id][core_id][row_id][lane_idx];
        forced_pmem_row[(lane_idx*bw_psum) +: bw_psum] = lane_value[bw_psum-1:0];
      end
    end
  endtask

  task automatic write_core_bank_row;
    input integer core_id;
    input integer bank_sel;
    input integer row_id;
    begin
      case (bank_sel)
        0: begin
          case (core_id)
            0: case (row_id)
                 0: dut.core_cluster[0].core_instance.psum_mem_instance_0.memory0 = forced_pmem_row;
                 1: dut.core_cluster[0].core_instance.psum_mem_instance_0.memory1 = forced_pmem_row;
                 2: dut.core_cluster[0].core_instance.psum_mem_instance_0.memory2 = forced_pmem_row;
                 3: dut.core_cluster[0].core_instance.psum_mem_instance_0.memory3 = forced_pmem_row;
                 4: dut.core_cluster[0].core_instance.psum_mem_instance_0.memory4 = forced_pmem_row;
                 5: dut.core_cluster[0].core_instance.psum_mem_instance_0.memory5 = forced_pmem_row;
                 6: dut.core_cluster[0].core_instance.psum_mem_instance_0.memory6 = forced_pmem_row;
                 7: dut.core_cluster[0].core_instance.psum_mem_instance_0.memory7 = forced_pmem_row;
               endcase
            1: case (row_id)
                 0: dut.core_cluster[1].core_instance.psum_mem_instance_0.memory0 = forced_pmem_row;
                 1: dut.core_cluster[1].core_instance.psum_mem_instance_0.memory1 = forced_pmem_row;
                 2: dut.core_cluster[1].core_instance.psum_mem_instance_0.memory2 = forced_pmem_row;
                 3: dut.core_cluster[1].core_instance.psum_mem_instance_0.memory3 = forced_pmem_row;
                 4: dut.core_cluster[1].core_instance.psum_mem_instance_0.memory4 = forced_pmem_row;
                 5: dut.core_cluster[1].core_instance.psum_mem_instance_0.memory5 = forced_pmem_row;
                 6: dut.core_cluster[1].core_instance.psum_mem_instance_0.memory6 = forced_pmem_row;
                 7: dut.core_cluster[1].core_instance.psum_mem_instance_0.memory7 = forced_pmem_row;
               endcase
            2: case (row_id)
                 0: dut.core_cluster[2].core_instance.psum_mem_instance_0.memory0 = forced_pmem_row;
                 1: dut.core_cluster[2].core_instance.psum_mem_instance_0.memory1 = forced_pmem_row;
                 2: dut.core_cluster[2].core_instance.psum_mem_instance_0.memory2 = forced_pmem_row;
                 3: dut.core_cluster[2].core_instance.psum_mem_instance_0.memory3 = forced_pmem_row;
                 4: dut.core_cluster[2].core_instance.psum_mem_instance_0.memory4 = forced_pmem_row;
                 5: dut.core_cluster[2].core_instance.psum_mem_instance_0.memory5 = forced_pmem_row;
                 6: dut.core_cluster[2].core_instance.psum_mem_instance_0.memory6 = forced_pmem_row;
                 7: dut.core_cluster[2].core_instance.psum_mem_instance_0.memory7 = forced_pmem_row;
               endcase
            default: case (row_id)
                 0: dut.core_cluster[3].core_instance.psum_mem_instance_0.memory0 = forced_pmem_row;
                 1: dut.core_cluster[3].core_instance.psum_mem_instance_0.memory1 = forced_pmem_row;
                 2: dut.core_cluster[3].core_instance.psum_mem_instance_0.memory2 = forced_pmem_row;
                 3: dut.core_cluster[3].core_instance.psum_mem_instance_0.memory3 = forced_pmem_row;
                 4: dut.core_cluster[3].core_instance.psum_mem_instance_0.memory4 = forced_pmem_row;
                 5: dut.core_cluster[3].core_instance.psum_mem_instance_0.memory5 = forced_pmem_row;
                 6: dut.core_cluster[3].core_instance.psum_mem_instance_0.memory6 = forced_pmem_row;
                 7: dut.core_cluster[3].core_instance.psum_mem_instance_0.memory7 = forced_pmem_row;
               endcase
          endcase
        end

        default: begin
          case (core_id)
            0: case (row_id)
                 0: dut.core_cluster[0].core_instance.psum_mem_instance_1.memory0 = forced_pmem_row;
                 1: dut.core_cluster[0].core_instance.psum_mem_instance_1.memory1 = forced_pmem_row;
                 2: dut.core_cluster[0].core_instance.psum_mem_instance_1.memory2 = forced_pmem_row;
                 3: dut.core_cluster[0].core_instance.psum_mem_instance_1.memory3 = forced_pmem_row;
                 4: dut.core_cluster[0].core_instance.psum_mem_instance_1.memory4 = forced_pmem_row;
                 5: dut.core_cluster[0].core_instance.psum_mem_instance_1.memory5 = forced_pmem_row;
                 6: dut.core_cluster[0].core_instance.psum_mem_instance_1.memory6 = forced_pmem_row;
                 7: dut.core_cluster[0].core_instance.psum_mem_instance_1.memory7 = forced_pmem_row;
               endcase
            1: case (row_id)
                 0: dut.core_cluster[1].core_instance.psum_mem_instance_1.memory0 = forced_pmem_row;
                 1: dut.core_cluster[1].core_instance.psum_mem_instance_1.memory1 = forced_pmem_row;
                 2: dut.core_cluster[1].core_instance.psum_mem_instance_1.memory2 = forced_pmem_row;
                 3: dut.core_cluster[1].core_instance.psum_mem_instance_1.memory3 = forced_pmem_row;
                 4: dut.core_cluster[1].core_instance.psum_mem_instance_1.memory4 = forced_pmem_row;
                 5: dut.core_cluster[1].core_instance.psum_mem_instance_1.memory5 = forced_pmem_row;
                 6: dut.core_cluster[1].core_instance.psum_mem_instance_1.memory6 = forced_pmem_row;
                 7: dut.core_cluster[1].core_instance.psum_mem_instance_1.memory7 = forced_pmem_row;
               endcase
            2: case (row_id)
                 0: dut.core_cluster[2].core_instance.psum_mem_instance_1.memory0 = forced_pmem_row;
                 1: dut.core_cluster[2].core_instance.psum_mem_instance_1.memory1 = forced_pmem_row;
                 2: dut.core_cluster[2].core_instance.psum_mem_instance_1.memory2 = forced_pmem_row;
                 3: dut.core_cluster[2].core_instance.psum_mem_instance_1.memory3 = forced_pmem_row;
                 4: dut.core_cluster[2].core_instance.psum_mem_instance_1.memory4 = forced_pmem_row;
                 5: dut.core_cluster[2].core_instance.psum_mem_instance_1.memory5 = forced_pmem_row;
                 6: dut.core_cluster[2].core_instance.psum_mem_instance_1.memory6 = forced_pmem_row;
                 7: dut.core_cluster[2].core_instance.psum_mem_instance_1.memory7 = forced_pmem_row;
               endcase
            default: case (row_id)
                 0: dut.core_cluster[3].core_instance.psum_mem_instance_1.memory0 = forced_pmem_row;
                 1: dut.core_cluster[3].core_instance.psum_mem_instance_1.memory1 = forced_pmem_row;
                 2: dut.core_cluster[3].core_instance.psum_mem_instance_1.memory2 = forced_pmem_row;
                 3: dut.core_cluster[3].core_instance.psum_mem_instance_1.memory3 = forced_pmem_row;
                 4: dut.core_cluster[3].core_instance.psum_mem_instance_1.memory4 = forced_pmem_row;
                 5: dut.core_cluster[3].core_instance.psum_mem_instance_1.memory5 = forced_pmem_row;
                 6: dut.core_cluster[3].core_instance.psum_mem_instance_1.memory6 = forced_pmem_row;
                 7: dut.core_cluster[3].core_instance.psum_mem_instance_1.memory7 = forced_pmem_row;
               endcase
          endcase
        end
      endcase
    end
  endtask

  task automatic force_core_pmem_row;
    input integer core_id;
    input integer bank_sel;
    begin
      case (core_id)
        0: begin
          forced_pmem_row_core0 = forced_pmem_row;
          if (bank_sel) begin
            force dut.core_cluster[0].core_instance.pmem_out_1 = forced_pmem_row_core0;
            force dut.core_cluster[0].core_instance.pmem_out_0 = {bw_psum*col{1'b0}};
          end else begin
            force dut.core_cluster[0].core_instance.pmem_out_0 = forced_pmem_row_core0;
            force dut.core_cluster[0].core_instance.pmem_out_1 = {bw_psum*col{1'b0}};
          end
        end
        1: begin
          forced_pmem_row_core1 = forced_pmem_row;
          if (bank_sel) begin
            force dut.core_cluster[1].core_instance.pmem_out_1 = forced_pmem_row_core1;
            force dut.core_cluster[1].core_instance.pmem_out_0 = {bw_psum*col{1'b0}};
          end else begin
            force dut.core_cluster[1].core_instance.pmem_out_0 = forced_pmem_row_core1;
            force dut.core_cluster[1].core_instance.pmem_out_1 = {bw_psum*col{1'b0}};
          end
        end
        2: begin
          forced_pmem_row_core2 = forced_pmem_row;
          if (bank_sel) begin
            force dut.core_cluster[2].core_instance.pmem_out_1 = forced_pmem_row_core2;
            force dut.core_cluster[2].core_instance.pmem_out_0 = {bw_psum*col{1'b0}};
          end else begin
            force dut.core_cluster[2].core_instance.pmem_out_0 = forced_pmem_row_core2;
            force dut.core_cluster[2].core_instance.pmem_out_1 = {bw_psum*col{1'b0}};
          end
        end
        default: begin
          forced_pmem_row_core3 = forced_pmem_row;
          if (bank_sel) begin
            force dut.core_cluster[3].core_instance.pmem_out_1 = forced_pmem_row_core3;
            force dut.core_cluster[3].core_instance.pmem_out_0 = {bw_psum*col{1'b0}};
          end else begin
            force dut.core_cluster[3].core_instance.pmem_out_0 = forced_pmem_row_core3;
            force dut.core_cluster[3].core_instance.pmem_out_1 = {bw_psum*col{1'b0}};
          end
        end
      endcase
    end
  endtask

  task automatic release_core_pmem_row;
    input integer core_id;
    begin
      case (core_id)
        0: begin
          release dut.core_cluster[0].core_instance.pmem_out_0;
          release dut.core_cluster[0].core_instance.pmem_out_1;
        end
        1: begin
          release dut.core_cluster[1].core_instance.pmem_out_0;
          release dut.core_cluster[1].core_instance.pmem_out_1;
        end
        2: begin
          release dut.core_cluster[2].core_instance.pmem_out_0;
          release dut.core_cluster[2].core_instance.pmem_out_1;
        end
        default: begin
          release dut.core_cluster[3].core_instance.pmem_out_0;
          release dut.core_cluster[3].core_instance.pmem_out_1;
        end
      endcase
    end
  endtask

  task force_ready_state_all;
    input integer bank_sel;
    begin
      force dut.core_cluster[0].core_instance.pmem_ready_bank_sel = bank_sel[0];
      force dut.core_cluster[1].core_instance.pmem_ready_bank_sel = bank_sel[0];
      force dut.core_cluster[2].core_instance.pmem_ready_bank_sel = bank_sel[0];
      force dut.core_cluster[3].core_instance.pmem_ready_bank_sel = bank_sel[0];
      force dut.core_cluster[0].core_instance.pmem_ready_valid = 1'b1;
      force dut.core_cluster[1].core_instance.pmem_ready_valid = 1'b1;
      force dut.core_cluster[2].core_instance.pmem_ready_valid = 1'b1;
      force dut.core_cluster[3].core_instance.pmem_ready_valid = 1'b1;
      tick(1);
    end
  endtask

  task release_ready_state_all;
    begin
      release dut.core_cluster[0].core_instance.pmem_ready_bank_sel;
      release dut.core_cluster[1].core_instance.pmem_ready_bank_sel;
      release dut.core_cluster[2].core_instance.pmem_ready_bank_sel;
      release dut.core_cluster[3].core_instance.pmem_ready_bank_sel;
      release dut.core_cluster[0].core_instance.pmem_ready_valid;
      release dut.core_cluster[1].core_instance.pmem_ready_valid;
      release dut.core_cluster[2].core_instance.pmem_ready_valid;
      release dut.core_cluster[3].core_instance.pmem_ready_valid;
    end
  endtask

  task preload_b2_threshold_rows;
    reg [5:0] local_row;
    begin
      for (tile_idx = 0; tile_idx < num_tiles; tile_idx = tile_idx + 1) begin
        local_row = tile_idx ? 6'd49 : 6'd48;
        for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1) begin
          spad_wr_data = {{(pr*bw-sum_out_bw){1'b0}}, b2_threshold[tile_idx][core_idx][sum_out_bw-1:0]};
          spad_wr_addr = {core_idx[1:0], local_row};
          spad_wr_en = 1'b1;
          tick_spad(1);
          spad_wr_en = 1'b0;
          tick_spad(1);
        end
      end
      spad_wr_data = {pr*bw{1'b0}};
      spad_wr_addr = 8'd0;
    end
  endtask

  task program_b2_threshold_bank;
    input integer bank_sel;
    begin
      @(negedge clk);
      clear_controls();
      use_spad_ctrl = 1'b1;
      ctrl_core_enable_mask_cfg = 4'b1111;
      ctrl_b2_cfg_core_mask = 4'b1111;
      ctrl_b2_cfg_addr = bank_sel ? 8'd49 : 8'd48;
      ctrl_b2_cfg_start = 1'b1;

      @(negedge clk);
      clear_controls();
      use_spad_ctrl = 1'b1;
      ctrl_core_enable_mask_cfg = 4'b1111;

      wait_ctr = 0;
      while ((ctrl_done !== 1'b1) && (wait_ctr < 64)) begin
        tick(1);
        wait_ctr = wait_ctr + 1;
        clear_controls();
        use_spad_ctrl = 1'b1;
        ctrl_core_enable_mask_cfg = 4'b1111;
      end

      if (ctrl_done !== 1'b1) begin
        $display("FAIL threshold ctrl_done timeout bank=%0d", bank_sel);
        errors = errors + 1;
      end

      @(negedge clk);
      clear_controls();
      tick(1);
    end
  endtask

  task check_threshold_bank;
    input integer tile_id;
    input integer bank_sel;
    begin
      for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1) begin
        if (core_threshold_bank_value(core_idx, bank_sel) !== b2_threshold[tile_id][core_idx][sum_out_bw-1:0]) begin
          $display("FAIL threshold bank%0d tile=%0d core=%0d got=%0d exp=%0d",
                   bank_sel,
                   tile_id,
                   core_idx,
                   core_threshold_bank_value(core_idx, bank_sel),
                   b2_threshold[tile_id][core_idx]);
          errors = errors + 1;
        end

        if (core_active_threshold_value(core_idx) !== b2_threshold[tile_id][core_idx][sum_out_bw-1:0]) begin
          $display("FAIL active threshold tile=%0d core=%0d got=%0d exp=%0d",
                   tile_id,
                   core_idx,
                   core_active_threshold_value(core_idx),
                   b2_threshold[tile_id][core_idx]);
          errors = errors + 1;
        end
      end
    end
  endtask

  task preload_norm_rows_to_bank;
    input integer tile_id;
    input integer bank_sel;
    begin
      for (row_idx = 0; row_idx < total_cycle; row_idx = row_idx + 1) begin
        for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1) begin
          pack_dataset_row(tile_id, core_idx, row_idx, 1);
          write_core_bank_row(core_idx, bank_sel, row_idx);
        end
      end
      tick(1);
    end
  endtask

  task force_raw_rows_to_sfp;
    input integer tile_id;
    input integer bank_sel;
    input integer row_id;
    begin
      for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1) begin
        pack_dataset_row(tile_id, core_idx, row_id, 0);
        force_core_pmem_row(core_idx, bank_sel);
      end
    end
  endtask

  task release_raw_row_forces;
    begin
      for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1)
        release_core_pmem_row(core_idx);
    end
  endtask

  task run_acc_rows_for_tile;
    input integer tile_id;
    input integer bank_sel;
    begin
      for (row_idx = 0; row_idx < total_cycle; row_idx = row_idx + 1) begin
        force_raw_rows_to_sfp(tile_id, bank_sel, row_idx);

        @(negedge clk);
        clear_controls();
        core_enable_mask = 4'b1111;
        pmem_rd = 1'b1;
        pmem_add = row_idx[3:0];

        @(negedge clk);
        clear_controls();
        core_enable_mask = 4'b1111;
        pmem_rd = 1'b1;
        pmem_add = row_idx[3:0];
        sfp_acc_inst = 4'b1111;

        tick(1);

        @(negedge clk);
        clear_controls();
        core_enable_mask = 4'b1111;

        wait_ctr = 0;
        while (all_core_sum_valid() && (wait_ctr < 32)) begin
          clear_controls();
          core_enable_mask = 4'b1111;
          tick(1);
          wait_ctr = wait_ctr + 1;
        end

        wait_ctr = 0;
        while (!all_core_sum_valid() && (wait_ctr < 32)) begin
          clear_controls();
          core_enable_mask = 4'b1111;
          tick(1);
          wait_ctr = wait_ctr + 1;
        end

        for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1) begin
          got_sum = core_sum_value(core_idx);
          exp_sum = row_abs[tile_id][core_idx][row_idx];
          if ((core_sum_valid_value(core_idx) !== 1) || (got_sum !== exp_sum)) begin
            $display("FAIL acc tile=%0d bank=%0d core=%0d row=%0d got_valid=%0d got_sum=%0d exp_sum=%0d",
                     tile_id,
                     bank_sel,
                     core_idx,
                     row_idx,
                     core_sum_valid_value(core_idx),
                     got_sum,
                     exp_sum);
            errors = errors + 1;
          end
        end

        @(negedge clk);
        clear_controls();
        tick(1);
        release_raw_row_forces();
      end

      clear_controls();
      tick(1);
    end
  endtask

  task check_norm_rows_for_tile;
    input integer tile_id;
    input integer bank_sel;
    begin
      for (row_idx = 0; row_idx < total_cycle; row_idx = row_idx + 1) begin
        @(negedge clk);
        clear_controls();
        core_enable_mask = 4'b1111;
        pmem_rd = 1'b1;
        qkmem_add = bank_sel[3:0];
        pmem_add = row_idx[3:0];

        @(negedge clk);
        clear_controls();
        core_enable_mask = 4'b1111;
        pmem_rd = 1'b1;
        qkmem_add = bank_sel[3:0];
        pmem_add = row_idx[3:0];

        @(posedge clk);
        #1;
        for (core_idx = 0; core_idx < num_cores; core_idx = core_idx + 1) begin
          for (j = 0; j < col; j = j + 1) begin
            got_lane = $signed(out[(((core_idx*col)+j)*bw_psum) +: bw_psum]);
            exp_lane = norm_b2_only[tile_id][core_idx][row_idx][j];
            if (got_lane !== exp_lane) begin
              $display("FAIL norm tile=%0d bank=%0d core=%0d row=%0d lane=%0d got=%0d exp=%0d keep=%0d",
                       tile_id,
                       bank_sel,
                       core_idx,
                       row_idx,
                       j,
                       got_lane,
                       exp_lane,
                       b2_keep[tile_id][core_idx][row_idx]);
              errors = errors + 1;
            end
          end
        end
      end

      @(negedge clk);
      clear_controls();
    end
  endtask

  initial begin
    $dumpfile("fullchip_b2_tb.vcd");
    $dumpvars(0, fullchip_b2_tb);

    clk = 1'b0;
    adder_clk = 1'b0;
    spad_clk = 1'b0;
    reset = 1'b1;
    errors = 0;
    clear_controls();

    load_dataset();
    build_expected_model();
    apply_reset();

    if (errors == 0) begin
      preload_b2_threshold_rows();

      for (tile_idx = 0; tile_idx < num_tiles; tile_idx = tile_idx + 1) begin
        force_ready_state_all(tile_idx);
        program_b2_threshold_bank(tile_idx);
        check_threshold_bank(tile_idx, tile_idx);
        run_acc_rows_for_tile(tile_idx, tile_idx);
        preload_norm_rows_to_bank(tile_idx, tile_idx);
        check_norm_rows_for_tile(tile_idx, tile_idx);
      end

      release_ready_state_all();
    end

    if (errors == 0)
      $display("fullchip_b2_tb PASS");
    else
      $display("fullchip_b2_tb FAIL count=%0d", errors);

    #20 $finish;
  end

endmodule
