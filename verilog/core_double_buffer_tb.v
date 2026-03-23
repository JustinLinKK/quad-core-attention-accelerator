`timescale 1ns/1ps

module core_double_buffer_tb;

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+6;
parameter sum_out_bw = bw_psum+4;
parameter sum_in_bw = sum_out_bw+2;
parameter pr = 8;

reg clk;
reg reset;
reg [sum_in_bw-1:0] sum_in;
reg ext_sum_wr;
reg [pr*bw-1:0] mem_in;
reg [22:0] inst;
wire [11:0] core_status;
wire [sum_out_bw-1:0] sum_out;
wire [bw_psum*col-1:0] out;

integer fails;
integer wait_ctr;

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

task tick;
begin
  #1 clk = 1'b0;
  #1 clk = 1'b1;
end
endtask

task expect_bit;
  input cond;
  input integer code;
  begin
    if (!cond) begin
      $display("FAIL check=%0d", code);
      fails = fails + 1;
    end
  end
endtask

initial begin
  clk = 1'b0;
  reset = 1'b1;
  sum_in = {sum_in_bw{1'b0}};
  ext_sum_wr = 1'b0;
  mem_in = {pr*bw{1'b0}};
  inst = 23'd0;
  fails = 0;

  // Enable core in all phases.
  inst[20] = 1'b1;

  repeat (4) tick();
  reset = 1'b0;
  repeat (2) tick();

  // Load tile1 -> write into bank1, then promote bank1 as compute bank.
  inst[4] = 1'b1; // qmem_wr
  inst[2] = 1'b1; // kmem_wr
  repeat (4) tick();
  inst[4] = 1'b0;
  inst[2] = 1'b0;
  repeat (2) tick();
  expect_bit(dut.q_compute_bank_sel == 1'b1, 1);
  expect_bit(dut.k_compute_bank_sel == 1'b1, 2);

  // Start tile1 execute.
  inst[7] = 1'b1;
  repeat (2) tick();
  expect_bit(dut.tile_inflight == 1'b1, 3);

  // While tile1 executes, load tile2. Promotion must be deferred.
  inst[4] = 1'b1;
  inst[2] = 1'b1;
  repeat (3) tick();
  inst[4] = 1'b0;
  inst[2] = 1'b0;
  repeat (2) tick();
  expect_bit(dut.q_compute_bank_sel == 1'b1, 4);
  expect_bit(dut.k_compute_bank_sel == 1'b1, 5);
  expect_bit(dut.q_bank_switch_pending == 1'b1, 6);
  expect_bit(dut.k_bank_switch_pending == 1'b1, 7);

  // End execute drive; keep tile inflight until PMEM MAC write completes.
  inst[7] = 1'b0;
  tick();
  expect_bit(dut.tile_inflight == 1'b1, 8);

  // Emulate completion of tile1 PMEM writeback directly for scheduler testing.
  dut.tile_inflight = 1'b0;
  dut.pmem_ready_bank_sel = 1'b1;
  dut.pmem_ready_valid = 1'b1;
  tick();

  expect_bit(dut.pmem_ready_bank_sel == 1'b1, 10);
  expect_bit(dut.tile_inflight == 1'b0, 11);

  // Deferred promotion now applies: tile2 becomes compute bank0.
  tick();
  expect_bit(dut.q_compute_bank_sel == 1'b0, 12);
  expect_bit(dut.k_compute_bank_sel == 1'b0, 13);

  // Single-core SFP path must consume ready bank1 (tile1) first.
  inst[18] = 1'b1; // sfp_acc
  inst[1] = 1'b1;  // pmem_rd
  tick();
  expect_bit(dut.pmem_bank_sel == 1'b1, 14);
  inst[18] = 1'b0;
  inst[1] = 1'b0;
  tick();

  if (fails == 0)
    $display("core_double_buffer_tb PASS");
  else
    $display("core_double_buffer_tb FAIL count=%0d", fails);

  $finish;
end

endmodule
