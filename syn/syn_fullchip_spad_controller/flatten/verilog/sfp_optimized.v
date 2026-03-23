// Created by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
// Step6 SFP keeps the Step5 timing-closed radix-4 divider and registered
// writeback stage, then layers B2 threshold skip outside the divider critical
// path.
module sfp_div_radix4_exact_main (
    clk,
    reset,
    en,
    numer,
    denom,
    out,
    out_valid
);

  parameter width = 22;
  localparam integer stages = (width + 1) / 2;
  localparam integer div_w = stages * 2;
  localparam integer rem_w = div_w + 2;

  input clk;
  input reset;
  input en;
  input signed [width-1:0] numer;
  input signed [width-1:0] denom;

  output signed [width-1:0] out;
  output out_valid;

  reg [div_w-1:0] dividend_pipe [0:stages];
  reg [rem_w-1:0] divisor_pipe [0:stages];
  reg [div_w-1:0] quotient_pipe [0:stages];
  reg [rem_w-1:0] remainder_pipe [0:stages];
  reg sign_pipe [0:stages];
  reg div0_pipe [0:stages];
  reg valid_pipe [0:stages];

  reg [div_w-1:0] dividend_cmp_pipe [0:stages-1];
  reg [rem_w-1:0] divisor_cmp_pipe [0:stages-1];
  reg [div_w-1:0] quotient_cmp_pipe [0:stages-1];
  reg [rem_w-1:0] rem_shift_cmp_pipe [0:stages-1];
  reg [rem_w-1:0] div1_cmp_pipe [0:stages-1];
  reg [rem_w-1:0] div2_cmp_pipe [0:stages-1];
  reg [rem_w-1:0] div3_cmp_pipe [0:stages-1];
  reg sign_cmp_pipe [0:stages-1];
  reg div0_cmp_pipe [0:stages-1];
  reg valid_cmp_pipe [0:stages-1];

  reg [div_w-1:0] dividend_mid_pipe [0:stages-1];
  reg [rem_w-1:0] divisor_mid_pipe [0:stages-1];
  reg [div_w-1:0] quotient_mid_pipe [0:stages-1];
  reg [rem_w-1:0] rem_shift_mid_pipe [0:stages-1];
  reg [rem_w-1:0] sub_operand_mid_pipe [0:stages-1];
  reg [1:0] qdigit_mid_pipe [0:stages-1];
  reg sign_mid_pipe [0:stages-1];
  reg div0_mid_pipe [0:stages-1];
  reg valid_mid_pipe [0:stages-1];

  wire numer_neg;
  wire denom_neg;
  wire [width-1:0] numer_abs;
  wire [width-1:0] denom_abs;
  wire [div_w-1:0] numer_abs_pad;
  wire [div_w-1:0] denom_abs_pad;
  wire signed [width-1:0] quotient_signed_w;

  assign numer_neg = numer[width-1];
  assign denom_neg = denom[width-1];
  assign numer_abs = numer_neg ? (~numer + 1'b1) : numer;
  assign denom_abs = denom_neg ? (~denom + 1'b1) : denom;
  assign numer_abs_pad = (div_w == width) ? numer_abs : {{(div_w-width){1'b0}}, numer_abs};
  assign denom_abs_pad = (div_w == width) ? denom_abs : {{(div_w-width){1'b0}}, denom_abs};
  assign quotient_signed_w = $signed(quotient_pipe[stages][width-1:0]);
  assign out_valid = valid_pipe[stages];
  assign out = div0_pipe[stages] ? {width{1'b0}} :
               (sign_pipe[stages] ? -quotient_signed_w : quotient_signed_w);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      dividend_pipe[0] <= {div_w{1'b0}};
      divisor_pipe[0] <= {rem_w{1'b0}};
      quotient_pipe[0] <= {div_w{1'b0}};
      remainder_pipe[0] <= {rem_w{1'b0}};
      sign_pipe[0] <= 1'b0;
      div0_pipe[0] <= 1'b0;
      valid_pipe[0] <= 1'b0;
    end else begin
      dividend_pipe[0] <= numer_abs_pad;
      divisor_pipe[0] <= {{(rem_w-div_w){1'b0}}, denom_abs_pad};
      quotient_pipe[0] <= {div_w{1'b0}};
      remainder_pipe[0] <= {rem_w{1'b0}};
      sign_pipe[0] <= numer_neg ^ denom_neg;
      div0_pipe[0] <= (denom == {width{1'b0}});
      valid_pipe[0] <= en;
    end
  end

  genvar gi;
  generate
    for (gi = 0; gi < stages; gi = gi + 1) begin : div_stage
      localparam integer dividend_bit_hi = div_w - (2 * gi) - 1;

      wire [1:0] next_dividend_bits_w;
      wire [rem_w-1:0] rem_shift_w;
      wire [rem_w-1:0] div1_w;
      wire [rem_w-1:0] div2_w;
      wire [rem_w-1:0] div3_w;
      wire [1:0] qdigit_w;
      wire [rem_w-1:0] sub_operand_w;
      wire [rem_w-1:0] rem_next_w;
      wire [div_w-1:0] quot_next_w;

      assign next_dividend_bits_w = dividend_pipe[gi][dividend_bit_hi -: 2];
      assign rem_shift_w = {remainder_pipe[gi][rem_w-3:0], next_dividend_bits_w};
      assign div1_w = divisor_pipe[gi];
      assign div2_w = divisor_pipe[gi] << 1;
      assign div3_w = div1_w + div2_w;
      assign qdigit_w = (div1_cmp_pipe[gi] == {rem_w{1'b0}}) ? 2'd0 :
                        (rem_shift_cmp_pipe[gi] >= div3_cmp_pipe[gi]) ? 2'd3 :
                        (rem_shift_cmp_pipe[gi] >= div2_cmp_pipe[gi]) ? 2'd2 :
                        (rem_shift_cmp_pipe[gi] >= div1_cmp_pipe[gi]) ? 2'd1 : 2'd0;
      assign sub_operand_w = (qdigit_w == 2'd3) ? div3_cmp_pipe[gi] :
                             (qdigit_w == 2'd2) ? div2_cmp_pipe[gi] :
                             (qdigit_w == 2'd1) ? div1_cmp_pipe[gi] :
                                                  {rem_w{1'b0}};
      assign rem_next_w = rem_shift_mid_pipe[gi] - sub_operand_mid_pipe[gi];
      assign quot_next_w = {quotient_mid_pipe[gi][div_w-3:0], qdigit_mid_pipe[gi]};

      always @(posedge clk or posedge reset) begin
        if (reset) begin
          dividend_cmp_pipe[gi] <= {div_w{1'b0}};
          divisor_cmp_pipe[gi] <= {rem_w{1'b0}};
          quotient_cmp_pipe[gi] <= {div_w{1'b0}};
          rem_shift_cmp_pipe[gi] <= {rem_w{1'b0}};
          div1_cmp_pipe[gi] <= {rem_w{1'b0}};
          div2_cmp_pipe[gi] <= {rem_w{1'b0}};
          div3_cmp_pipe[gi] <= {rem_w{1'b0}};
          sign_cmp_pipe[gi] <= 1'b0;
          div0_cmp_pipe[gi] <= 1'b0;
          valid_cmp_pipe[gi] <= 1'b0;
        end else begin
          dividend_cmp_pipe[gi] <= dividend_pipe[gi];
          divisor_cmp_pipe[gi] <= divisor_pipe[gi];
          quotient_cmp_pipe[gi] <= quotient_pipe[gi];
          rem_shift_cmp_pipe[gi] <= rem_shift_w;
          div1_cmp_pipe[gi] <= div1_w;
          div2_cmp_pipe[gi] <= div2_w;
          div3_cmp_pipe[gi] <= div3_w;
          sign_cmp_pipe[gi] <= sign_pipe[gi];
          div0_cmp_pipe[gi] <= div0_pipe[gi];
          valid_cmp_pipe[gi] <= valid_pipe[gi];
        end
      end

      always @(posedge clk or posedge reset) begin
        if (reset) begin
          dividend_mid_pipe[gi] <= {div_w{1'b0}};
          divisor_mid_pipe[gi] <= {rem_w{1'b0}};
          quotient_mid_pipe[gi] <= {div_w{1'b0}};
          rem_shift_mid_pipe[gi] <= {rem_w{1'b0}};
          sub_operand_mid_pipe[gi] <= {rem_w{1'b0}};
          qdigit_mid_pipe[gi] <= 2'd0;
          sign_mid_pipe[gi] <= 1'b0;
          div0_mid_pipe[gi] <= 1'b0;
          valid_mid_pipe[gi] <= 1'b0;
        end else begin
          dividend_mid_pipe[gi] <= dividend_cmp_pipe[gi];
          divisor_mid_pipe[gi] <= divisor_cmp_pipe[gi];
          quotient_mid_pipe[gi] <= quotient_cmp_pipe[gi];
          rem_shift_mid_pipe[gi] <= rem_shift_cmp_pipe[gi];
          sub_operand_mid_pipe[gi] <= sub_operand_w;
          qdigit_mid_pipe[gi] <= qdigit_w;
          sign_mid_pipe[gi] <= sign_cmp_pipe[gi];
          div0_mid_pipe[gi] <= div0_cmp_pipe[gi];
          valid_mid_pipe[gi] <= valid_cmp_pipe[gi];
        end
      end

      always @(posedge clk or posedge reset) begin
        if (reset) begin
          dividend_pipe[gi+1] <= {div_w{1'b0}};
          divisor_pipe[gi+1] <= {rem_w{1'b0}};
          quotient_pipe[gi+1] <= {div_w{1'b0}};
          remainder_pipe[gi+1] <= {rem_w{1'b0}};
          sign_pipe[gi+1] <= 1'b0;
          div0_pipe[gi+1] <= 1'b0;
          valid_pipe[gi+1] <= 1'b0;
        end else begin
          dividend_pipe[gi+1] <= dividend_mid_pipe[gi];
          divisor_pipe[gi+1] <= divisor_mid_pipe[gi];
          quotient_pipe[gi+1] <= quot_next_w;
          remainder_pipe[gi+1] <= rem_next_w;
          sign_pipe[gi+1] <= sign_mid_pipe[gi];
          div0_pipe[gi+1] <= div0_mid_pipe[gi];
          valid_pipe[gi+1] <= valid_mid_pipe[gi];
        end
      end
    end
  endgenerate

endmodule

module sfp_optimized (
    clk,
    reset,
    acc,
    div,
    multi_core,
    ext_sum_wr,
    threshold_sum_wr,
    threshold_sum_in,
    sum_in,
    sum_out,
    sum_valid,
    ext_sum_empty,
    div_done,
    sfp_in,
    sfp_out
);

  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+6;
  parameter sum_out_bw = bw_psum+4;
  parameter sum_in_bw = sum_out_bw+2;

  localparam integer ext_norm_pad = bw_psum + 7 - sum_in_bw;
  localparam integer threshold_sum_ext_pad = (sum_in_bw > sum_out_bw) ? (sum_in_bw - sum_out_bw) : 0;
  localparam integer div_stages = (bw_psum + 1) / 2;
  localparam integer div_data_latency = 3 * div_stages;
  localparam integer div_done_latency = div_data_latency + 1;

  input clk;
  input reset;
  input acc;
  input div;
  input multi_core;
  input ext_sum_wr;
  input threshold_sum_wr;
  input [sum_out_bw-1:0] threshold_sum_in;
  input [sum_in_bw-1:0] sum_in;
  input [col*bw_psum-1:0] sfp_in;

  output [col*bw_psum-1:0] sfp_out;
  output [sum_out_bw-1:0] sum_out;
  output sum_valid;
  output ext_sum_empty;
  output div_done;

  reg [sum_out_bw-1:0] sum_q;
  reg sum_valid_q;
  reg [sum_out_bw-1:0] threshold_sum_q;
  reg [sum_in_bw-1:0] sum_ext;
  reg ext_sum_empty_q;
  reg div_done_q;
  reg b2_skip_ext_q;
  reg div_q;
  reg abs_pipe_vld_q;
  reg [bw_psum-1:0] abs_pipe_q0;
  reg [bw_psum-1:0] abs_pipe_q1;
  reg [bw_psum-1:0] abs_pipe_q2;
  reg [bw_psum-1:0] abs_pipe_q3;
  reg [bw_psum-1:0] abs_pipe_q4;
  reg [bw_psum-1:0] abs_pipe_q5;
  reg [bw_psum-1:0] abs_pipe_q6;
  reg [bw_psum-1:0] abs_pipe_q7;
  reg acc_pair_vld_q;
  reg [sum_out_bw-1:0] acc_pair01_q;
  reg [sum_out_bw-1:0] acc_pair23_q;
  reg [sum_out_bw-1:0] acc_pair45_q;
  reg [sum_out_bw-1:0] acc_pair67_q;

  reg signed [bw_psum-1:0] sfp_out_sign0;
  reg signed [bw_psum-1:0] sfp_out_sign1;
  reg signed [bw_psum-1:0] sfp_out_sign2;
  reg signed [bw_psum-1:0] sfp_out_sign3;
  reg signed [bw_psum-1:0] sfp_out_sign4;
  reg signed [bw_psum-1:0] sfp_out_sign5;
  reg signed [bw_psum-1:0] sfp_out_sign6;
  reg signed [bw_psum-1:0] sfp_out_sign7;

  reg signed [bw_psum-1:0] div_hold0_q;
  reg signed [bw_psum-1:0] div_hold1_q;
  reg signed [bw_psum-1:0] div_hold2_q;
  reg signed [bw_psum-1:0] div_hold3_q;
  reg signed [bw_psum-1:0] div_hold4_q;
  reg signed [bw_psum-1:0] div_hold5_q;
  reg signed [bw_psum-1:0] div_hold6_q;
  reg signed [bw_psum-1:0] div_hold7_q;
  reg div_commit_vld_q;
  reg div_commit_mc_q;
  reg [div_data_latency:0] div_mc_pipe_q;
  reg [div_data_latency:0] skip_pipe_q;

  wire signed [bw_psum-1:0] sfp_in_sign0;
  wire signed [bw_psum-1:0] sfp_in_sign1;
  wire signed [bw_psum-1:0] sfp_in_sign2;
  wire signed [bw_psum-1:0] sfp_in_sign3;
  wire signed [bw_psum-1:0] sfp_in_sign4;
  wire signed [bw_psum-1:0] sfp_in_sign5;
  wire signed [bw_psum-1:0] sfp_in_sign6;
  wire signed [bw_psum-1:0] sfp_in_sign7;

  wire q_empty;
  wire q_full;
  wire b2_q_empty;
  wire b2_q_full;
  wire [bw_psum-1:0] denom_head;
  wire b2_skip_head;
  wire [bw_psum-1:0] sum_ext_norm;
  wire [sum_in_bw-1:0] threshold_sum_ext;
  wire threshold_sum_en;
  wire acc_accept_w;
  wire [sum_out_bw-1:0] acc_sum_final_w;
  wire [bw_psum-1:0] acc_denom_final_w;
  wire b2_skip_acc_w;
  wire signed [bw_psum-1:0] denom_use;
  wire can_div;
  wire row_consume_fire;
  wire b2_skip_use;
  wire div_fire;
  wire skip_fire;

  wire signed [bw_psum-1:0] div_result0;
  wire signed [bw_psum-1:0] div_result1;
  wire signed [bw_psum-1:0] div_result2;
  wire signed [bw_psum-1:0] div_result3;
  wire signed [bw_psum-1:0] div_result4;
  wire signed [bw_psum-1:0] div_result5;
  wire signed [bw_psum-1:0] div_result6;
  wire signed [bw_psum-1:0] div_result7;
  wire [7:0] div_out_valid_vec;
  wire div_out_valid;

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

  assign sum_out = sum_q;
  assign sum_valid = sum_valid_q;
  assign ext_sum_empty = ext_sum_empty_q;
  assign div_done = div_done_q;

  assign threshold_sum_en = |threshold_sum_q;
  assign threshold_sum_ext = (sum_in_bw > sum_out_bw) ?
                             {{threshold_sum_ext_pad{1'b0}}, threshold_sum_q} :
                             threshold_sum_q[sum_in_bw-1:0];
  assign sum_ext_norm = {{ext_norm_pad{1'b0}}, sum_ext[sum_in_bw-1:7]};
  assign acc_accept_w = acc && !q_full && !b2_q_full;
  assign acc_sum_final_w = acc_pair01_q + acc_pair23_q + acc_pair45_q + acc_pair67_q;
  assign acc_denom_final_w = {{3{1'b0}}, acc_sum_final_w[sum_out_bw-1:7]};
  assign b2_skip_acc_w = threshold_sum_en && (acc_sum_final_w < threshold_sum_q);
  assign denom_use = multi_core ? $signed(sum_ext_norm) : $signed(denom_head);
  assign can_div = multi_core ? !ext_sum_empty_q : (!q_empty && !b2_q_empty);
  assign row_consume_fire = div && !div_q && can_div;
  assign b2_skip_use = multi_core ? b2_skip_ext_q : b2_skip_head;
  assign div_fire = row_consume_fire && !b2_skip_use;
  assign skip_fire = row_consume_fire && b2_skip_use;
  assign div_out_valid = &div_out_valid_vec;

  fifo_depth16 #(.bw(bw_psum)) denom_fifo_storage (
      .rd_clk(clk),
      .wr_clk(clk),
      .in(acc_denom_final_w),
      .out(denom_head),
      .rd(row_consume_fire && !multi_core),
      .wr(acc_pair_vld_q),
      .o_full(q_full),
      .o_empty(q_empty),
      .reset(reset)
  );

  fifo_depth16 #(.bw(1)) b2_skip_fifo_storage (
      .rd_clk(clk),
      .wr_clk(clk),
      .in(b2_skip_acc_w),
      .out(b2_skip_head),
      .rd(row_consume_fire && !multi_core),
      .wr(acc_pair_vld_q),
      .o_full(b2_q_full),
      .o_empty(b2_q_empty),
      .reset(reset)
  );

  sfp_div_radix4_exact_main #(.width(bw_psum)) div0 (
      .clk(clk), .reset(reset), .en(div_fire), .numer(sfp_in_sign0), .denom(denom_use),
      .out(div_result0), .out_valid(div_out_valid_vec[0])
  );
  sfp_div_radix4_exact_main #(.width(bw_psum)) div1 (
      .clk(clk), .reset(reset), .en(div_fire), .numer(sfp_in_sign1), .denom(denom_use),
      .out(div_result1), .out_valid(div_out_valid_vec[1])
  );
  sfp_div_radix4_exact_main #(.width(bw_psum)) div2 (
      .clk(clk), .reset(reset), .en(div_fire), .numer(sfp_in_sign2), .denom(denom_use),
      .out(div_result2), .out_valid(div_out_valid_vec[2])
  );
  sfp_div_radix4_exact_main #(.width(bw_psum)) div3 (
      .clk(clk), .reset(reset), .en(div_fire), .numer(sfp_in_sign3), .denom(denom_use),
      .out(div_result3), .out_valid(div_out_valid_vec[3])
  );
  sfp_div_radix4_exact_main #(.width(bw_psum)) div4 (
      .clk(clk), .reset(reset), .en(div_fire), .numer(sfp_in_sign4), .denom(denom_use),
      .out(div_result4), .out_valid(div_out_valid_vec[4])
  );
  sfp_div_radix4_exact_main #(.width(bw_psum)) div5 (
      .clk(clk), .reset(reset), .en(div_fire), .numer(sfp_in_sign5), .denom(denom_use),
      .out(div_result5), .out_valid(div_out_valid_vec[5])
  );
  sfp_div_radix4_exact_main #(.width(bw_psum)) div6 (
      .clk(clk), .reset(reset), .en(div_fire), .numer(sfp_in_sign6), .denom(denom_use),
      .out(div_result6), .out_valid(div_out_valid_vec[6])
  );
  sfp_div_radix4_exact_main #(.width(bw_psum)) div7 (
      .clk(clk), .reset(reset), .en(div_fire), .numer(sfp_in_sign7), .denom(denom_use),
      .out(div_result7), .out_valid(div_out_valid_vec[7])
  );

  always @(posedge clk) begin
    if (reset) begin
      sum_q <= {sum_out_bw{1'b0}};
      sum_valid_q <= 1'b0;
      threshold_sum_q <= {sum_out_bw{1'b0}};
      sum_ext <= {sum_in_bw{1'b0}};
      ext_sum_empty_q <= 1'b1;
      div_done_q <= 1'b0;
      b2_skip_ext_q <= 1'b0;
      div_q <= 1'b0;
      abs_pipe_vld_q <= 1'b0;
      abs_pipe_q0 <= {bw_psum{1'b0}};
      abs_pipe_q1 <= {bw_psum{1'b0}};
      abs_pipe_q2 <= {bw_psum{1'b0}};
      abs_pipe_q3 <= {bw_psum{1'b0}};
      abs_pipe_q4 <= {bw_psum{1'b0}};
      abs_pipe_q5 <= {bw_psum{1'b0}};
      abs_pipe_q6 <= {bw_psum{1'b0}};
      abs_pipe_q7 <= {bw_psum{1'b0}};
      acc_pair_vld_q <= 1'b0;
      acc_pair01_q <= {sum_out_bw{1'b0}};
      acc_pair23_q <= {sum_out_bw{1'b0}};
      acc_pair45_q <= {sum_out_bw{1'b0}};
      acc_pair67_q <= {sum_out_bw{1'b0}};
      sfp_out_sign0 <= {bw_psum{1'b0}};
      sfp_out_sign1 <= {bw_psum{1'b0}};
      sfp_out_sign2 <= {bw_psum{1'b0}};
      sfp_out_sign3 <= {bw_psum{1'b0}};
      sfp_out_sign4 <= {bw_psum{1'b0}};
      sfp_out_sign5 <= {bw_psum{1'b0}};
      sfp_out_sign6 <= {bw_psum{1'b0}};
      sfp_out_sign7 <= {bw_psum{1'b0}};
      div_hold0_q <= {bw_psum{1'b0}};
      div_hold1_q <= {bw_psum{1'b0}};
      div_hold2_q <= {bw_psum{1'b0}};
      div_hold3_q <= {bw_psum{1'b0}};
      div_hold4_q <= {bw_psum{1'b0}};
      div_hold5_q <= {bw_psum{1'b0}};
      div_hold6_q <= {bw_psum{1'b0}};
      div_hold7_q <= {bw_psum{1'b0}};
      div_commit_vld_q <= 1'b0;
      div_commit_mc_q <= 1'b0;
      div_mc_pipe_q <= {(div_data_latency+1){1'b0}};
      skip_pipe_q <= {(div_data_latency+1){1'b0}};
    end else begin
      sum_valid_q <= 1'b0;
      div_done_q <= 1'b0;
      div_q <= div;
      div_commit_vld_q <= div_out_valid;
      div_commit_mc_q <= div_out_valid && div_mc_pipe_q[div_data_latency];
      div_mc_pipe_q <= {div_mc_pipe_q[div_data_latency-1:0], (div_fire ? multi_core : 1'b0)};
      skip_pipe_q <= {skip_pipe_q[div_data_latency-1:0], skip_fire};

      if (threshold_sum_wr)
        threshold_sum_q <= threshold_sum_in;

      if (ext_sum_wr && ext_sum_empty_q) begin
        sum_ext <= sum_in;
        ext_sum_empty_q <= 1'b0;
        b2_skip_ext_q <= threshold_sum_en && (sum_in < threshold_sum_ext);
      end

      abs_pipe_vld_q <= acc_accept_w;
      if (acc_accept_w) begin
        abs_pipe_q0 <= abs_full(sfp_in_sign0);
        abs_pipe_q1 <= abs_full(sfp_in_sign1);
        abs_pipe_q2 <= abs_full(sfp_in_sign2);
        abs_pipe_q3 <= abs_full(sfp_in_sign3);
        abs_pipe_q4 <= abs_full(sfp_in_sign4);
        abs_pipe_q5 <= abs_full(sfp_in_sign5);
        abs_pipe_q6 <= abs_full(sfp_in_sign6);
        abs_pipe_q7 <= abs_full(sfp_in_sign7);
      end

      acc_pair_vld_q <= abs_pipe_vld_q;
      if (abs_pipe_vld_q) begin
        acc_pair01_q <= {4'b0, abs_pipe_q0} + {4'b0, abs_pipe_q1};
        acc_pair23_q <= {4'b0, abs_pipe_q2} + {4'b0, abs_pipe_q3};
        acc_pair45_q <= {4'b0, abs_pipe_q4} + {4'b0, abs_pipe_q5};
        acc_pair67_q <= {4'b0, abs_pipe_q6} + {4'b0, abs_pipe_q7};
      end

      if (acc_pair_vld_q) begin
        sum_q <= acc_sum_final_w;
        sum_valid_q <= 1'b1;
      end

      if (div_out_valid) begin
        div_hold0_q <= div_result0;
        div_hold1_q <= div_result1;
        div_hold2_q <= div_result2;
        div_hold3_q <= div_result3;
        div_hold4_q <= div_result4;
        div_hold5_q <= div_result5;
        div_hold6_q <= div_result6;
        div_hold7_q <= div_result7;
      end

      if (row_consume_fire && multi_core)
        ext_sum_empty_q <= 1'b1;

      if (skip_pipe_q[div_data_latency]) begin
        div_done_q <= 1'b1;
        sfp_out_sign0 <= {bw_psum{1'b0}};
        sfp_out_sign1 <= {bw_psum{1'b0}};
        sfp_out_sign2 <= {bw_psum{1'b0}};
        sfp_out_sign3 <= {bw_psum{1'b0}};
        sfp_out_sign4 <= {bw_psum{1'b0}};
        sfp_out_sign5 <= {bw_psum{1'b0}};
        sfp_out_sign6 <= {bw_psum{1'b0}};
        sfp_out_sign7 <= {bw_psum{1'b0}};
      end

      if (div_commit_vld_q) begin
        div_done_q <= 1'b1;
        sfp_out_sign0 <= div_hold0_q;
        sfp_out_sign1 <= div_hold1_q;
        sfp_out_sign2 <= div_hold2_q;
        sfp_out_sign3 <= div_hold3_q;
        sfp_out_sign4 <= div_hold4_q;
        sfp_out_sign5 <= div_hold5_q;
        sfp_out_sign6 <= div_hold6_q;
        sfp_out_sign7 <= div_hold7_q;
      end
    end
  end

endmodule
