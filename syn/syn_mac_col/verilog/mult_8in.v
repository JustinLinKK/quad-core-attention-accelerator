// Created by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
// 1-cycle latency signed 8x8 multiplier with enable gating.
module mult_8in (clk, reset, en, x, y, p);

  input clk;
  input reset;
  input en;
  input signed [7:0] x;
  input signed [7:0] y;
  output reg signed [15:0] p;

  wire signed [3:0] x_hi;
  wire [3:0] x_lo;
  wire signed [3:0] y_hi;
  wire [3:0] y_lo;

  reg en_s1_q;
  reg signed [7:0] m_hh_q;
  reg signed [7:0] m_hl_q;
  reg signed [7:0] m_lh_q;
  reg [7:0] m_ll_q;

  wire signed [15:0] term_hh;
  wire signed [15:0] term_hl;
  wire signed [15:0] term_lh;
  wire signed [15:0] term_ll;

  wire signed [15:0] sum_a;
  wire signed [15:0] sum_b;
  wire signed [15:0] sum2;

  assign x_hi = x[7:4];
  assign x_lo = x[3:0];
  assign y_hi = y[7:4];
  assign y_lo = y[3:0];

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      en_s1_q <= 1'b0;
      m_hh_q <= 8'sd0;
      m_hl_q <= 8'sd0;
      m_lh_q <= 8'sd0;
      m_ll_q <= 8'd0;
    end else begin
      en_s1_q <= en;
      if (en) begin
        m_hh_q <= $signed(x_hi) * $signed(y_hi);
        m_hl_q <= $signed(x_hi) * $signed({1'b0, y_lo});
        m_lh_q <= $signed({1'b0, x_lo}) * $signed(y_hi);
        m_ll_q <= x_lo * y_lo;
      end
    end
  end

  assign term_hh = $signed(m_hh_q) <<< 8;
  assign term_hl = $signed(m_hl_q) <<< 4;
  assign term_lh = $signed(m_lh_q) <<< 4;
  assign term_ll = $signed({1'b0, m_ll_q});

  // Balanced reduction (helps critical path vs term_hh+term_hl+term_lh+term_ll)
  assign sum_a = term_hh + term_hl;
  assign sum_b = term_lh + term_ll;
  assign sum2  = sum_a + sum_b;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      p <= 16'sd0;
    end else if (en_s1_q)
      p <= sum2;
  end

endmodule