`timescale 1ns/1ps

module cross_core_adder_tb;

parameter bw = 8;
parameter bw_psum = 2*bw+6;
parameter sum_out_bw = bw_psum + 4;
parameter sum_in_bw = sum_out_bw + 2;
parameter num_cores = 4;

reg clk;
reg reset;
reg [num_cores-1:0] multi_core_inst;
reg [num_cores-1:0] core_enable_mask;
reg [num_cores-2:0] group_link;
reg ext_sum_wr_cmd;
reg [num_cores*sum_out_bw-1:0] core_sum_in;
reg [num_cores-1:0] sum_valid_in;
wire [num_cores-1:0] core_sum_pop_ready;
wire [num_cores*sum_in_bw-1:0] core_sum_to_cores;
wire [num_cores-1:0] core_ext_sum_wr;
wire [num_cores*sum_in_bw-1:0] sum_out;
wire [num_cores-1:0] sum_valid_out;

integer fails;

cross_core_adder #(
  .bw(bw),
  .bw_psum(bw_psum),
  .sum_out_bw(sum_out_bw),
  .num_cores(num_cores),
  .sum_in_bw(sum_in_bw)
) dut (
  .clk(clk),
  .reset(reset),
  .multi_core_inst(multi_core_inst),
  .core_enable_mask(core_enable_mask),
  .group_link(group_link),
  .ext_sum_wr_cmd(ext_sum_wr_cmd),
  .core_sum_in(core_sum_in),
  .sum_valid_in(sum_valid_in),
  .core_sum_pop_ready(core_sum_pop_ready),
  .core_sum_to_cores(core_sum_to_cores),
  .core_ext_sum_wr(core_ext_sum_wr),
  .sum_out(sum_out),
  .sum_valid_out(sum_valid_out)
);

always #5 clk = ~clk;

task tick;
input integer n;
integer t;
begin
  for (t = 0; t < n; t = t + 1)
    @(posedge clk);
  #1;
end
endtask

task clear_inputs;
begin
  multi_core_inst = 4'b0000;
  core_enable_mask = 4'b1111;
  group_link = 3'b000;
  ext_sum_wr_cmd = 1'b0;
  core_sum_in = {num_cores*sum_out_bw{1'b0}};
  sum_valid_in = {num_cores{1'b0}};
end
endtask

task inject_sum;
input integer core_idx;
input integer sum_value;
begin
  core_sum_in = {num_cores*sum_out_bw{1'b0}};
  sum_valid_in = {num_cores{1'b0}};
  core_sum_in[(core_idx*sum_out_bw) +: sum_out_bw] = sum_value[sum_out_bw-1:0];
  sum_valid_in[core_idx] = 1'b1;
  tick(1);
  core_sum_in = {num_cores*sum_out_bw{1'b0}};
  sum_valid_in = {num_cores{1'b0}};
end
endtask

initial begin
  clk = 1'b0;
  reset = 1'b1;
  fails = 0;
  clear_inputs();

  tick(3);
  reset = 1'b0;
  tick(2);

  multi_core_inst = 4'b1111;
  core_enable_mask = 4'b1111;
  group_link = 3'b101;

  inject_sum(0, 3);
  inject_sum(1, 5);
  inject_sum(2, 7);
  inject_sum(3, 11);

  tick(4);
  ext_sum_wr_cmd = 1'b1;
  tick(1);
  ext_sum_wr_cmd = 1'b0;
  tick(4);

  if (sum_out[sum_in_bw*1-1:sum_in_bw*0] !== 8 || !sum_valid_out[0]) begin
    $display("FAIL group01 output got=%0d valid=%0d", sum_out[sum_in_bw*1-1:sum_in_bw*0], sum_valid_out[0]);
    fails = fails + 1;
  end
  if (sum_out[sum_in_bw*3-1:sum_in_bw*2] !== 18 || !sum_valid_out[2]) begin
    $display("FAIL group23 output got=%0d valid=%0d", sum_out[sum_in_bw*3-1:sum_in_bw*2], sum_valid_out[2]);
    fails = fails + 1;
  end
  if (core_ext_sum_wr !== 4'b1111) begin
    $display("FAIL ext_sum_wr got=%b", core_ext_sum_wr);
    fails = fails + 1;
  end

  if (fails == 0)
    $display("cross_core_adder_tb PASS");
  else
    $display("cross_core_adder_tb FAIL count=%0d", fails);

  $finish;
end

endmodule
