`timescale 1ns/1ps

module sfp_b2_tb;

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 22;
parameter sum_out_bw = bw_psum + 4;
parameter sum_in_bw = sum_out_bw + 2;
parameter b2_threshold = 600;

localparam integer div_data_latency = 3 * ((bw_psum + 1) / 2);
localparam integer div_done_latency = div_data_latency + 1;
localparam integer div_timeout = div_done_latency + 8;

reg clk;
reg reset;
reg acc;
reg div;
reg multi_core;
reg ext_sum_wr;
reg [sum_in_bw-1:0] sum_in;
reg [col*bw_psum-1:0] sfp_in;

wire [col*bw_psum-1:0] sfp_out;
wire [sum_out_bw-1:0] sum_out;
wire sum_valid;
wire ext_sum_empty;
wire div_done;
reg threshold_sum_wr;
reg [sum_out_bw-1:0] threshold_sum_in;

integer fails;
integer c;
integer exp_abs_sum;
integer exp_denom;
integer got_lane;
integer exp_lane;
integer row_small [0:col-1];
integer row_large [0:col-1];
integer wait_ctr;

sfp_optimized #(
  .col(col),
  .bw(bw),
  .bw_psum(bw_psum),
  .sum_out_bw(sum_out_bw),
  .sum_in_bw(sum_in_bw)
) dut (
  .clk(clk),
  .reset(reset),
  .acc(acc),
  .div(div),
  .multi_core(multi_core),
  .ext_sum_wr(ext_sum_wr),
  .threshold_sum_wr(threshold_sum_wr),
  .threshold_sum_in(threshold_sum_in),
  .sum_in(sum_in),
  .sum_out(sum_out),
  .sum_valid(sum_valid),
  .ext_sum_empty(ext_sum_empty),
  .div_done(div_done),
  .sfp_in(sfp_in),
  .sfp_out(sfp_out)
);

always #5 clk = ~clk;

task tick;
begin
  @(posedge clk);
  #1;
end
endtask

task wait_div_done;
begin
  wait_ctr = 0;
  while ((div_done !== 1'b1) && (wait_ctr < div_timeout)) begin
    tick();
    wait_ctr = wait_ctr + 1;
  end
end
endtask

task wait_sum_valid;
begin
  wait_ctr = 0;
  while ((sum_valid !== 1'b1) && (wait_ctr < div_timeout)) begin
    tick();
    wait_ctr = wait_ctr + 1;
  end
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

task clear_ctrl;
begin
  acc = 1'b0;
  div = 1'b0;
  multi_core = 1'b0;
  ext_sum_wr = 1'b0;
  threshold_sum_wr = 1'b0;
  threshold_sum_in = b2_threshold;
  sum_in = {sum_in_bw{1'b0}};
  sfp_in = {col*bw_psum{1'b0}};
end
endtask

task program_threshold;
input integer threshold;
begin
  clear_ctrl();
  threshold_sum_in = threshold[sum_out_bw-1:0];
  threshold_sum_wr = 1'b1;
  tick();
  threshold_sum_wr = 1'b0;
  tick();
end
endtask

task drive_small_row;
begin
  for (c = 0; c < col; c = c + 1)
    sfp_in[(bw_psum*c) +: bw_psum] = row_small[c];
end
endtask

task drive_large_row;
begin
  for (c = 0; c < col; c = c + 1)
    sfp_in[(bw_psum*c) +: bw_psum] = row_large[c];
end
endtask

task expect_acc_sum;
input integer expected_sum;
begin
  if ((sum_valid !== 1'b1) || ($unsigned(sum_out) !== expected_sum)) begin
    $display("FAIL acc expected valid=1 sum=%0d got valid=%0d sum=%0d",
             expected_sum, sum_valid, $unsigned(sum_out));
    fails = fails + 1;
  end
end
endtask

task expect_zero_row;
input [255:0] tag;
begin
  for (c = 0; c < col; c = c + 1) begin
    got_lane = $signed(sfp_out[(bw_psum*c) +: bw_psum]);
    if (got_lane !== 0) begin
      $display("FAIL %0s col%0d expected zero got=%0d", tag, c, got_lane);
      fails = fails + 1;
    end
  end
end
endtask

task expect_div_row;
input [255:0] tag;
input integer denom;
input integer use_large_row;
begin
  for (c = 0; c < col; c = c + 1) begin
    got_lane = $signed(sfp_out[(bw_psum*c) +: bw_psum]);
    if (use_large_row != 0)
      exp_lane = row_large[c] / denom;
    else
      exp_lane = row_small[c] / denom;
    if (got_lane !== exp_lane) begin
      $display("FAIL %0s col%0d got=%0d exp=%0d", tag, c, got_lane, exp_lane);
      fails = fails + 1;
    end
  end
end
endtask

initial begin
  clk = 1'b0;
  fails = 0;
  clear_ctrl();
  reset = 1'b1;

  for (c = 0; c < col; c = c + 1) begin
    row_small[c] = 20 + (7*c);
    if (c[0])
      row_small[c] = -row_small[c];
    row_large[c] = 97 + (11*c);
    if (c[0])
      row_large[c] = -row_large[c];
  end

  repeat (3) tick();
  reset = 1'b0;
  repeat (2) tick();
  program_threshold(b2_threshold);

  exp_abs_sum = 0;
  for (c = 0; c < col; c = c + 1)
    exp_abs_sum = exp_abs_sum + abs_i(row_small[c]);
  if (exp_abs_sum >= b2_threshold) begin
    $display("FAIL setup: row_small abs_sum=%0d should be below threshold=%0d", exp_abs_sum, b2_threshold);
    fails = fails + 1;
  end

  drive_small_row();
  acc = 1'b1;
  tick();
  acc = 1'b0;
  wait_sum_valid();
  expect_acc_sum(exp_abs_sum);

  drive_small_row();
  div = 1'b1;
  tick();
  div = 1'b0;
  wait_div_done();
  if (div_done !== 1'b1) begin
    $display("FAIL single_core_skip div_done timeout");
    fails = fails + 1;
  end
  expect_zero_row("single_core_skip");
  clear_ctrl();
  repeat (2) tick();

  exp_abs_sum = 0;
  for (c = 0; c < col; c = c + 1)
    exp_abs_sum = exp_abs_sum + abs_i(row_large[c]);
  if (exp_abs_sum < b2_threshold) begin
    $display("FAIL setup: row_large abs_sum=%0d should be above threshold=%0d", exp_abs_sum, b2_threshold);
    fails = fails + 1;
  end
  exp_denom = exp_abs_sum >>> 7;
  if (exp_denom == 0)
    exp_denom = 1;

  drive_large_row();
  acc = 1'b1;
  tick();
  acc = 1'b0;
  wait_sum_valid();
  expect_acc_sum(exp_abs_sum);

  drive_large_row();
  div = 1'b1;
  tick();
  div = 1'b0;
  wait_div_done();
  if (div_done !== 1'b1) begin
    $display("FAIL single_core_keep div_done timeout");
    fails = fails + 1;
  end
  expect_div_row("single_core_keep", exp_denom, 1);
  clear_ctrl();
  repeat (2) tick();

  drive_large_row();
  sum_in = 26'd512;
  ext_sum_wr = 1'b1;
  tick();
  ext_sum_wr = 1'b0;
  multi_core = 1'b1;
  drive_large_row();
  div = 1'b1;
  tick();
  div = 1'b0;
  wait_div_done();
  multi_core = 1'b0;
  if (div_done !== 1'b1) begin
    $display("FAIL multi_core_skip div_done timeout");
    fails = fails + 1;
  end
  expect_zero_row("multi_core_skip");
  if (ext_sum_empty !== 1'b1) begin
    $display("FAIL multi_core_skip ext_sum_empty expected 1 got %0d", ext_sum_empty);
    fails = fails + 1;
  end
  clear_ctrl();
  repeat (2) tick();

  drive_large_row();
  sum_in = 26'd1024;
  ext_sum_wr = 1'b1;
  tick();
  ext_sum_wr = 1'b0;
  multi_core = 1'b1;
  drive_large_row();
  div = 1'b1;
  tick();
  div = 1'b0;
  wait_div_done();
  multi_core = 1'b0;
  if (div_done !== 1'b1) begin
    $display("FAIL multi_core_keep div_done timeout");
    fails = fails + 1;
  end
  expect_div_row("multi_core_keep", 8, 1);
  if (ext_sum_empty !== 1'b1) begin
    $display("FAIL multi_core_keep ext_sum_empty expected 1 got %0d", ext_sum_empty);
    fails = fails + 1;
  end

  program_threshold(0);
  if (dut.threshold_sum_q !== {sum_out_bw{1'b0}}) begin
    $display("FAIL threshold clear got=%0d exp=0", dut.threshold_sum_q);
    fails = fails + 1;
  end

  if (fails == 0)
    $display("sfp_b2_tb PASS");
  else
    $display("sfp_b2_tb FAIL count=%0d", fails);

  $finish;
end

endmodule
