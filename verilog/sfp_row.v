// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Modified by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
module sfp_row (clk, reset, acc, div, multi_core, ext_sum_wr, sum_in, sum_out, sum_valid, ext_sum_empty, sfp_in, sfp_out);

  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+4;
  parameter sum_in_bw = bw_psum;

  input  clk, reset, div, acc, multi_core, ext_sum_wr;
  input  [sum_in_bw-1:0] sum_in;
  input  [col*bw_psum-1:0] sfp_in;
  output [col*bw_psum-1:0] sfp_out;
  output [bw_psum+3:0] sum_out;
  output sum_valid;
  output ext_sum_empty;

  reg div_q;
  reg fifo_wr;
  reg [bw_psum+3:0] sum_q;
  wire [bw_psum+3:0] sum_this_core;
  reg [sum_in_bw-1:0] sum_ext;
  reg ext_sum_empty_q;
  reg sum_valid_q;

  reg signed [bw_psum-1:0] sfp_out_sign0;
  reg signed [bw_psum-1:0] sfp_out_sign1;
  reg signed [bw_psum-1:0] sfp_out_sign2;
  reg signed [bw_psum-1:0] sfp_out_sign3;
  reg signed [bw_psum-1:0] sfp_out_sign4;
  reg signed [bw_psum-1:0] sfp_out_sign5;
  reg signed [bw_psum-1:0] sfp_out_sign6;
  reg signed [bw_psum-1:0] sfp_out_sign7;

  wire signed [bw_psum-1:0] sfp_in_sign0;
  wire signed [bw_psum-1:0] sfp_in_sign1;
  wire signed [bw_psum-1:0] sfp_in_sign2;
  wire signed [bw_psum-1:0] sfp_in_sign3;
  wire signed [bw_psum-1:0] sfp_in_sign4;
  wire signed [bw_psum-1:0] sfp_in_sign5;
  wire signed [bw_psum-1:0] sfp_in_sign6;
  wire signed [bw_psum-1:0] sfp_in_sign7;

  reg [bw_psum+3:0] full_abs_sum;

  wire signed [bw_psum-1:0] sum_this_core_norm;
  wire [bw_psum-1:0] sum_ext_norm;
  wire signed [bw_psum-1:0] sum_norm_sel;
  localparam integer EXT_NORM_PAD = (bw_psum + 7 > sum_in_bw) ? (bw_psum + 7 - sum_in_bw) : 0;

  function [bw_psum-1:0] abs_full;
    input signed [bw_psum-1:0] val;
    begin
      if (val[bw_psum-1])
        abs_full = ~val + 1'b1;
      else
        abs_full = val;
    end
  endfunction

  assign sfp_in_sign0 = sfp_in[bw_psum*1-1 : bw_psum*0];
  assign sfp_in_sign1 = sfp_in[bw_psum*2-1 : bw_psum*1];
  assign sfp_in_sign2 = sfp_in[bw_psum*3-1 : bw_psum*2];
  assign sfp_in_sign3 = sfp_in[bw_psum*4-1 : bw_psum*3];
  assign sfp_in_sign4 = sfp_in[bw_psum*5-1 : bw_psum*4];
  assign sfp_in_sign5 = sfp_in[bw_psum*6-1 : bw_psum*5];
  assign sfp_in_sign6 = sfp_in[bw_psum*7-1 : bw_psum*6];
  assign sfp_in_sign7 = sfp_in[bw_psum*8-1 : bw_psum*7];

  assign sfp_out[bw_psum*1-1 : bw_psum*0] = sfp_out_sign0;
  assign sfp_out[bw_psum*2-1 : bw_psum*1] = sfp_out_sign1;
  assign sfp_out[bw_psum*3-1 : bw_psum*2] = sfp_out_sign2;
  assign sfp_out[bw_psum*4-1 : bw_psum*3] = sfp_out_sign3;
  assign sfp_out[bw_psum*5-1 : bw_psum*4] = sfp_out_sign4;
  assign sfp_out[bw_psum*6-1 : bw_psum*5] = sfp_out_sign5;
  assign sfp_out[bw_psum*7-1 : bw_psum*6] = sfp_out_sign6;
  assign sfp_out[bw_psum*8-1 : bw_psum*7] = sfp_out_sign7;

  assign sum_this_core_norm = sum_this_core[bw_psum+3:7];
  assign sum_ext_norm = {{EXT_NORM_PAD{1'b0}}, sum_ext[sum_in_bw-1:7]};
  // Multicore contract:
  // 1) ACC exports local sum via sum_out/sum_valid.
  // 2) External adder returns final global sum via ext_sum_wr/sum_in.
  // 3) DIV in multicore uses returned global sum directly.
  assign sum_norm_sel = multi_core ? sum_ext_norm : sum_this_core_norm;

  assign sum_out = sum_q;
  assign sum_valid = sum_valid_q;
  assign ext_sum_empty = ext_sum_empty_q;

  always @(*) begin
    full_abs_sum =
      {4'b0, abs_full(sfp_in_sign0)} +
      {4'b0, abs_full(sfp_in_sign1)} +
      {4'b0, abs_full(sfp_in_sign2)} +
      {4'b0, abs_full(sfp_in_sign3)} +
      {4'b0, abs_full(sfp_in_sign4)} +
      {4'b0, abs_full(sfp_in_sign5)} +
      {4'b0, abs_full(sfp_in_sign6)} +
      {4'b0, abs_full(sfp_in_sign7)};
  end

  fifo_depth16 #(.bw(bw_psum+4)) fifo_inst_int (
     .rd_clk(clk),
     .wr_clk(clk),
     .in(sum_q),
     .out(sum_this_core),
     .rd(div_q),
     .wr(fifo_wr),
     .o_full(),
     .o_empty(),
     .reset(reset)
  );

  always @ (posedge clk) begin
    if (reset) begin
      fifo_wr <= 1'b0;
      div_q <= 1'b0;
      sum_q <= {(bw_psum+4){1'b0}};
      sum_ext <= {sum_in_bw{1'b0}};
      ext_sum_empty_q <= 1'b1;
      sum_valid_q <= 1'b0;
      sfp_out_sign0 <= {bw_psum{1'b0}};
      sfp_out_sign1 <= {bw_psum{1'b0}};
      sfp_out_sign2 <= {bw_psum{1'b0}};
      sfp_out_sign3 <= {bw_psum{1'b0}};
      sfp_out_sign4 <= {bw_psum{1'b0}};
      sfp_out_sign5 <= {bw_psum{1'b0}};
      sfp_out_sign6 <= {bw_psum{1'b0}};
      sfp_out_sign7 <= {bw_psum{1'b0}};
    end
    else begin
      sum_valid_q <= 1'b0;
      div_q <= div;

      if (ext_sum_wr && ext_sum_empty_q) begin
        sum_ext <= sum_in;
        ext_sum_empty_q <= 1'b0;
      end

      if (acc) begin
        sum_q <= full_abs_sum;
        fifo_wr <= 1'b1;
        sum_valid_q <= 1'b1;
      end
      else begin
        fifo_wr <= 1'b0;
        if (div) begin
          if (multi_core)
            ext_sum_empty_q <= 1'b1;
          sfp_out_sign0 <= sfp_in_sign0 / sum_norm_sel;
          sfp_out_sign1 <= sfp_in_sign1 / sum_norm_sel;
          sfp_out_sign2 <= sfp_in_sign2 / sum_norm_sel;
          sfp_out_sign3 <= sfp_in_sign3 / sum_norm_sel;
          sfp_out_sign4 <= sfp_in_sign4 / sum_norm_sel;
          sfp_out_sign5 <= sfp_in_sign5 / sum_norm_sel;
          sfp_out_sign6 <= sfp_in_sign6 / sum_norm_sel;
          sfp_out_sign7 <= sfp_in_sign7 / sum_norm_sel;
        end
      end
    end
  end


endmodule
