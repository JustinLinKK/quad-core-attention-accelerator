`timescale 1ns/1ps

module core_b2_cfg_tb;

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 22;
parameter sum_out_bw = bw_psum + 4;
parameter pr = 8;
parameter sum_in_bw = sum_out_bw + 2;
parameter div_latency = (3 * ((bw_psum + 1) / 2)) + 1;

reg clk;
reg reset;
reg [pr*bw-1:0] mem_in;
reg [22:0] inst;
reg [sum_in_bw-1:0] sum_in;
reg ext_sum_wr;
reg [bw_psum*col-1:0] forced_pmem_row;

wire [sum_out_bw-1:0] sum_out;
wire [bw_psum*col-1:0] out;
wire [11:0] core_status;

integer fails;
integer c;
integer exp_abs_sum;
integer row_data [0:col-1];

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
  inst = 23'd0;
  inst[20] = 1'b1;
  mem_in = {pr*bw{1'b0}};
  sum_in = {sum_in_bw{1'b0}};
  ext_sum_wr = 1'b0;
end
endtask

task force_pmem_row0;
begin
  for (c = 0; c < col; c = c + 1)
    forced_pmem_row[(bw_psum*c) +: bw_psum] = row_data[c];
  force dut.pmem_out_0 = forced_pmem_row;
  force dut.pmem_out_1 = {bw_psum*col{1'b0}};
end
endtask

task program_b2_threshold;
input integer bank_sel;
input integer threshold;
begin
  clear_ctrl();
  mem_in[sum_out_bw-1:0] = threshold[sum_out_bw-1:0];
  inst[16] = 1'b1;
  inst[12] = bank_sel[0];
  tick();
  clear_ctrl();
  tick();
end
endtask

task run_acc_row0;
begin
  clear_ctrl();
  inst[1] = 1'b1;
  inst[11:8] = 4'd0;
  tick();

  clear_ctrl();
  inst[1] = 1'b1;
  inst[18] = 1'b1;
  inst[11:8] = 4'd0;
  tick();

  while (core_status[8] === 1'b1)
    tick();
  while (core_status[8] !== 1'b1)
    tick();
end
endtask

initial begin
  clk = 1'b0;
  fails = 0;
  reset = 1'b1;
  clear_ctrl();
  ext_sum_wr = 1'b0;
  forced_pmem_row = {bw_psum*col{1'b0}};

  for (c = 0; c < col; c = c + 1) begin
    row_data[c] = 120 + (13*c);
    if (c[0])
      row_data[c] = -row_data[c];
  end

  exp_abs_sum = 0;
  for (c = 0; c < col; c = c + 1)
    exp_abs_sum = exp_abs_sum + abs_i(row_data[c]);

  repeat (4) tick();
  reset = 1'b0;
  repeat (2) tick();

  force_pmem_row0();

  program_b2_threshold(0, exp_abs_sum + 5);
  if (dut.threshold_bank0_q !== (exp_abs_sum + 5)) begin
    $display("FAIL threshold bank0 high got=%0d exp=%0d", dut.threshold_bank0_q, (exp_abs_sum + 5));
    fails = fails + 1;
  end
  if (dut.sfp_row_inst.threshold_sum_q !== (exp_abs_sum + 5)) begin
    $display("FAIL active threshold bank0 got=%0d exp=%0d", dut.sfp_row_inst.threshold_sum_q, (exp_abs_sum + 5));
    fails = fails + 1;
  end
  run_acc_row0();
  if (($unsigned(sum_out) !== exp_abs_sum) || (core_status[8] !== 1'b1)) begin
    $display("FAIL acc high-threshold got sum=%0d valid=%0d exp_sum=%0d", $unsigned(sum_out), core_status[8], exp_abs_sum);
    fails = fails + 1;
  end

  force dut.pmem_ready_bank_sel = 1'b1;
  program_b2_threshold(1, exp_abs_sum - 5);
  if (dut.threshold_bank1_q !== (exp_abs_sum - 5)) begin
    $display("FAIL threshold bank1 low got=%0d exp=%0d", dut.threshold_bank1_q, (exp_abs_sum - 5));
    fails = fails + 1;
  end
  if (dut.sfp_row_inst.threshold_sum_q !== (exp_abs_sum - 5)) begin
    $display("FAIL active threshold bank1 got=%0d exp=%0d", dut.sfp_row_inst.threshold_sum_q, (exp_abs_sum - 5));
    fails = fails + 1;
  end
  release dut.pmem_ready_bank_sel;

  force dut.pmem_ready_bank_sel = 1'b0;
  program_b2_threshold(0, 0);
  if (dut.threshold_bank0_q !== {sum_out_bw{1'b0}}) begin
    $display("FAIL threshold bank0 zero clear got=%0d exp=0", dut.threshold_bank0_q);
    fails = fails + 1;
  end
  if (dut.sfp_row_inst.threshold_sum_q !== {sum_out_bw{1'b0}}) begin
    $display("FAIL active threshold zero clear got=%0d exp=0", dut.sfp_row_inst.threshold_sum_q);
    fails = fails + 1;
  end
  release dut.pmem_ready_bank_sel;

  if (fails == 0)
    $display("core_b2_cfg_tb PASS");
  else
    $display("core_b2_cfg_tb FAIL count=%0d", fails);

  $finish;
end

endmodule
