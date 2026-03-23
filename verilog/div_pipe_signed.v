// Created by OpenAI Codex for ECE 260B Project
// Please do not spread this code without permission
//
// Fully pipelined signed divider with one result per cycle after fill.
// Division by zero returns 0.
module div_pipe_signed (
    clk,
    reset,
    en,
    numer,
    denom,
    out,
    out_valid);

  parameter width = 22;

  input clk;
  input reset;
  input en;
  input signed [width-1:0] numer;
  input signed [width-1:0] denom;

  output signed [width-1:0] out;
  output out_valid;

  reg signed [width-1:0] out_q;
  reg out_valid_q;

  reg [width-1:0] dividend_pipe [0:width];
  reg [width-1:0] divisor_pipe  [0:width];
  reg [width-1:0] quotient_pipe [0:width];
  reg [width:0]   remainder_pipe[0:width];
  reg             sign_pipe     [0:width];
  reg             div0_pipe     [0:width];
  reg             valid_pipe    [0:width];

  wire [width-1:0] numer_abs;
  wire [width-1:0] denom_abs;
  wire numer_neg;
  wire denom_neg;

  assign numer_neg = numer[width-1];
  assign denom_neg = denom[width-1];
  assign numer_abs = numer_neg ? (~numer + 1'b1) : numer;
  assign denom_abs = denom_neg ? (~denom + 1'b1) : denom;

  assign out = out_q;
  assign out_valid = out_valid_q;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      out_q <= {width{1'b0}};
      out_valid_q <= 1'b0;
      dividend_pipe[0] <= {width{1'b0}};
      divisor_pipe[0] <= {width{1'b0}};
      quotient_pipe[0] <= {width{1'b0}};
      remainder_pipe[0] <= {(width+1){1'b0}};
      sign_pipe[0] <= 1'b0;
      div0_pipe[0] <= 1'b0;
      valid_pipe[0] <= 1'b0;
    end else begin
      dividend_pipe[0] <= numer_abs;
      divisor_pipe[0] <= denom_abs;
      quotient_pipe[0] <= {width{1'b0}};
      remainder_pipe[0] <= {(width+1){1'b0}};
      sign_pipe[0] <= numer_neg ^ denom_neg;
      div0_pipe[0] <= (denom == {width{1'b0}});
      valid_pipe[0] <= en;

      out_valid_q <= valid_pipe[width];
      if (valid_pipe[width]) begin
        if (div0_pipe[width])
          out_q <= {width{1'b0}};
        else if (sign_pipe[width])
          out_q <= -$signed(quotient_pipe[width]);
        else
          out_q <= $signed(quotient_pipe[width]);
      end
    end
  end

  genvar gi;
  generate
    for (gi = 0; gi < width; gi = gi + 1) begin : div_stage
      wire [width:0] rem_shift_w;
      wire [width:0] div_ext_w;
      wire take_sub_w;
      wire [width:0] rem_next_w;
      wire [width-1:0] quo_mask_w;
      wire [width-1:0] quo_next_w;

      assign rem_shift_w = {remainder_pipe[gi][width-1:0], dividend_pipe[gi][width-1-gi]};
      assign div_ext_w = {1'b0, divisor_pipe[gi]};
      assign take_sub_w = (div_ext_w != {(width+1){1'b0}}) && (rem_shift_w >= div_ext_w);
      assign rem_next_w = take_sub_w ? (rem_shift_w - div_ext_w) : rem_shift_w;
      assign quo_mask_w = take_sub_w ? (({{width-1{1'b0}}, 1'b1}) << (width-1-gi)) : {width{1'b0}};
      assign quo_next_w = quotient_pipe[gi] | quo_mask_w;

      always @(posedge clk or posedge reset) begin
        if (reset) begin
          dividend_pipe[gi+1] <= {width{1'b0}};
          divisor_pipe[gi+1] <= {width{1'b0}};
          quotient_pipe[gi+1] <= {width{1'b0}};
          remainder_pipe[gi+1] <= {(width+1){1'b0}};
          sign_pipe[gi+1] <= 1'b0;
          div0_pipe[gi+1] <= 1'b0;
          valid_pipe[gi+1] <= 1'b0;
        end else begin
          dividend_pipe[gi+1] <= dividend_pipe[gi];
          divisor_pipe[gi+1] <= divisor_pipe[gi];
          quotient_pipe[gi+1] <= quo_next_w;
          remainder_pipe[gi+1] <= rem_next_w;
          sign_pipe[gi+1] <= sign_pipe[gi];
          div0_pipe[gi+1] <= div0_pipe[gi];
          valid_pipe[gi+1] <= valid_pipe[gi];
        end
      end
    end
  endgenerate

endmodule
