// Created by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
module mac_8in (clk, reset, en, out, a, b);

  parameter bw = 8;
  parameter bw_psum = 2*bw+6;
  parameter pr = 8; // parallel factor: number of inputs = 8

  input clk;
  input reset;
  input en;
  input signed [pr*bw-1:0] a;
  input signed [pr*bw-1:0] b;

  output signed [bw_psum-1:0] out;

  localparam bw_prod = 2*bw;
  localparam bw_acc  = bw_psum;

  // ---------------------------------------
  // Stage 0 regs
  // ---------------------------------------
  reg signed [bw-1:0] a0_q, a1_q, a2_q, a3_q, a4_q, a5_q, a6_q, a7_q;
  reg signed [bw-1:0] b0_q, b1_q, b2_q, b3_q, b4_q, b5_q, b6_q, b7_q;

  // ---------------------------------------
  // Mult outputs (registered inside mult_8in)
  // ---------------------------------------
  wire signed [bw_prod-1:0] product0, product1, product2, product3;
  wire signed [bw_prod-1:0] product4, product5, product6, product7;

  // Extend to accumulator width
  wire signed [bw_acc-1:0] p0_ext, p1_ext, p2_ext, p3_ext;
  wire signed [bw_acc-1:0] p4_ext, p5_ext, p6_ext, p7_ext;

  // Valid pipeline
  reg vld_s0_q;
  reg vld_s1_q;
  reg vld_s2_q;
  reg vld_s3_q;
  reg vld_s4_q;

  // Mid-CSA pipeline regs
  reg signed [bw_acc-1:0] s4_q;
  reg signed [bw_acc-1:0] c4s_q;
  reg signed [bw_acc-1:0] s5_q;
  reg signed [bw_acc-1:0] c5s_q;

  // Stage regs
  reg signed [bw_acc-1:0] sum_q;
  reg signed [bw_acc-1:0] car_q;

  reg signed [bw_psum-1:0] out_q;
  assign out = out_q;

  // ---------------------------------------
  // Mult instances (enable = vld_s0_q)
  // ---------------------------------------
  mult_8in mult0_inst (.clk(clk), .reset(reset), .en(vld_s0_q), .x(a0_q), .y(b0_q), .p(product0));
  mult_8in mult1_inst (.clk(clk), .reset(reset), .en(vld_s0_q), .x(a1_q), .y(b1_q), .p(product1));
  mult_8in mult2_inst (.clk(clk), .reset(reset), .en(vld_s0_q), .x(a2_q), .y(b2_q), .p(product2));
  mult_8in mult3_inst (.clk(clk), .reset(reset), .en(vld_s0_q), .x(a3_q), .y(b3_q), .p(product3));
  mult_8in mult4_inst (.clk(clk), .reset(reset), .en(vld_s0_q), .x(a4_q), .y(b4_q), .p(product4));
  mult_8in mult5_inst (.clk(clk), .reset(reset), .en(vld_s0_q), .x(a5_q), .y(b5_q), .p(product5));
  mult_8in mult6_inst (.clk(clk), .reset(reset), .en(vld_s0_q), .x(a6_q), .y(b6_q), .p(product6));
  mult_8in mult7_inst (.clk(clk), .reset(reset), .en(vld_s0_q), .x(a7_q), .y(b7_q), .p(product7));

  // ---------------------------------------
  // Sign extend products
  // ---------------------------------------
  assign p0_ext = {{(bw_acc-bw_prod){product0[bw_prod-1]}}, product0};
  assign p1_ext = {{(bw_acc-bw_prod){product1[bw_prod-1]}}, product1};
  assign p2_ext = {{(bw_acc-bw_prod){product2[bw_prod-1]}}, product2};
  assign p3_ext = {{(bw_acc-bw_prod){product3[bw_prod-1]}}, product3};
  assign p4_ext = {{(bw_acc-bw_prod){product4[bw_prod-1]}}, product4};
  assign p5_ext = {{(bw_acc-bw_prod){product5[bw_prod-1]}}, product5};
  assign p6_ext = {{(bw_acc-bw_prod){product6[bw_prod-1]}}, product6};
  assign p7_ext = {{(bw_acc-bw_prod){product7[bw_prod-1]}}, product7};

  // ---------------------------------------
  // CSA compression for 8 operands
  // Split into two pipeline halves
  // ---------------------------------------
  wire [bw_acc-1:0] s0_d, c0_d;
  wire [bw_acc-1:0] s1_d, c1_d;
  wire [bw_acc-1:0] s2_d, c2_d;

  wire [bw_acc-1:0] c0_s, c1_s, c2_s;

  // 3:2 compressors (level 1)
  assign s0_d = p0_ext ^ p1_ext ^ p2_ext;
  assign c0_d = (p0_ext & p1_ext) | (p0_ext & p2_ext) | (p1_ext & p2_ext);

  assign s1_d = p3_ext ^ p4_ext ^ p5_ext;
  assign c1_d = (p3_ext & p4_ext) | (p3_ext & p5_ext) | (p4_ext & p5_ext);

  assign s2_d = p6_ext ^ p7_ext ^ {bw_acc{1'b0}};
  assign c2_d = (p6_ext & p7_ext); // since third term is 0

  // Shift carries
  assign c0_s = {c0_d[bw_acc-2:0], 1'b0};
  assign c1_s = {c1_d[bw_acc-2:0], 1'b0};
  assign c2_s = {c2_d[bw_acc-2:0], 1'b0};

  // Level 2
  wire [bw_acc-1:0] s4_d, c4_d;
  wire [bw_acc-1:0] s5_d, c5_d;
  wire [bw_acc-1:0] c4_s, c5_s;

  assign s4_d = s0_d ^ c0_s ^ s1_d;
  assign c4_d = (s0_d & c0_s) | (s0_d & s1_d) | (c0_s & s1_d);

  assign s5_d = c1_s ^ s2_d ^ c2_s;
  assign c5_d = (c1_s & s2_d) | (c1_s & c2_s) | (s2_d & c2_s);

  assign c4_s = {c4_d[bw_acc-2:0], 1'b0};
  assign c5_s = {c5_d[bw_acc-2:0], 1'b0};

  // ---------------------------------------
  // Final CSA half (after mid-stage regs)
  // ---------------------------------------
  wire [bw_acc-1:0] s6_d, c6_d;
  wire [bw_acc-1:0] c6_s;
  wire [bw_acc-1:0] sum_d;
  wire [bw_acc-1:0] car_d;

  assign s6_d = s4_q ^ c4s_q ^ s5_q;
  assign c6_d = (s4_q & c4s_q) | (s4_q & s5_q) | (c4s_q & s5_q);
  assign c6_s = {c6_d[bw_acc-2:0], 1'b0};

  assign sum_d = s6_d ^ c6_s ^ c5s_q;
  assign car_d = (s6_d & c6_s) | (s6_d & c5s_q) | (c6_s & c5s_q);

  // ---------------------------------------
  // Final add (single CPA only)
  // ---------------------------------------
  wire [bw_acc-1:0] car_s;
  wire [bw_acc-1:0] sum_full_d;

  assign car_s      = {car_q[bw_acc-2:0], 1'b0};
  assign sum_full_d = sum_q + car_s;

  // ---------------------------------------
  // Valid pipeline for stage enables
  // ---------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      vld_s0_q <= 1'b0;
      vld_s1_q <= 1'b0;
      vld_s2_q <= 1'b0;
      vld_s3_q <= 1'b0;
      vld_s4_q <= 1'b0;
    end else begin
      vld_s0_q <= en;
      vld_s1_q <= vld_s0_q;
      vld_s2_q <= vld_s1_q;
      vld_s3_q <= vld_s2_q;
      vld_s4_q <= vld_s3_q;
    end
  end

  // ---------------------------------------
  // Stage 0 register: capture MAC inputs
  // ---------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      a0_q <= 0; a1_q <= 0; a2_q <= 0; a3_q <= 0;
      a4_q <= 0; a5_q <= 0; a6_q <= 0; a7_q <= 0;
      b0_q <= 0; b1_q <= 0; b2_q <= 0; b3_q <= 0;
      b4_q <= 0; b5_q <= 0; b6_q <= 0; b7_q <= 0;
    end else if (en) begin
      a0_q <= $signed(a[bw*1-1:bw*0]);
      a1_q <= $signed(a[bw*2-1:bw*1]);
      a2_q <= $signed(a[bw*3-1:bw*2]);
      a3_q <= $signed(a[bw*4-1:bw*3]);
      a4_q <= $signed(a[bw*5-1:bw*4]);
      a5_q <= $signed(a[bw*6-1:bw*5]);
      a6_q <= $signed(a[bw*7-1:bw*6]);
      a7_q <= $signed(a[bw*8-1:bw*7]);
      b0_q <= $signed(b[bw*1-1:bw*0]);
      b1_q <= $signed(b[bw*2-1:bw*1]);
      b2_q <= $signed(b[bw*3-1:bw*2]);
      b3_q <= $signed(b[bw*4-1:bw*3]);
      b4_q <= $signed(b[bw*5-1:bw*4]);
      b5_q <= $signed(b[bw*6-1:bw*5]);
      b6_q <= $signed(b[bw*7-1:bw*6]);
      b7_q <= $signed(b[bw*8-1:bw*7]);
    end
  end

  // ---------------------------------------
  // Mid-CSA register stage
  // Capture after level-2 CSA
  // ---------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      s4_q  <= 0;
      c4s_q <= 0;
      s5_q  <= 0;
      c5s_q <= 0;
    end else if (vld_s2_q) begin
      s4_q  <= s4_d;
      c4s_q <= c4_s;
      s5_q  <= s5_d;
      c5s_q <= c5_s;
    end
  end

  // ---------------------------------------
  // Next stage register: capture compressed sum/carry
  // ---------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      sum_q <= 0;
      car_q <= 0;
    end else if (vld_s3_q) begin
      sum_q <= sum_d;
      car_q <= car_d;
    end
  end

  // ---------------------------------------
  // Final output register
  // ---------------------------------------
  always @(posedge clk or posedge reset) begin
    if (reset)
      out_q <= {bw_psum{1'b0}};
    else if (vld_s4_q)
      out_q <= sum_full_d;
  end

endmodule