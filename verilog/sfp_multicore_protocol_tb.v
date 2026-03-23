// Created by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
`timescale 1ns/1ps

module sfp_multicore_protocol_tb;

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+6;
parameter sum_in_bw = bw_psum;
localparam integer acc_latency = 2;
localparam integer div_latency = 3 * ((bw_psum + 1) / 2);
localparam integer div_timeout = div_latency + 12;

reg clk;
reg reset;
reg acc;
reg div;
reg multi_core;
reg ext_sum_wr;
reg [sum_in_bw-1:0] sum_in;
reg [col*bw_psum-1:0] sfp_in;

wire [col*bw_psum-1:0] sfp_out_opt;
wire [bw_psum+3:0] sum_out_opt;
wire sum_valid_opt;
wire ext_sum_empty_opt;
wire div_done_opt;

integer fails;
integer i;
integer lane_val;
integer expected_lane;
integer sum_abs;
integer returned_denom;
integer wait_ctr;

sfp_optimized #(
  .col(col), .bw(bw), .bw_psum(bw_psum), .sum_in_bw(sum_in_bw)
) dut_opt (
  .clk(clk), .reset(reset), .acc(acc), .div(div), .multi_core(multi_core),
  .ext_sum_wr(ext_sum_wr), .sum_in(sum_in), .sum_out(sum_out_opt),
  .sum_valid(sum_valid_opt), .ext_sum_empty(ext_sum_empty_opt), .div_done(div_done_opt),
  .sfp_in(sfp_in), .sfp_out(sfp_out_opt)
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
  while ((div_done_opt !== 1'b1) && (wait_ctr < div_timeout)) begin
    tick();
    wait_ctr = wait_ctr + 1;
  end
end
endtask

task wait_sum_valid;
begin
  wait_ctr = 0;
  while ((sum_valid_opt !== 1'b1) && (wait_ctr < div_timeout)) begin
    tick();
    wait_ctr = wait_ctr + 1;
  end
end
endtask

function integer abs_i;
input integer x;
begin
  if (x < 0) abs_i = -x;
  else abs_i = x;
end
endfunction

task apply_vec;
  input signed [bw_psum-1:0] v0;
  input signed [bw_psum-1:0] v1;
  input signed [bw_psum-1:0] v2;
  input signed [bw_psum-1:0] v3;
  input signed [bw_psum-1:0] v4;
  input signed [bw_psum-1:0] v5;
  input signed [bw_psum-1:0] v6;
  input signed [bw_psum-1:0] v7;
  begin
    sfp_in[bw_psum*1-1:bw_psum*0] = v0;
    sfp_in[bw_psum*2-1:bw_psum*1] = v1;
    sfp_in[bw_psum*3-1:bw_psum*2] = v2;
    sfp_in[bw_psum*4-1:bw_psum*3] = v3;
    sfp_in[bw_psum*5-1:bw_psum*4] = v4;
    sfp_in[bw_psum*6-1:bw_psum*5] = v5;
    sfp_in[bw_psum*7-1:bw_psum*6] = v6;
    sfp_in[bw_psum*8-1:bw_psum*7] = v7;
  end
endtask

initial begin
  clk = 1'b0;
  reset = 1'b1;
  acc = 1'b0;
  div = 1'b0;
  multi_core = 1'b0;
  ext_sum_wr = 1'b0;
  sum_in = {sum_in_bw{1'b0}};
  sfp_in = {col*bw_psum{1'b0}};
  fails = 0;

  repeat (2) tick();
  reset = 1'b0;
  tick();

  if (ext_sum_empty_opt !== 1'b1) begin
    $display("FAIL(reset ext_sum_empty)");
    fails = fails + 1;
  end

  apply_vec(20'sd160, -20'sd192, 20'sd224, -20'sd256, 20'sd288, -20'sd320, 20'sd352, -20'sd384);
  sum_abs = abs_i(160)+abs_i(-192)+abs_i(224)+abs_i(-256)+abs_i(288)+abs_i(-320)+abs_i(352)+abs_i(-384);

  acc = 1'b1;
  tick();
  acc = 1'b0;
  wait_sum_valid();

  if (sum_valid_opt !== 1'b1) begin
    $display("FAIL(sum_valid pulse)");
    fails = fails + 1;
  end
  if ($unsigned(sum_out_opt) !== sum_abs) begin
    $display("FAIL(local sum export) opt=%0d exp=%0d", $unsigned(sum_out_opt), sum_abs);
    fails = fails + 1;
  end
  if (ext_sum_empty_opt !== 1'b1) begin
    $display("FAIL(ext_sum_empty should stay high before return write)");
    fails = fails + 1;
  end

  returned_denom = 26;
  sum_in = returned_denom << 7;
  ext_sum_wr = 1'b1;
  tick();
  ext_sum_wr = 1'b0;

  if (ext_sum_empty_opt !== 1'b0) begin
    $display("FAIL(ext_sum_empty should drop low after ext_sum_wr)");
    fails = fails + 1;
  end

  acc = 1'b1;
  tick();
  acc = 1'b0;
  tick();

  multi_core = 1'b1;
  div = 1'b1;
  tick();
  div = 1'b0;
  wait_div_done();
  multi_core = 1'b0;

  if (div_done_opt !== 1'b1) begin
    $display("FAIL(div_done timeout)");
    fails = fails + 1;
  end

  for (i = 0; i < col; i = i + 1) begin
    lane_val = $signed(sfp_in[i*bw_psum +: bw_psum]);
    expected_lane = lane_val / returned_denom;

    if ($signed(sfp_out_opt[i*bw_psum +: bw_psum]) !== expected_lane) begin
      $display("FAIL(opt lane%0d) got=%0d exp=%0d", i, $signed(sfp_out_opt[i*bw_psum +: bw_psum]), expected_lane);
      fails = fails + 1;
    end
  end

  if (ext_sum_empty_opt !== 1'b1) begin
    $display("FAIL(ext_sum_empty should return high after multicore div)");
    fails = fails + 1;
  end

  if (fails == 0)
    $display("sfp_multicore_protocol_tb PASS");
  else
    $display("sfp_multicore_protocol_tb FAIL count=%0d", fails);

  $finish;
end

endmodule
