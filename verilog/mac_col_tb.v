`timescale 1ns/1ps

module mac_col_tb;

parameter bw = 8;
parameter bw_psum = 2*bw+6;
parameter pr = 8;
parameter col_id = 0;

reg clk;
reg reset;
reg signed [pr*bw-1:0] q_in;
wire signed [pr*bw-1:0] q_out;
reg q_zero_in;
wire q_zero_out;
reg [1:0] i_inst;
wire [1:0] o_inst;
wire fifo_wr;
wire signed [bw_psum-1:0] out;

integer expected_full;
integer fails;
reg signed [pr*bw-1:0] key_model;
reg key_zero_model;

mac_col #(
  .bw(bw),
  .bw_psum(bw_psum),
  .pr(pr),
  .col_id(col_id)
) dut (
  .clk(clk),
  .reset(reset),
  .out(out),
  .q_in(q_in),
  .q_out(q_out),
  .q_zero_in(q_zero_in),
  .q_zero_out(q_zero_out),
  .i_inst(i_inst),
  .fifo_wr(fifo_wr),
  .o_inst(o_inst)
);

always #5 clk = ~clk;

task apply_vec;
  input signed [bw-1:0] v0;
  input signed [bw-1:0] v1;
  input signed [bw-1:0] v2;
  input signed [bw-1:0] v3;
  input signed [bw-1:0] v4;
  input signed [bw-1:0] v5;
  input signed [bw-1:0] v6;
  input signed [bw-1:0] v7;
  begin
    q_in[bw*1-1:bw*0] = v0;
    q_in[bw*2-1:bw*1] = v1;
    q_in[bw*3-1:bw*2] = v2;
    q_in[bw*4-1:bw*3] = v3;
    q_in[bw*5-1:bw*4] = v4;
    q_in[bw*6-1:bw*5] = v5;
    q_in[bw*7-1:bw*6] = v6;
    q_in[bw*8-1:bw*7] = v7;
  end
endtask

task tick;
  begin
    @(posedge clk);
    #1;
  end
endtask

task reset_dut;
  begin
    reset = 1'b1;
    q_in = '0;
    q_zero_in = 1'b1;
    i_inst = 2'b00;
    repeat (2) tick();
    reset = 1'b0;
    key_model = '0;
    key_zero_model = 1'b1;
  end
endtask

function integer dot8;
  input signed [pr*bw-1:0] va;
  input signed [pr*bw-1:0] vb;
  integer idx;
  reg signed [bw-1:0] a_i;
  reg signed [bw-1:0] b_i;
  begin
    dot8 = 0;
    for (idx = 0; idx < pr; idx = idx + 1) begin
      a_i = va[idx*bw +: bw];
      b_i = vb[idx*bw +: bw];
      dot8 = dot8 + (a_i * b_i);
    end
  end
endfunction

task check_out;
  input integer expected;
  input [255:0] tag;
  begin
    if ($signed(out) !== expected) begin
      $display("FAIL(%0s): got=%0d exp=%0d", tag, $signed(out), expected);
      fails = fails + 1;
    end
    else begin
      $display("PASS(%0s): %0d", tag, expected);
    end
  end
endtask

task wait_fifo_and_check;
  input integer expected;
  input [255:0] tag;
  integer t;
  reg seen_valid;
  begin
    seen_valid = 1'b0;
    begin : wait_loop
      for (t = 0; t < 20; t = t + 1) begin
        tick();
        if (fifo_wr === 1'b1) begin
          // fifo_wr is asserted one cycle before out is updated.
          tick();
          check_out(expected, tag);
          seen_valid = 1'b1;
          disable wait_loop;
        end
      end
    end
    if (!seen_valid) begin
      $display("FAIL(%0s): fifo_wr timeout waiting for valid output", tag);
      fails = fails + 1;
    end
  end
endtask

task load_key_vec;
  input signed [pr*bw-1:0] key_vec;
  input key_zero;
  begin
    q_in = key_vec;
    q_zero_in = key_zero;
    i_inst = 2'b01;
    repeat (12) tick();
    key_model = key_vec;
    key_zero_model = key_zero;
  end
endtask

task exec_query_vec;
  input signed [pr*bw-1:0] q_vec;
  input query_zero;
  input [255:0] tag;
  begin
    q_in = q_vec;
    q_zero_in = query_zero;
    i_inst = 2'b10;
    tick();
    i_inst = 2'b00;
    // Query-zero flag no longer bypasses MAC; only key-zero bypass is active.
    expected_full = key_zero_model ? 0 : dot8(q_vec, key_model);
    wait_fifo_and_check(expected_full, tag);
  end
endtask

task exec_burst_8;
  integer i;
  begin
    for (i = 0; i < 8; i = i + 1) begin
      q_in = {$random, $random};
      if (q_in == {pr*bw{1'b0}})
        q_in = 64'h0102030405060708;
      exec_query_vec(q_in, 1'b0, "full8_exec");
    end
  end
endtask

initial begin
  clk = 1'b0;
  reset = 1'b1;
  q_in = '0;
  q_zero_in = 1'b1;
  i_inst = 2'b00;
  fails = 0;
  key_model = '0;
  key_zero_model = 1'b1;

  reset_dut();

  // Scenario 1: non-zero key and non-zero query.
  apply_vec(8'sd1, -8'sd2, 8'sd3, -8'sd4, 8'sd5, -8'sd6, 8'sd7, -8'sd8);
  load_key_vec(q_in, 1'b0);
  exec_burst_8();

  // Scenario 2: query zero flag should not bypass MAC anymore.
  exec_query_vec(q_in, 1'b1, "query_zero_flag_no_bypass");

  // Scenario 3: load zero key (key zero flag high), query non-zero should still output zero.
  reset_dut();
  load_key_vec({pr*bw{1'b0}}, 1'b1);
  apply_vec(8'sd11, -8'sd3, 8'sd7, -8'sd1, 8'sd2, -8'sd4, 8'sd9, -8'sd6);
  exec_query_vec(q_in, 1'b0, "key_zero_flag");

  // Scenario 4: randomized execute checks with fixed non-zero key.
  reset_dut();
  apply_vec(-8'sd2, 8'sd1, -8'sd4, 8'sd3, -8'sd6, 8'sd5, -8'sd8, 8'sd7);
  load_key_vec(q_in, 1'b0);
  repeat (20) begin
    q_in = {$random, $random};
    if (q_in == {pr*bw{1'b0}})
      q_in = 64'h0102030405060708;
    exec_query_vec(q_in, 1'b0, "random_exec");
  end

  if (fails == 0)
    $display("mac_col_tb completed: PASS");
  else
    $display("mac_col_tb completed: FAIL count=%0d", fails);
  $finish;
end

endmodule
