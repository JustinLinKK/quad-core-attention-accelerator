`timescale 1ns/1ps

module mac_array_tb;

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+6;
parameter pr = 8;

reg clk;
reg reset;
reg [pr*bw-1:0] in;
reg [1:0] inst;

wire [bw_psum*col-1:0] out;
wire [col-1:0] fifo_wr;
reg  [col-1:0] fifo_wr_d1;
wire signed [bw_psum-1:0] out_col [0:col-1];

integer fails;
integer exp_col;
integer idx;
reg signed [pr*bw-1:0] key_model;
reg key_zero_model;
reg signed [pr*bw-1:0] query_hist [0:col-1];
reg signed [pr*bw-1:0] query_hist_d1 [0:col-1];
reg signed [pr*bw-1:0] query_hist_d2 [0:col-1];
reg signed [pr*bw-1:0] query_hist_d3 [0:col-1];
reg signed [pr*bw-1:0] query_hist_d4 [0:col-1];
reg signed [pr*bw-1:0] query_hist_d5 [0:col-1];
reg signed [pr*bw-1:0] query_hist_d6 [0:col-1];

mac_array #(
  .col(col),
  .bw(bw),
  .bw_psum(bw_psum),
  .pr(pr)
) dut (
  .clk(clk),
  .reset(reset),
  .in(in),
  .out(out),
  .fifo_wr(fifo_wr),
  .inst(inst)
);

genvar g;
generate
  for (g = 0; g < col; g = g + 1) begin : out_unpack
    assign out_col[g] = out[bw_psum*(g+1)-1:bw_psum*g];
  end
endgenerate

always #5 clk = ~clk;

task apply_vec;
  input [7:0] v0;
  input [7:0] v1;
  input [7:0] v2;
  input [7:0] v3;
  input [7:0] v4;
  input [7:0] v5;
  input [7:0] v6;
  input [7:0] v7;
  begin
    in[bw*1-1:bw*0] = v0;
    in[bw*2-1:bw*1] = v1;
    in[bw*3-1:bw*2] = v2;
    in[bw*4-1:bw*3] = v3;
    in[bw*5-1:bw*4] = v4;
    in[bw*6-1:bw*5] = v5;
    in[bw*7-1:bw*6] = v6;
    in[bw*8-1:bw*7] = v7;
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
    inst = 2'b00;
    in = '0;
    repeat (2) tick();
    reset = 1'b0;
    key_model = '0;
    key_zero_model = 1'b1;
    fifo_wr_d1 = {col{1'b0}};
    for (idx = 0; idx < col; idx = idx + 1) begin
      query_hist[idx] = '0;
      query_hist_d1[idx] = '0;
      query_hist_d2[idx] = '0;
      query_hist_d3[idx] = '0;
      query_hist_d4[idx] = '0;
      query_hist_d5[idx] = '0;
      query_hist_d6[idx] = '0;
    end
  end
endtask

function integer dot8;
  input signed [pr*bw-1:0] va;
  input signed [pr*bw-1:0] vb;
  integer i;
  reg signed [bw-1:0] a_i;
  reg signed [bw-1:0] b_i;
  begin
    dot8 = 0;
    for (i = 0; i < pr; i = i + 1) begin
      a_i = va[i*bw +: bw];
      b_i = vb[i*bw +: bw];
      dot8 = dot8 + (a_i * b_i);
    end
  end
endfunction

task check_all_cols;
  input [255:0] tag;
  integer i;
  integer local_fail;
  begin
    local_fail = 0;
    for (i = 0; i < col; i = i + 1) begin
      if (fifo_wr_d1[i]) begin
        exp_col = key_zero_model ? 0 : dot8(query_hist_d6[i], key_model);
        if ($signed(out_col[i]) !== exp_col) begin
          $display("FAIL(%0s): col%0d got=%0d exp=%0d", tag, i, $signed(out_col[i]), exp_col);
          fails = fails + 1;
          local_fail = 1;
        end
      end
    end
    if (!local_fail)
      $display("PASS(%0s): all %0d columns", tag, col);
  end
endtask

task load_key_vec;
  input signed [pr*bw-1:0] key_vec;
  input key_zero;
  begin
    in = key_vec;
    inst = 2'b01;
    repeat (12) tick();
    key_model = key_vec;
    key_zero_model = key_zero;
    fifo_wr_d1 = {col{1'b0}};
    // Key loading should not seed execute-history pipeline.
    for (idx = 0; idx < col; idx = idx + 1) begin
      query_hist[idx] = '0;
      query_hist_d1[idx] = '0;
      query_hist_d2[idx] = '0;
      query_hist_d3[idx] = '0;
      query_hist_d4[idx] = '0;
      query_hist_d5[idx] = '0;
      query_hist_d6[idx] = '0;
    end
  end
endtask

task exec_vec;
  input signed [pr*bw-1:0] q_vec;
  input [255:0] tag;
  integer i;
  begin
    in = q_vec;
    inst = 2'b10;
    tick();

    // Compare first, then advance the model pipeline state.
    check_all_cols(tag);
    fifo_wr_d1 = fifo_wr;

    for (i = col-1; i > 0; i = i - 1) begin
      query_hist_d6[i] = query_hist_d6[i-1];
    end
    query_hist_d6[0] = query_hist_d5[0];

    for (i = col-1; i > 0; i = i - 1) begin
      query_hist_d5[i] = query_hist_d5[i-1];
    end
    query_hist_d5[0] = query_hist_d4[0];

    for (i = col-1; i > 0; i = i - 1) begin
      query_hist_d4[i] = query_hist_d4[i-1];
    end
    query_hist_d4[0] = query_hist_d3[0];

    for (i = col-1; i > 0; i = i - 1) begin
      query_hist_d3[i] = query_hist_d3[i-1];
    end
    query_hist_d3[0] = query_hist_d2[0];

    for (i = col-1; i > 0; i = i - 1) begin
      query_hist_d2[i] = query_hist_d2[i-1];
    end
    query_hist_d2[0] = query_hist_d1[0];

    for (i = col-1; i > 0; i = i - 1) begin
      query_hist_d1[i] = query_hist_d1[i-1];
    end
    query_hist_d1[0] = query_hist[0];

    for (i = col-1; i > 0; i = i - 1) begin
      query_hist[i] = query_hist[i-1];
    end
    query_hist[0] = q_vec;
  end
endtask

task exec_burst_8;
  integer i;
  begin
    for (i = 0; i < 8; i = i + 1) begin
      in = {$random, $random};
      if (in == {pr*bw{1'b0}})
        in = 64'h1122334455667788;
      exec_vec(in, "full8_exec");
    end
  end
endtask

initial begin
  clk = 1'b0;
  reset = 1'b1;
  inst = 2'b00;
  in = '0;
  fails = 0;
  key_model = '0;
  key_zero_model = 1'b1;
  fifo_wr_d1 = {col{1'b0}};
  for (idx = 0; idx < col; idx = idx + 1) begin
    query_hist[idx] = '0;
    query_hist_d1[idx] = '0;
    query_hist_d2[idx] = '0;
    query_hist_d3[idx] = '0;
    query_hist_d4[idx] = '0;
    query_hist_d5[idx] = '0;
    query_hist_d6[idx] = '0;
  end

  reset_dut();

  // Scenario 1: non-zero key and full 8-vector execute burst.
  apply_vec(8'sd1, -8'sd2, 8'sd3, -8'sd4, 8'sd5, -8'sd6, 8'sd7, -8'sd8);
  load_key_vec(in, 1'b0);
  exec_burst_8();

  // Scenario 2: zero query vector still occupies the execute pipeline.
  exec_vec({pr*bw{1'b0}}, "query_zero_vector");

  // Scenario 3: zero key load then full 8-vector execute burst should stay zero.
  reset_dut();
  load_key_vec({pr*bw{1'b0}}, 1'b1);
  exec_burst_8();

  if (fails == 0)
    $display("mac_array_tb completed: PASS");
  else
    $display("mac_array_tb completed: FAIL count=%0d", fails);
  $finish;
end

endmodule
