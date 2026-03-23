`timescale 1ns/1ps

module core_multi_testbench;

parameter bw = 8;
parameter bw_psum = 2*bw+6;
parameter sum_in_bw = bw_psum + 6;
parameter pr = 8;
parameter col = 8;
parameter num_cores = 4;
parameter sum_msg_bw = bw_psum + 4;
localparam integer cc_settle_cycles = 20;

reg clk;
reg adder_clk;
reg spad_clk;
reg [num_cores-1:0] core_clk;
reg reset;
reg [pr*bw-1:0] mem_in;
reg [num_cores-1:0] mem_in_mask;
reg [16:0] inst;
wire [num_cores*23-1:0] core_inst_bus;
reg half_precision;
reg [num_cores-1:0] multi_core_inst;
reg [num_cores-1:0] core_enable_mask;
reg [num_cores-2:0] group_link;
reg [num_cores-1:0] sfp_acc_inst;
reg [num_cores-1:0] sfp_div_inst;
reg ext_sum_wr;
reg [sum_in_bw-1:0] sum_in;
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

wire [bw_psum+3:0] sum_out;
wire sum_valid;
wire ext_sum_empty;
wire [num_cores*bw_psum*col-1:0] out;
wire [num_cores*12-1:0] core_status;
wire [num_cores*10-1:0] core_ctrl_status;
wire [num_cores-1:0] group_sum_valid;
wire [num_cores*sum_in_bw-1:0] group_sum_out;
wire ctrl_busy;
wire ctrl_done;

integer fails;
integer recv_seen [0:num_cores-1];
integer recv_sum  [0:num_cores-1];
reg [num_cores*sum_msg_bw-1:0] inj_sum_bus;
reg [num_cores-1:0] inj_valid_bus;

fullchip #(
  .bw(bw),
  .bw_psum(bw_psum),
  .pr(pr),
  .col(col),
  .num_cores(num_cores)
) dut (
  .clk(clk),
  .adder_clk(adder_clk),
  .spad_clk(spad_clk),
  .core_clk(core_clk),
  .mem_in(mem_in),
  .mem_in_mask(mem_in_mask),
  .core_inst(core_inst_bus),
  .reset(reset),
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

always @(posedge clk) begin
  if (reset) begin
    recv_seen[0] <= 0;
    recv_seen[1] <= 0;
    recv_seen[2] <= 0;
    recv_seen[3] <= 0;
    recv_sum[0] <= 0;
    recv_sum[1] <= 0;
    recv_sum[2] <= 0;
    recv_sum[3] <= 0;
  end else begin
    if (dut.cc_ext_sum_wr_core[0]) begin
      recv_seen[0] <= 1;
      recv_sum[0] <= dut.cc_sum_in_core[sum_in_bw*1-1:sum_in_bw*0];
    end
    if (dut.cc_ext_sum_wr_core[1]) begin
      recv_seen[1] <= 1;
      recv_sum[1] <= dut.cc_sum_in_core[sum_in_bw*2-1:sum_in_bw*1];
    end
    if (dut.cc_ext_sum_wr_core[2]) begin
      recv_seen[2] <= 1;
      recv_sum[2] <= dut.cc_sum_in_core[sum_in_bw*3-1:sum_in_bw*2];
    end
    if (dut.cc_ext_sum_wr_core[3]) begin
      recv_seen[3] <= 1;
      recv_sum[3] <= dut.cc_sum_in_core[sum_in_bw*4-1:sum_in_bw*3];
    end
  end
end

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
    mem_in = {pr*bw{1'b0}};
    mem_in_mask = {num_cores{1'b1}};
    inst = 17'd0;
    half_precision = 1'b0;
    sfp_acc_inst = {num_cores{1'b0}};
    sfp_div_inst = {num_cores{1'b0}};
    ext_sum_wr = 1'b0;
    sum_in = {sum_in_bw{1'b0}};
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

genvar gi;
generate
  for (gi = 0; gi < num_cores; gi = gi + 1)
  begin : core_inst_pack
    assign core_inst_bus[(23*(gi+1))-1 : (23*gi)] = {
      2'b00,
      core_enable_mask[gi],
      multi_core_inst[gi],
      sfp_acc_inst[gi],
      sfp_div_inst[gi],
      inst
    };
  end
endgenerate

task clear_recv;
  integer i;
  begin
    for (i = 0; i < num_cores; i = i + 1) begin
      recv_seen[i] = 0;
      recv_sum[i] = 0;
    end
  end
endtask

task inject_core_sum;
  input integer core_idx;
  input integer sum_value;
  reg [sum_msg_bw-1:0] encoded;
  begin
    encoded = sum_value[sum_msg_bw-1:0];
    inj_sum_bus = {num_cores*sum_msg_bw{1'b0}};
    inj_valid_bus = {num_cores{1'b0}};
    case (core_idx)
      0: inj_sum_bus[sum_msg_bw*1-1:sum_msg_bw*0] = encoded;
      1: inj_sum_bus[sum_msg_bw*2-1:sum_msg_bw*1] = encoded;
      2: inj_sum_bus[sum_msg_bw*3-1:sum_msg_bw*2] = encoded;
      3: inj_sum_bus[sum_msg_bw*4-1:sum_msg_bw*3] = encoded;
    endcase
    inj_valid_bus[core_idx] = 1'b1;

    force dut.core_sum_out_local = inj_sum_bus;
    force dut.core_sum_valid_local = inj_valid_bus;

    tick(1);
    release dut.core_sum_out_local;
    release dut.core_sum_valid_local;
  end
endtask

task check_received;
  input integer c0_seen;
  input integer c0_sum;
  input integer c1_seen;
  input integer c1_sum;
  input integer c2_seen;
  input integer c2_sum;
  input integer c3_seen;
  input integer c3_sum;
  begin
    if (recv_seen[0] !== c0_seen) begin
      $display("FAIL core0 seen got=%0d exp=%0d", recv_seen[0], c0_seen);
      fails = fails + 1;
    end
    if (recv_seen[1] !== c1_seen) begin
      $display("FAIL core1 seen got=%0d exp=%0d", recv_seen[1], c1_seen);
      fails = fails + 1;
    end
    if (recv_seen[2] !== c2_seen) begin
      $display("FAIL core2 seen got=%0d exp=%0d", recv_seen[2], c2_seen);
      fails = fails + 1;
    end
    if (recv_seen[3] !== c3_seen) begin
      $display("FAIL core3 seen got=%0d exp=%0d", recv_seen[3], c3_seen);
      fails = fails + 1;
    end

    if (c0_seen && (recv_sum[0] !== c0_sum)) begin
      $display("FAIL core0 sum got=%0d exp=%0d", recv_sum[0], c0_sum);
      fails = fails + 1;
    end
    if (c1_seen && (recv_sum[1] !== c1_sum)) begin
      $display("FAIL core1 sum got=%0d exp=%0d", recv_sum[1], c1_sum);
      fails = fails + 1;
    end
    if (c2_seen && (recv_sum[2] !== c2_sum)) begin
      $display("FAIL core2 sum got=%0d exp=%0d", recv_sum[2], c2_sum);
      fails = fails + 1;
    end
    if (c3_seen && (recv_sum[3] !== c3_sum)) begin
      $display("FAIL core3 sum got=%0d exp=%0d", recv_sum[3], c3_sum);
      fails = fails + 1;
    end
  end
endtask

initial begin
  clk = 1'b0;
  adder_clk = 1'b0;
  spad_clk = 1'b0;
  core_clk = {num_cores{1'b0}};
  reset = 1'b1;
  multi_core_inst = {num_cores{1'b0}};
  core_enable_mask = {num_cores{1'b1}};
  mem_in_mask = {num_cores{1'b1}};
  group_link = {num_cores-1{1'b0}};
  fails = 0;
  clear_inputs();
  clear_recv();
  inj_sum_bus = {num_cores*sum_msg_bw{1'b0}};
  inj_valid_bus = {num_cores{1'b0}};

  // Reset
  tick(4);
  reset = 1'b0;
  tick(4);

  // Case 1: two multicore groups [0,1] and [2,3]
  // Inject denominators 3,5,7,11 -> group sums 8 and 18.
  clear_recv();
  multi_core_inst = 4'b1111;
  core_enable_mask = 4'b1111;
  group_link = 3'b101;

  inject_core_sum(0, 3);
  inject_core_sum(1, 5);
  inject_core_sum(2, 7);
  inject_core_sum(3, 11);

  tick(cc_settle_cycles);
  ext_sum_wr = 1'b1;
  tick(1);
  ext_sum_wr = 1'b0;
  tick(cc_settle_cycles);

  check_received(1, 8, 1, 8, 1, 18, 1, 18);

  // Case 2: sparse multicore enable [0] and [2] only.
  // Inject denominators 9 and 4 -> each core receives its own group sum.
  clear_recv();
  reset = 1'b1;
  tick(2);
  reset = 1'b0;
  tick(4);

  multi_core_inst = 4'b0101;
  core_enable_mask = 4'b1111;
  group_link = 3'b000;

  inject_core_sum(0, 9);
  inject_core_sum(2, 4);

  tick(cc_settle_cycles);
  ext_sum_wr = 1'b1;
  tick(1);
  ext_sum_wr = 1'b0;
  tick(cc_settle_cycles);

  check_received(1, 9, 0, 0, 1, 4, 0, 0);

  if (fails == 0)
    $display("core_multi_testbench PASS");
  else
    $display("core_multi_testbench FAIL count=%0d", fails);

  $finish;
end

always @(*) begin
  core_clk = {num_cores{clk}};
end

endmodule
