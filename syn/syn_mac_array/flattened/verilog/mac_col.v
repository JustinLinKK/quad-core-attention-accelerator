// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Modify by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
module mac_col (
    clk,
    reset,
    out,
    q_in,
    q_out,
    q_zero_in,
    q_zero_out,
    i_inst,
    fifo_wr,
    o_inst);

  parameter bw = 8;
  parameter bw_psum = 2*bw+6;
  parameter pr = 8;
  parameter col_id = 0;

  input  clk, reset;
  input  signed [pr*bw-1:0] q_in;
  input  q_zero_in;
  input  [1:0] i_inst; // [1]: execute, [0]: load

  output signed [bw_psum-1:0] out;
  output signed [pr*bw-1:0] q_out;
  output q_zero_out;
  output [1:0] o_inst; // [1]: execute, [0]: load
  output fifo_wr;

  reg    load_ready_q;
  reg    [3:0] cnt_q;
  reg    [1:0] inst_q;
  reg    q_zero_q;
  reg    k_zero_q;

  reg    [4:0] exec_vld_pipe_q;
  reg    [4:0] exec_zero_pipe_q;

  reg   signed [pr*bw-1:0] query_q;
  reg   signed [pr*bw-1:0] key_q;

  wire   key_wr_fire;
  wire   exec_fire;
  wire   exec_k_zero;
  wire   mac_pipe_en;

  wire  signed [pr*bw-1:0] query_eff;
  wire  signed [pr*bw-1:0] key_eff;

  wire  signed [bw_psum-1:0] psum;

  assign o_inst = inst_q;

  // Always write to OFIFO when execute pipeline reaches output stage
  assign fifo_wr = exec_vld_pipe_q[4];

  assign q_out  = q_zero_q ? {pr*bw{1'b0}} : query_q;
  assign q_zero_out = q_zero_q;

  // Output forced to zero when key was zero
  assign out = exec_zero_pipe_q[4] ? {bw_psum{1'b0}} : psum;

  // Fire key register write when processing the last load of the column
  assign key_wr_fire = inst_q[0] && (cnt_q == 9-col_id);

  // Use registered instruction for safer timing
  assign exec_fire = inst_q[1];

  // Track zero-key condition
  assign exec_k_zero = exec_fire && k_zero_q;

  // MAC always runs during execute (throughput-first design)
  assign mac_pipe_en = exec_fire;

  // Operand isolation: when key is zero, feed zero into MAC
  assign key_eff = k_zero_q ? {pr*bw{1'b0}} : key_q;

  assign query_eff = q_in;

  mac_8in #(.bw(bw), .bw_psum(bw_psum), .pr(pr)) mac_8in_instance (
            .clk(clk),
            .reset(reset),
            .en(mac_pipe_en),
            .a(query_eff),
            .b(key_eff),
            .out(psum)
          );

  always @ (posedge clk)
  begin
    if (reset)
    begin
      cnt_q <= 0;
      load_ready_q <= 1;
      inst_q <= 0;
      exec_vld_pipe_q <= 5'b00000;
      exec_zero_pipe_q <= 5'b00000;
      query_q <= {pr*bw{1'b0}};
      q_zero_q <= 1'b1;
      k_zero_q <= 1'b1;
      key_q <= {pr*bw{1'b0}};
    end
    else
    begin
      if (i_inst[0] && !inst_q[0]) begin
        cnt_q <= 0;
        load_ready_q <= 1'b1;
      end

      inst_q <= i_inst;

      exec_vld_pipe_q <= {exec_vld_pipe_q[3:0], exec_fire};
      exec_zero_pipe_q <= {exec_zero_pipe_q[3:0], exec_k_zero};

      // Key load
      if (key_wr_fire)
      begin
        k_zero_q <= q_zero_in;
        key_q <= q_zero_in ? {pr*bw{1'b0}} : q_in;
      end

      // Query update during load
      if (inst_q[0])
      begin
        if (!q_zero_in)
          query_q <= q_in;

        q_zero_q <= q_zero_in;

        if (cnt_q == 9-col_id)
        begin
          cnt_q <= 0;
          load_ready_q <= 0;
        end
        else if (load_ready_q)
          cnt_q <= cnt_q + 1;
      end

      // Query update during execute
      else if (inst_q[1])
      begin
        if (!q_zero_in)
          query_q <= q_in;

        q_zero_q <= q_zero_in;
      end
    end
  end

endmodule
