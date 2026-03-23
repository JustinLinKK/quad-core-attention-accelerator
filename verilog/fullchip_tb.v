// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Modified by Jingbin Lin in ECE 260B Project, UCSD
// Extended testbench for single-core and multicore validation.
// Please do not spread this code without permission
`timescale 1ns/1ps

module fullchip_tb;

  localparam integer total_cycle = 8;
  localparam integer bw = 8;
  localparam integer pr = 8;
  localparam integer col = 8;
  localparam integer num_cores = 4;
  localparam integer bw_psum = 2*bw + 6;
  localparam integer sum_out_bw = bw_psum + 4;
  localparam integer sum_in_bw = sum_out_bw + 2;
  localparam integer core_inst_w = 23;
  localparam integer cc_settle_cycles = 20;

  integer qk_file;
  integer qk_scan_file;
  integer captured_data;
  integer out_file;
  integer fails;
  integer mismatch_count;
  integer i;
  integer j;
  integer q;
  integer lane;
  integer got_lane;
  integer exp_lane;

  integer K [0:col-1][0:pr-1];
  integer Q [0:total_cycle-1][0:pr-1];
  integer result [0:total_cycle-1][0:col-1];

  reg clk;
  reg adder_clk;
  reg spad_clk;
  wire [num_cores-1:0] core_clk;
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
  reg half_precision;
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

  reg [num_cores-1:0] recv_seen;
  integer recv_sum [0:num_cores-1];
  integer sum_valid_seen;
  integer last_sum_out;

  assign core_clk = {num_cores{clk}};

  assign inst[16] = 1'b0; // reserved
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
    for (gi = 0; gi < num_cores; gi = gi + 1)
    begin : core_inst_pack
      assign core_inst_bus[(core_inst_w*(gi+1))-1 : (core_inst_w*gi)] = {
        2'b00,
        core_enable_mask[gi],
        multi_core_inst[gi],
        sfp_acc_inst[gi],
        sfp_div_inst[gi],
        inst
      };
    end
  endgenerate;

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
             .half_precision(half_precision),
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

  always @(posedge clk)
  begin
    if (reset)
    begin
      recv_seen <= {num_cores{1'b0}};
      for (i = 0; i < num_cores; i = i + 1)
        recv_sum[i] <= 0;
      sum_valid_seen <= 0;
      last_sum_out <= 0;
    end
    else
    begin
      if (sum_valid)
      begin
        sum_valid_seen <= 1;
        last_sum_out <= $unsigned(sum_out);
      end

      for (i = 0; i < num_cores; i = i + 1)
      begin
        if (dut.cc_ext_sum_wr_core[i])
        begin
          recv_seen[i] <= 1'b1;
          recv_sum[i] <= $unsigned(dut.cc_sum_in_core[(i*sum_in_bw) +: sum_in_bw]);
        end
      end
    end
  end

  task tick;
    input integer n;
    integer t;
    begin
      for (t = 0; t < n; t = t + 1)
      begin
        @(posedge clk);
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
      half_precision = 1'b0;
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

  task load_input_files;
    begin
      qk_file = $fopen("Step6/datafiles/qdata.txt", "r");
      if (qk_file == 0)
      begin
        $display("FAIL: cannot open Step6/datafiles/qdata.txt");
        fails = fails + 1;
      end
      else
      begin
        for (q = 0; q < total_cycle; q = q + 1)
        begin
          for (j = 0; j < pr; j = j + 1)
          begin
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            Q[q][j] = captured_data;
          end
        end
        $fclose(qk_file);
      end

      qk_file = $fopen("Step6/datafiles/kdata.txt", "r");
      if (qk_file == 0)
      begin
        $display("FAIL: cannot open Step6/datafiles/kdata.txt");
        fails = fails + 1;
      end
      else
      begin
        for (q = 0; q < col; q = q + 1)
        begin
          for (j = 0; j < pr; j = j + 1)
          begin
            qk_scan_file = $fscanf(qk_file, "%d\n", captured_data);
            K[q][j] = captured_data;
          end
        end
        $fclose(qk_file);
      end
    end
  endtask

  task build_expected_results;
    integer t;
    integer c;
    integer k;
    begin
      for (t = 0; t < total_cycle; t = t + 1)
      begin
        for (c = 0; c < col; c = c + 1)
        begin
          result[t][c] = 0;
          for (k = 0; k < pr; k = k + 1)
            result[t][c] = result[t][c] + Q[t][k] * K[c][k];
        end
      end
    end
  endtask

  task drive_q_vector;
    input integer idx;
    begin
      for (lane = 0; lane < pr; lane = lane + 1)
        mem_in[(lane*bw) +: bw] = Q[idx][lane][bw-1:0];
    end
  endtask

  task drive_k_vector;
    input integer idx;
    begin
      for (lane = 0; lane < pr; lane = lane + 1)
        mem_in[(lane*bw) +: bw] = K[idx][lane][bw-1:0];
    end
  endtask

  task run_single_core_test;
    begin
      $display("===== single-core functional test =====");
      mismatch_count = 0;

      clear_controls();
      apply_reset();

      core_enable_mask = 4'b0001;
      mem_in_mask = 4'b0001;

      for (q = 0; q < total_cycle; q = q + 1)
      begin
        @(negedge clk);
        qmem_wr = 1'b1;
        qkmem_add = q[3:0];
        drive_q_vector(q);
      end
      @(negedge clk);
      qmem_wr = 1'b0;
      qkmem_add = 4'd0;
      mem_in = {pr*bw{1'b0}};
      tick(1);

      for (q = 0; q < col; q = q + 1)
      begin
        @(negedge clk);
        kmem_wr = 1'b1;
        qkmem_add = q[3:0];
        drive_k_vector(q);
      end
      @(negedge clk);
      kmem_wr = 1'b0;
      qkmem_add = 4'd0;
      mem_in = {pr*bw{1'b0}};
      tick(2);

      for (q = 0; q < col+1; q = q + 1)
      begin
        @(negedge clk);
        load = 1'b1;
        if (q == 1)
          kmem_rd = 1'b1;
        if (q > 1)
          qkmem_add = q - 1;
      end
      @(negedge clk);
      kmem_rd = 1'b0;
      qkmem_add = 4'd0;
      @(negedge clk);
      load = 1'b0;

      tick(10);

      for (q = 0; q < total_cycle; q = q + 1)
      begin
        @(negedge clk);
        execute = 1'b1;
        qmem_rd = 1'b1;
        qkmem_add = q[3:0];
      end
      @(negedge clk);
      execute = 1'b0;
      qmem_rd = 1'b0;
      qkmem_add = 4'd0;

      tick(10);

      for (q = 0; q < total_cycle; q = q + 1)
      begin
        @(negedge clk);
        execute = 1'b1;
        qkmem_add = q[3:0];
      end
      @(negedge clk);
      execute = 1'b0;
      qkmem_add = 4'd0;

      tick(2);

      for (q = 0; q < total_cycle; q = q + 1)
      begin
        @(negedge clk);
        pmem_wr = 1'b1;
        pmem_add = q[3:0];
        @(negedge clk);
        pmem_wr = 1'b0;
        pmem_add = 4'd0;
      end
      tick(1);

      out_file = $fopen("out_single_core.txt", "w");
      if (out_file == 0)
      begin
        $display("FAIL: cannot open out_single_core.txt");
        fails = fails + 1;
      end

      for (q = 0; q < total_cycle; q = q + 1)
      begin
        @(negedge clk);
        pmem_rd = 1'b1;
        pmem_add = q[3:0];
        @(posedge clk);
        #1;

        @(negedge clk);
        pmem_rd = 1'b1;
        pmem_add = q[3:0];
        @(posedge clk);
        #1;

        for (lane = 0; lane < col; lane = lane + 1)
        begin
          got_lane = $signed(out[(lane*bw_psum) +: bw_psum]);
          exp_lane = result[q][col-1-lane];
          if (got_lane !== exp_lane)
          begin
            mismatch_count = mismatch_count + 1;
            $display("Mismatch row=%0d lane=%0d got=%0d exp=%0d", q, lane, got_lane, exp_lane);
          end
          if (out_file != 0)
          begin
            if (lane == col-1)
              $fwrite(out_file, "%0d\n", got_lane);
            else
              $fwrite(out_file, "%0d\t", got_lane);
          end
        end
      end

      @(negedge clk);
      pmem_rd = 1'b0;
      pmem_add = 4'd0;

      if (out_file != 0)
        $fclose(out_file);

      if (mismatch_count == 0)
        $display("single-core PASS: %0d rows matched expected QxK.", total_cycle);
      else
      begin
        $display("single-core FAIL: %0d mismatches.", mismatch_count);
        fails = fails + 1;
      end
    end
  endtask

  task clear_multicore_capture;
    begin
      recv_seen = {num_cores{1'b0}};
      for (i = 0; i < num_cores; i = i + 1)
        recv_sum[i] = 0;
      sum_valid_seen = 0;
      last_sum_out = 0;
    end
  endtask

  task inject_core_sum;
    input integer core_idx;
    input integer sum_value;
    begin
      case (core_idx)
        0:
        begin
          force dut.core_sum_out_local[sum_out_bw*1-1:sum_out_bw*0] = sum_value[sum_out_bw-1:0];
          force dut.core_sum_valid_local[0] = 1'b1;
        end
        1:
        begin
          force dut.core_sum_out_local[sum_out_bw*2-1:sum_out_bw*1] = sum_value[sum_out_bw-1:0];
          force dut.core_sum_valid_local[1] = 1'b1;
        end
        2:
        begin
          force dut.core_sum_out_local[sum_out_bw*3-1:sum_out_bw*2] = sum_value[sum_out_bw-1:0];
          force dut.core_sum_valid_local[2] = 1'b1;
        end
        default:
        begin
          force dut.core_sum_out_local[sum_out_bw*4-1:sum_out_bw*3] = sum_value[sum_out_bw-1:0];
          force dut.core_sum_valid_local[3] = 1'b1;
        end
      endcase
      tick(1);
      case (core_idx)
        0:
        begin
          release dut.core_sum_out_local[sum_out_bw*1-1:sum_out_bw*0];
          release dut.core_sum_valid_local[0];
        end
        1:
        begin
          release dut.core_sum_out_local[sum_out_bw*2-1:sum_out_bw*1];
          release dut.core_sum_valid_local[1];
        end
        2:
        begin
          release dut.core_sum_out_local[sum_out_bw*3-1:sum_out_bw*2];
          release dut.core_sum_valid_local[2];
        end
        default:
        begin
          release dut.core_sum_out_local[sum_out_bw*4-1:sum_out_bw*3];
          release dut.core_sum_valid_local[3];
        end
      endcase
      tick(1);
    end
  endtask

  task pulse_ext_sum_wr;
    begin
      @(negedge clk);
      ext_sum_wr = 1'b1;
      @(negedge clk);
      ext_sum_wr = 1'b0;
    end
  endtask

  task check_recv_entry;
    input integer core_idx;
    input integer exp_seen;
    input integer exp_sum;
    begin
      if (recv_seen[core_idx] !== exp_seen[0])
      begin
        $display("FAIL multicore: core%0d seen got=%0d exp=%0d", core_idx, recv_seen[core_idx], exp_seen);
        fails = fails + 1;
      end
      if (exp_seen && (recv_sum[core_idx] !== exp_sum))
      begin
        $display("FAIL multicore: core%0d sum got=%0d exp=%0d", core_idx, recv_sum[core_idx], exp_sum);
        fails = fails + 1;
      end
    end
  endtask

  task run_multicore_tests;
    begin
      $display("===== multicore grouping test =====");

      clear_controls();
      apply_reset();

      core_enable_mask = 4'b1111;
      mem_in_mask = 4'b1111;
      multi_core_inst = 4'b1111;
      group_link = 3'b101; // groups: [0,1] and [2,3]
      clear_multicore_capture();
      tick(cc_settle_cycles);

      inject_core_sum(0, 3);
      inject_core_sum(1, 5);
      inject_core_sum(2, 7);
      inject_core_sum(3, 11);
      tick(cc_settle_cycles);
      pulse_ext_sum_wr();
      tick(cc_settle_cycles);

      check_recv_entry(0, 1, 8);
      check_recv_entry(1, 1, 8);
      check_recv_entry(2, 1, 18);
      check_recv_entry(3, 1, 18);
      if (!sum_valid_seen || (last_sum_out !== 8))
      begin
        $display("FAIL multicore: sum_valid/sum_out core0-group got valid=%0d sum=%0d exp_sum=8", sum_valid_seen, last_sum_out);
        fails = fails + 1;
      end

      $display("===== sparse multicore mask test =====");
      clear_controls();
      apply_reset();

      core_enable_mask = 4'b1111;
      mem_in_mask = 4'b1111;
      multi_core_inst = 4'b0101; // cores 0 and 2 only
      group_link = 3'b000;
      clear_multicore_capture();
      tick(cc_settle_cycles);

      inject_core_sum(0, 9);
      inject_core_sum(2, 4);
      tick(cc_settle_cycles);
      pulse_ext_sum_wr();
      tick(cc_settle_cycles);

      check_recv_entry(0, 1, 9);
      check_recv_entry(1, 0, 0);
      check_recv_entry(2, 1, 4);
      check_recv_entry(3, 0, 0);
      if (!sum_valid_seen || (last_sum_out !== 9))
      begin
        $display("FAIL sparse multicore: sum_valid/sum_out got valid=%0d sum=%0d exp_sum=9", sum_valid_seen, last_sum_out);
        fails = fails + 1;
      end

      $display("===== disabled-core isolation test =====");
      clear_controls();
      apply_reset();

      core_enable_mask = 4'b0011; // cores 2/3 disabled
      mem_in_mask = 4'b1111;
      multi_core_inst = 4'b1111;
      group_link = 3'b111;
      clear_multicore_capture();
      tick(cc_settle_cycles);

      inject_core_sum(0, 6);
      inject_core_sum(1, 10);
      inject_core_sum(2, 21); // should be ignored due to disabled core
      tick(cc_settle_cycles);
      pulse_ext_sum_wr();
      tick(cc_settle_cycles);

      check_recv_entry(0, 1, 16);
      check_recv_entry(1, 1, 16);
      check_recv_entry(2, 0, 0);
      check_recv_entry(3, 0, 0);
      if (!sum_valid_seen || (last_sum_out !== 16))
      begin
        $display("FAIL disabled-core case: sum_valid/sum_out got valid=%0d sum=%0d exp_sum=16", sum_valid_seen, last_sum_out);
        fails = fails + 1;
      end
    end
  endtask

  initial
  begin
    $dumpfile("fullchip_tb.vcd");
    $dumpvars(0, fullchip_tb);

    clk = 1'b0;
    adder_clk = 1'b0;
    spad_clk = 1'b0;
    reset = 1'b1;
    fails = 0;
    clear_controls();

    load_input_files();
    build_expected_results();

    if (fails == 0)
      run_single_core_test();

    run_multicore_tests();

    if (fails == 0)
      $display("fullchip_tb PASS");
    else
      $display("fullchip_tb FAIL count=%0d", fails);

    #20 $finish;
  end

endmodule

