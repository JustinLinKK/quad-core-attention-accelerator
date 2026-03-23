// Created by Jingbin Lin in ECE 260B Project, UCSD
// Updated for 2-tile end-to-end single-core validation.
// Please do not spread this code without permission
`timescale 1ns/1ps

module core_single_tb;

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 22;
parameter pr = 8;

localparam integer sum_out_bw = bw_psum + 4;
localparam integer sum_in_bw = bw_psum + 6;
localparam integer tile_count = 2;
localparam integer tile_rows = 8;
localparam integer sfp_acc_latency = 2;
localparam integer sfp_div_latency = (3 * ((bw_psum + 1) / 2)) + 1;
localparam integer mac_settle_cycles = 10;
localparam integer pmem_write_settle_cycles = 2;
localparam integer ofifo_wait_max = 128;
localparam integer enable_bank_checks = 0;

integer i;
integer j;
integer k;
integer t;
integer errors;
integer cyc;
integer row_abs_sum;
integer wait_ctr;
integer got_val;
integer exp_val;

reg clk;
reg reset;
reg [pr*bw-1:0] mem_in;
reg [22:0] inst;
reg [sum_in_bw-1:0] sum_in;
reg ext_sum_wr;

wire [sum_out_bw-1:0] sum_out;
wire [bw_psum*col-1:0] out;
wire [11:0] core_status;
wire sum_valid = core_status[8];
wire ext_sum_empty = core_status[9];

integer q_tile [0:tile_count-1][0:tile_rows-1][0:pr-1];
integer k_tile [0:tile_count-1][0:col-1][0:pr-1];
integer v_tile [0:tile_count-1][0:tile_rows-1][0:pr-1];

integer stage1_raw [0:tile_count-1][0:tile_rows-1][0:col-1];
integer stage1_abs_sum [0:tile_count-1][0:tile_rows-1];
integer stage1_denom [0:tile_count-1][0:tile_rows-1];
integer stage1_norm [0:tile_count-1][0:tile_rows-1][0:col-1];
integer stage2_k [0:tile_count-1][0:col-1][0:pr-1];
integer stage2_z [0:tile_count-1][0:tile_rows-1][0:col-1];

core #(
  .col(col),
  .bw(bw),
  .bw_psum(bw_psum),
  .sum_out_bw(sum_out_bw),
  .pr(pr),
  .sum_in_bw(sum_in_bw)
) dut (
  .clk(clk),
  .sum_out(sum_out),
  .sum_in(sum_in),
  .ext_sum_wr(ext_sum_wr),
  .managed_load_mode(1'b0),
  .q_load_done(1'b0),
  .k_load_done(1'b0),
  .mem_in(mem_in),
  .out(out),
  .inst(inst),
  .reset(reset),
  .core_status(core_status)
);

always #5 clk = ~clk;

task tick;
begin
  @(posedge clk);
  #1;
  cyc = cyc + 1;
end
endtask

task clear_ctrl;
begin
  inst = 23'd0;
  inst[20] = 1'b1;
  mem_in = {pr*bw{1'b0}};
  sum_in = {sum_in_bw{1'b0}};
  ext_sum_wr = 1'b0;
end
endtask

task apply_reset;
begin
  clear_ctrl();
  reset = 1'b1;
  repeat (4) tick();
  reset = 1'b0;
  repeat (2) tick();
end
endtask

function integer abs_i;
input integer x;
begin
  if (x < 0)
    abs_i = -x;
  else
    abs_i = x;
end
endfunction

function integer signed_seed;
input integer seed;
input integer limit;
integer span;
begin
  span = 2 * limit;
  signed_seed = (seed % span) - limit;
  if (signed_seed >= 0)
    signed_seed = signed_seed + 1;
end
endfunction

function integer wrap_s8;
input integer x;
integer tmp;
begin
  tmp = x % 256;
  if (tmp < 0)
    tmp = tmp + 256;
  if (tmp >= 128)
    wrap_s8 = tmp - 256;
  else
    wrap_s8 = tmp;
end
endfunction

function integer tile_bank;
input integer tile_idx;
begin
  if (tile_idx == 0)
    tile_bank = 1;
  else
    tile_bank = 0;
end
endfunction

function integer current_out_col;
input integer col_idx;
begin
  case (col_idx)
    0: current_out_col = $signed(out[bw_psum*8-1:bw_psum*7]);
    1: current_out_col = $signed(out[bw_psum*7-1:bw_psum*6]);
    2: current_out_col = $signed(out[bw_psum*6-1:bw_psum*5]);
    3: current_out_col = $signed(out[bw_psum*5-1:bw_psum*4]);
    4: current_out_col = $signed(out[bw_psum*4-1:bw_psum*3]);
    5: current_out_col = $signed(out[bw_psum*3-1:bw_psum*2]);
    6: current_out_col = $signed(out[bw_psum*2-1:bw_psum*1]);
    default: current_out_col = $signed(out[bw_psum*1-1:bw_psum*0]);
  endcase
end
endfunction

task init_vectors;
begin
  for (t = 0; t < tile_count; t = t + 1) begin
    for (i = 0; i < tile_rows; i = i + 1) begin
      for (j = 0; j < pr; j = j + 1) begin
        q_tile[t][i][j] = signed_seed((t+1)*17 + i*11 + j*5, 12);
        v_tile[t][i][j] = signed_seed((t+1)*29 + i*7 + j*9, 11);
      end
    end
    for (i = 0; i < col; i = i + 1) begin
      for (j = 0; j < pr; j = j + 1)
        k_tile[t][i][j] = signed_seed((t+1)*23 + i*13 + j*3, 10);
    end
  end
end
endtask

task build_expected_model;
begin
  for (t = 0; t < tile_count; t = t + 1) begin
    for (i = 0; i < tile_rows; i = i + 1) begin
      stage1_abs_sum[t][i] = 0;
      for (j = 0; j < col; j = j + 1) begin
        stage1_raw[t][i][j] = 0;
        for (k = 0; k < pr; k = k + 1)
          stage1_raw[t][i][j] = stage1_raw[t][i][j] + q_tile[t][i][k] * k_tile[t][j][k];
        stage1_abs_sum[t][i] = stage1_abs_sum[t][i] + abs_i(stage1_raw[t][i][j]);
      end

      stage1_denom[t][i] = stage1_abs_sum[t][i] >>> 7;
      if (stage1_denom[t][i] == 0) begin
        $display("FAIL tile%0d row%0d denominator collapsed to zero", t, i);
        errors = errors + 1;
        stage1_denom[t][i] = 1;
      end

      for (j = 0; j < col; j = j + 1) begin
        stage1_norm[t][i][j] = stage1_raw[t][i][j] / stage1_denom[t][i];
        stage2_k[t][i][j] = wrap_s8(stage1_norm[t][i][j]);
      end
    end

    for (i = 0; i < tile_rows; i = i + 1) begin
      for (j = 0; j < col; j = j + 1) begin
        stage2_z[t][i][j] = 0;
        for (k = 0; k < pr; k = k + 1)
          stage2_z[t][i][j] = stage2_z[t][i][j] + v_tile[t][i][k] * stage2_k[t][j][k];
      end
    end
  end
end
endtask

task drive_q_row;
input integer tile_idx;
input integer row_idx;
begin
  for (j = 0; j < pr; j = j + 1)
    mem_in[(j*bw) +: bw] = q_tile[tile_idx][row_idx][j];
end
endtask

task drive_v_row;
input integer tile_idx;
input integer row_idx;
begin
  for (j = 0; j < pr; j = j + 1)
    mem_in[(j*bw) +: bw] = v_tile[tile_idx][row_idx][j];
end
endtask

task drive_k_row;
input integer tile_idx;
input integer row_idx;
begin
  for (j = 0; j < pr; j = j + 1)
    mem_in[(j*bw) +: bw] = k_tile[tile_idx][row_idx][j];
end
endtask

task drive_stage2_k_row;
input integer tile_idx;
input integer row_idx;
begin
  for (j = 0; j < pr; j = j + 1)
    mem_in[(j*bw) +: bw] = stage2_k[tile_idx][row_idx][j];
end
endtask

task load_q_tile;
input integer tile_idx;
begin
  for (i = 0; i < tile_rows; i = i + 1) begin
    clear_ctrl();
    inst[4] = 1'b1;
    inst[15:12] = i[3:0];
    drive_q_row(tile_idx, i);
    tick();
  end
  clear_ctrl();
  tick();
end
endtask

task load_v_tile;
input integer tile_idx;
begin
  for (i = 0; i < tile_rows; i = i + 1) begin
    clear_ctrl();
    inst[4] = 1'b1;
    inst[15:12] = i[3:0];
    drive_v_row(tile_idx, i);
    tick();
  end
  clear_ctrl();
  tick();
end
endtask

task load_k_tile;
input integer tile_idx;
begin
  for (i = 0; i < col; i = i + 1) begin
    clear_ctrl();
    inst[2] = 1'b1;
    inst[15:12] = i[3:0];
    drive_k_row(tile_idx, i);
    tick();
  end
  clear_ctrl();
  tick();
end
endtask

task load_stage2_k_tile;
input integer tile_idx;
begin
  for (i = 0; i < col; i = i + 1) begin
    clear_ctrl();
    inst[2] = 1'b1;
    inst[15:12] = i[3:0];
    drive_stage2_k_row(tile_idx, i);
    tick();
  end
  clear_ctrl();
  tick();
end
endtask

task warm_k_rows;
begin
  for (i = 0; i < col+2; i = i + 1) begin
    clear_ctrl();
    inst[6] = 1'b1;
    if ((i >= 1) && (i <= col)) begin
      inst[3] = 1'b1;
      inst[15:12] = i - 1;
    end
    tick();
  end
  clear_ctrl();
  repeat (mac_settle_cycles) tick();
end
endtask

task launch_execute_rows;
begin
  for (i = 0; i < tile_rows; i = i + 1) begin
    clear_ctrl();
    inst[7] = 1'b1;
    inst[5] = 1'b1;
    inst[15:12] = i[3:0];
    tick();
  end

  clear_ctrl();
  repeat (mac_settle_cycles) tick();

  for (i = 0; i < tile_rows; i = i + 1) begin
    clear_ctrl();
    inst[7] = 1'b1;
    tick();
  end

  clear_ctrl();
  repeat (2) tick();
end
endtask

task write_ofifo_rows_to_pmem;
begin
  for (i = 0; i < tile_rows; i = i + 1) begin
    wait_ctr = 0;
    while ((dut.fifo_valid !== 1'b1) && (wait_ctr < ofifo_wait_max)) begin
      clear_ctrl();
      tick();
      wait_ctr = wait_ctr + 1;
    end

    if (dut.fifo_valid !== 1'b1) begin
      $display("FAIL pmem write row%0d: OFIFO never became valid", i);
      errors = errors + 1;
    end

    clear_ctrl();
    inst[0] = 1'b1;
    inst[11:8] = i[3:0];
    tick();

    clear_ctrl();
    tick();
  end

  wait_ctr = 0;
  while ((dut.pmem_ready_valid !== 1'b1) && (wait_ctr < ofifo_wait_max)) begin
    clear_ctrl();
    tick();
    wait_ctr = wait_ctr + 1;
  end

  if (dut.pmem_ready_valid !== 1'b1) begin
    $display("FAIL pmem write completion: ready bank never became valid");
    errors = errors + 1;
  end

  clear_ctrl();
  repeat (pmem_write_settle_cycles) tick();
end
endtask

task check_bank_state;
input [255:0] tag;
input integer exp_q_bank;
input integer exp_k_bank;
input integer exp_q_pending;
input integer exp_k_pending;
input integer exp_inflight;
input integer exp_ready_valid;
input integer exp_ready_bank;
begin
  if (enable_bank_checks) begin
    if (dut.q_compute_bank_sel !== (exp_q_bank != 0)) begin
      $display("FAIL %0s q_compute_bank got=%0d exp=%0d", tag, dut.q_compute_bank_sel, exp_q_bank);
      errors = errors + 1;
    end
    if (dut.k_compute_bank_sel !== (exp_k_bank != 0)) begin
      $display("FAIL %0s k_compute_bank got=%0d exp=%0d", tag, dut.k_compute_bank_sel, exp_k_bank);
      errors = errors + 1;
    end
    if (dut.q_bank_switch_pending !== (exp_q_pending != 0)) begin
      $display("FAIL %0s q_bank_switch_pending got=%0d exp=%0d", tag, dut.q_bank_switch_pending, exp_q_pending);
      errors = errors + 1;
    end
    if (dut.k_bank_switch_pending !== (exp_k_pending != 0)) begin
      $display("FAIL %0s k_bank_switch_pending got=%0d exp=%0d", tag, dut.k_bank_switch_pending, exp_k_pending);
      errors = errors + 1;
    end
    if (dut.tile_inflight !== (exp_inflight != 0)) begin
      $display("FAIL %0s tile_inflight got=%0d exp=%0d", tag, dut.tile_inflight, exp_inflight);
      errors = errors + 1;
    end
    if (dut.pmem_ready_valid !== (exp_ready_valid != 0)) begin
      $display("FAIL %0s pmem_ready_valid got=%0d exp=%0d", tag, dut.pmem_ready_valid, exp_ready_valid);
      errors = errors + 1;
    end
    if (dut.pmem_ready_bank_sel !== (exp_ready_bank != 0)) begin
      $display("FAIL %0s pmem_ready_bank_sel got=%0d exp=%0d", tag, dut.pmem_ready_bank_sel, exp_ready_bank);
      errors = errors + 1;
    end
  end
end
endtask

task run_acc_on_ready_tile;
input integer tile_idx;
begin
  for (i = 0; i < tile_rows; i = i + 1) begin
    row_abs_sum = stage1_abs_sum[tile_idx][i];

    clear_ctrl();
    inst[1] = 1'b1;
    inst[11:8] = i[3:0];
    tick();

    clear_ctrl();
    inst[1] = 1'b1;
    inst[18] = 1'b1;
    inst[11:8] = i[3:0];
    tick();

    wait_ctr = 0;
    while ((dut.core_status[8] === 1'b1) && (wait_ctr < ofifo_wait_max)) begin
      clear_ctrl();
      tick();
      wait_ctr = wait_ctr + 1;
    end

    wait_ctr = 0;
    while ((dut.core_status[8] !== 1'b1) && (wait_ctr < ofifo_wait_max)) begin
      clear_ctrl();
      tick();
      wait_ctr = wait_ctr + 1;
    end

    if ((sum_valid !== 1'b1) || ($unsigned(sum_out) !== row_abs_sum)) begin
      tick();
      if (sum_valid !== 1'b1) begin
        $display("FAIL tile%0d row%0d acc sum_valid not asserted", tile_idx, i);
        errors = errors + 1;
      end
      if ($unsigned(sum_out) !== row_abs_sum) begin
        $display("FAIL tile%0d row%0d acc sum_out got=%0d exp=%0d",
                 tile_idx, i, $unsigned(sum_out), row_abs_sum);
        errors = errors + 1;
      end
    end

    clear_ctrl();
    tick();
  end

  clear_ctrl();
  tick();
end
endtask

task run_div_on_ready_tile;
input integer tile_idx;
begin
  for (i = 0; i < tile_rows; i = i + 1) begin
    clear_ctrl();
    inst[1] = 1'b1;
    inst[11:8] = i[3:0];
    tick();

    clear_ctrl();
    inst[1] = 1'b1;
    inst[17] = 1'b1;
    inst[11:8] = i[3:0];
    tick();

    wait_ctr = 0;
    while ((dut.sfp_div_done_int === 1'b1) && (wait_ctr < ofifo_wait_max)) begin
      clear_ctrl();
      tick();
      wait_ctr = wait_ctr + 1;
    end

    wait_ctr = 0;
    while ((dut.sfp_div_done_int !== 1'b1) && (wait_ctr < ofifo_wait_max)) begin
      clear_ctrl();
      tick();
      wait_ctr = wait_ctr + 1;
    end

    clear_ctrl();
    inst[0] = 1'b1;
    inst[11:8] = i[3:0];
    tick();

    clear_ctrl();
    tick();
  end

  clear_ctrl();
  repeat (pmem_write_settle_cycles) tick();
end
endtask

task fallback_ready_bank_to_kmem;
input integer tile_idx;
begin
  for (i = 0; i < col; i = i + 1) begin
    clear_ctrl();
    inst[22] = 1'b1;
    inst[21] = 1'b1;
    inst[15:12] = tile_bank(tile_idx);
    inst[11:8] = i[3:0];
    tick();

    clear_ctrl();
    inst[22] = 1'b1;
    inst[21] = 1'b1;
    inst[15:12] = tile_bank(tile_idx);
    inst[11:8] = i[3:0];
    tick();
  end

  clear_ctrl();
  tick();
end
endtask

task check_pmem_bank_against_norm;
input integer tile_idx;
input integer bank_sel;
begin
  for (i = 0; i < tile_rows; i = i + 1) begin
    clear_ctrl();
    inst[21] = 1'b1;
    inst[1] = 1'b1;
    inst[15:12] = bank_sel[3:0];
    inst[11:8] = i[3:0];
    tick();

    clear_ctrl();
    inst[21] = 1'b1;
    inst[1] = 1'b1;
    inst[15:12] = bank_sel[3:0];
    inst[11:8] = i[3:0];
    tick();

    for (j = 0; j < col; j = j + 1) begin
      got_val = current_out_col(j);
      exp_val = stage1_norm[tile_idx][i][j];
      if (got_val !== exp_val) begin
        $display("FAIL norm tile%0d bank%0d row%0d col%0d got=%0d exp=%0d",
                 tile_idx, bank_sel, i, j, got_val, exp_val);
        errors = errors + 1;
      end
    end
  end

  clear_ctrl();
  tick();
end
endtask

task check_pmem_bank_against_final_z;
input integer tile_idx;
input integer bank_sel;
begin
  for (i = 0; i < tile_rows; i = i + 1) begin
    clear_ctrl();
    inst[21] = 1'b1;
    inst[1] = 1'b1;
    inst[15:12] = bank_sel[3:0];
    inst[11:8] = i[3:0];
    tick();

    clear_ctrl();
    inst[21] = 1'b1;
    inst[1] = 1'b1;
    inst[15:12] = bank_sel[3:0];
    inst[11:8] = i[3:0];
    tick();

    for (j = 0; j < col; j = j + 1) begin
      got_val = current_out_col(j);
      exp_val = stage2_z[tile_idx][i][j];
      if (got_val !== exp_val) begin
        $display("FAIL final_z tile%0d bank%0d row%0d col%0d got=%0d exp=%0d",
                 tile_idx, bank_sel, i, j, got_val, exp_val);
        errors = errors + 1;
      end
    end
  end

  clear_ctrl();
  tick();
end
endtask

initial begin
  $dumpfile("core_single_tb.vcd");
  $dumpvars(0, core_single_tb);

  errors = 0;
  cyc = 0;
  clk = 1'b0;
  reset = 1'b0;
  mem_in = {pr*bw{1'b0}};
  inst = 23'd0;
  inst[20] = 1'b1;
  sum_in = {sum_in_bw{1'b0}};
  ext_sum_wr = 1'b0;

  init_vectors();
  build_expected_model();
  apply_reset();

  // Stage 1, tile 0: load Q/K into bank1.
  load_q_tile(0);
  load_k_tile(0);
  check_bank_state("stage1_tile0_loaded", 1, 1, 0, 0, 0, 0, 0);

  // Stage 1, tile 0 execute and normalize into PMEM bank1.
  warm_k_rows();
  launch_execute_rows();
  check_bank_state("stage1_tile0_execute_done", 1, 1, 0, 0, 1, 0, 0);

  write_ofifo_rows_to_pmem();
  check_bank_state("stage1_tile0_written", 0, 0, 0, 0, 0, 1, tile_bank(0));

  load_q_tile(1);
  load_k_tile(1);
  check_bank_state("stage1_tile1_loaded", 0, 0, 0, 0, 0, 1, tile_bank(0));

  run_acc_on_ready_tile(0);
  run_div_on_ready_tile(0);
  check_bank_state("stage1_tile0_normalized", 0, 0, 0, 0, 0, 1, tile_bank(0));

  // Stage 1, tile 1 executes from bank0.
  warm_k_rows();
  launch_execute_rows();
  check_bank_state("stage1_tile1_execute_done", 0, 0, 0, 0, 1, 0, tile_bank(0));

  write_ofifo_rows_to_pmem();
  check_bank_state("stage1_tile1_written", 0, 0, 0, 0, 0, 1, tile_bank(1));

  run_acc_on_ready_tile(1);
  run_div_on_ready_tile(1);
  check_bank_state("stage1_tile1_normalized", 0, 0, 0, 0, 0, 1, tile_bank(1));

  check_pmem_bank_against_norm(0, tile_bank(0));
  check_pmem_bank_against_norm(1, tile_bank(1));

  // Stage 2, tile 0: load V into Q bank1, copy normalized tile0 into K bank1.
  load_v_tile(0);
  load_stage2_k_tile(0);
  check_bank_state("stage2_tile0_loaded", 1, 1, 0, 0, 0, 1, tile_bank(1));

  // Stage 2, tile 0 execute and write final Z into bank1.
  warm_k_rows();
  launch_execute_rows();
  check_bank_state("stage2_tile0_execute_done", 1, 1, 0, 0, 1, 0, tile_bank(1));

  write_ofifo_rows_to_pmem();
  check_bank_state("stage2_tile0_written", 1, 1, 0, 0, 0, 1, tile_bank(0));

  load_v_tile(1);
  check_bank_state("stage2_tile1_v_loaded", 0, 1, 0, 0, 0, 1, tile_bank(0));

  load_stage2_k_tile(1);
  check_bank_state("stage2_tile1_k_loaded", 0, 0, 0, 0, 0, 1, tile_bank(0));

  warm_k_rows();
  launch_execute_rows();
  check_bank_state("stage2_tile1_execute_done", 0, 0, 0, 0, 1, 0, tile_bank(0));

  write_ofifo_rows_to_pmem();
  check_bank_state("stage2_tile1_written", 0, 0, 0, 0, 0, 1, tile_bank(1));

  check_pmem_bank_against_final_z(0, tile_bank(0));
  check_pmem_bank_against_final_z(1, tile_bank(1));

  if (errors == 0)
    $display("CORE_SINGLE_TB PASS");
  else
    $display("CORE_SINGLE_TB FAIL mismatches=%0d", errors);

  #10 $finish;
end

endmodule
