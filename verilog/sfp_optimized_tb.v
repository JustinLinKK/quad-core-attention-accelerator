`timescale 1ns/1ps

module sfp_optimized_tb;

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+6;
parameter sum_out_bw = bw_psum + 4;
parameter sum_in_bw = sum_out_bw + 2;
parameter rows = 8;

localparam integer opt_acc_latency = 4;
localparam integer opt_sum_timeout = opt_acc_latency + 4;
localparam integer opt_div_latency = 3 * ((bw_psum + 1) / 2);
localparam integer opt_div_done_latency = 36;
localparam integer opt_div_timeout = opt_div_done_latency + 8;
localparam integer opt_acc_observable_wait = 4;
localparam integer opt_div_observable_wait = 36;

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

integer r;
integer c;
integer fails;
integer row_v [0:rows-1][0:col-1];
integer abs_sum_exp [0:rows-1];
integer denom_local [0:rows-1];
integer denom_total [0:rows-1];
integer acc_cap [0:rows-1];
integer div_cap [0:rows-1][0:col-1];
integer mc_cap [0:rows-1][0:col-1];
integer expected_val;
integer total_raw;
integer last_sum_wait;
integer last_div_wait;

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
  sum_in = {sum_in_bw{1'b0}};
  sfp_in = {col*bw_psum{1'b0}};
end
endtask

task drive_row;
input integer row_idx;
begin
  sfp_in[bw_psum*1-1:bw_psum*0] = row_v[row_idx][0];
  sfp_in[bw_psum*2-1:bw_psum*1] = row_v[row_idx][1];
  sfp_in[bw_psum*3-1:bw_psum*2] = row_v[row_idx][2];
  sfp_in[bw_psum*4-1:bw_psum*3] = row_v[row_idx][3];
  sfp_in[bw_psum*5-1:bw_psum*4] = row_v[row_idx][4];
  sfp_in[bw_psum*6-1:bw_psum*5] = row_v[row_idx][5];
  sfp_in[bw_psum*7-1:bw_psum*6] = row_v[row_idx][6];
  sfp_in[bw_psum*8-1:bw_psum*7] = row_v[row_idx][7];
end
endtask

task capture_div;
input integer row_idx;
input integer mode_mc;
begin
  if (mode_mc) begin
    mc_cap[row_idx][0] = $signed(sfp_out[bw_psum*1-1:bw_psum*0]);
    mc_cap[row_idx][1] = $signed(sfp_out[bw_psum*2-1:bw_psum*1]);
    mc_cap[row_idx][2] = $signed(sfp_out[bw_psum*3-1:bw_psum*2]);
    mc_cap[row_idx][3] = $signed(sfp_out[bw_psum*4-1:bw_psum*3]);
    mc_cap[row_idx][4] = $signed(sfp_out[bw_psum*5-1:bw_psum*4]);
    mc_cap[row_idx][5] = $signed(sfp_out[bw_psum*6-1:bw_psum*5]);
    mc_cap[row_idx][6] = $signed(sfp_out[bw_psum*7-1:bw_psum*6]);
    mc_cap[row_idx][7] = $signed(sfp_out[bw_psum*8-1:bw_psum*7]);
  end else begin
    div_cap[row_idx][0] = $signed(sfp_out[bw_psum*1-1:bw_psum*0]);
    div_cap[row_idx][1] = $signed(sfp_out[bw_psum*2-1:bw_psum*1]);
    div_cap[row_idx][2] = $signed(sfp_out[bw_psum*3-1:bw_psum*2]);
    div_cap[row_idx][3] = $signed(sfp_out[bw_psum*4-1:bw_psum*3]);
    div_cap[row_idx][4] = $signed(sfp_out[bw_psum*5-1:bw_psum*4]);
    div_cap[row_idx][5] = $signed(sfp_out[bw_psum*6-1:bw_psum*5]);
    div_cap[row_idx][6] = $signed(sfp_out[bw_psum*7-1:bw_psum*6]);
    div_cap[row_idx][7] = $signed(sfp_out[bw_psum*8-1:bw_psum*7]);
  end
end
endtask

task wait_div_done;
begin
  last_div_wait = 1;
  while ((div_done !== 1'b1) && (last_div_wait < opt_div_timeout)) begin
    tick();
    last_div_wait = last_div_wait + 1;
  end
end
endtask

task wait_sum_valid;
begin
  last_sum_wait = 1;
  while ((sum_valid !== 1'b1) && (last_sum_wait < opt_sum_timeout)) begin
    tick();
    last_sum_wait = last_sum_wait + 1;
  end
end
endtask

task run_acc;
input integer row_idx;
begin
  drive_row(row_idx);
  acc = 1'b1;
  tick();
  acc = 1'b0;
  wait_sum_valid();
  acc_cap[row_idx] = $unsigned(sum_out);
end
endtask

task run_div_single;
input integer row_idx;
begin
  drive_row(row_idx);
  div = 1'b1;
  tick();
  div = 1'b0;
  wait_div_done();
  capture_div(row_idx, 0);
end
endtask

task run_div_multicore;
input integer row_idx;
begin
  total_raw = denom_total[row_idx] <<< 7;
  drive_row(row_idx);
  sum_in = total_raw[sum_in_bw-1:0];
  ext_sum_wr = 1'b1;
  tick();
  ext_sum_wr = 1'b0;

  drive_row(row_idx);
  multi_core = 1'b1;
  div = 1'b1;
  tick();
  div = 1'b0;
  wait_div_done();
  if ((div_done === 1'b1) && (ext_sum_empty !== 1'b1)) begin
    $display("FAIL(mc div row%0d ext_sum_empty alignment)", row_idx);
    fails = fails + 1;
  end
  multi_core = 1'b0;
  capture_div(row_idx, 1);
end
endtask

initial begin
  clk = 1'b0;
  reset = 1'b1;
  fails = 0;
  clear_ctrl();

  for (r = 0; r < rows; r = r + 1) begin
    abs_sum_exp[r] = 0;
    for (c = 0; c < col; c = c + 1) begin
      row_v[r][c] = 20 + (11*r) + (7*c);
      if (c[0])
        row_v[r][c] = -row_v[r][c];
      abs_sum_exp[r] = abs_sum_exp[r] + abs_i(row_v[r][c]);
    end
    denom_local[r] = abs_sum_exp[r] >>> 7;
    if (denom_local[r] == 0)
      denom_local[r] = 1;
    denom_total[r] = denom_local[r] + 9 + r;
  end

  repeat (3) tick();
  reset = 1'b0;
  repeat (2) tick();

  if (ext_sum_empty !== 1'b1) begin
    $display("FAIL(reset ext_sum_empty)");
    fails = fails + 1;
  end

  for (r = 0; r < rows; r = r + 1) begin
    clear_ctrl();
    run_acc(r);

    if (sum_valid !== 1'b1) begin
      $display("FAIL(acc row%0d sum_valid)", r);
      fails = fails + 1;
    end
    if (last_sum_wait !== opt_acc_observable_wait) begin
      $display("FAIL(acc row%0d latency got=%0d exp=%0d)", r, last_sum_wait, opt_acc_observable_wait);
      fails = fails + 1;
    end
    if (acc_cap[r] !== abs_sum_exp[r]) begin
      $display("FAIL(acc row%0d got=%0d exp=%0d)", r, acc_cap[r], abs_sum_exp[r]);
      fails = fails + 1;
    end

    clear_ctrl();
    run_div_single(r);

    if (div_done !== 1'b1) begin
      $display("FAIL(div row%0d div_done)", r);
      fails = fails + 1;
    end
    if (last_div_wait !== opt_div_observable_wait) begin
      $display("FAIL(div row%0d latency got=%0d exp=%0d)", r, last_div_wait, opt_div_observable_wait);
      fails = fails + 1;
    end
    for (c = 0; c < col; c = c + 1) begin
      expected_val = row_v[r][c] / denom_local[r];
      if (div_cap[r][c] !== expected_val) begin
        $display("FAIL(div row%0d col%0d got=%0d exp=%0d)", r, c, div_cap[r][c], expected_val);
        fails = fails + 1;
      end
    end

    clear_ctrl();
    run_div_multicore(r);

    if (div_done !== 1'b1) begin
      $display("FAIL(mc div row%0d div_done)", r);
      fails = fails + 1;
    end
    if (last_div_wait !== opt_div_observable_wait) begin
      $display("FAIL(mc div row%0d latency got=%0d exp=%0d)", r, last_div_wait, opt_div_observable_wait);
      fails = fails + 1;
    end
    if (ext_sum_empty !== 1'b1) begin
      $display("FAIL(mc div row%0d ext_sum_empty)", r);
      fails = fails + 1;
    end
    for (c = 0; c < col; c = c + 1) begin
      expected_val = row_v[r][c] / denom_total[r];
      if (mc_cap[r][c] !== expected_val) begin
        $display("FAIL(mc div row%0d col%0d got=%0d exp=%0d)", r, c, mc_cap[r][c], expected_val);
        fails = fails + 1;
      end
    end

    clear_ctrl();
    repeat (2) tick();
  end

  if (fails == 0)
    $display("sfp_optimized_tb PASS");
  else
    $display("sfp_optimized_tb FAIL count=%0d", fails);

  $finish;
end

endmodule
