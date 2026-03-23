// Created by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
//
// Shared 16-entry storage block used by both synchronous and CDC FIFOs.
// This module only implements data storage/read mux; pointer/full/empty logic
// must be handled by the parent FIFO controller.
module fifo_storage16 (wr_clk, wr_en, wr_sel, in, rd_sel, out);

  parameter width = 8;

  input wr_clk;
  input wr_en;
  input [3:0] wr_sel;
  input [3:0] rd_sel;
  input [width-1:0] in;
  output [width-1:0] out;

  reg [width-1:0] q0;
  reg [width-1:0] q1;
  reg [width-1:0] q2;
  reg [width-1:0] q3;
  reg [width-1:0] q4;
  reg [width-1:0] q5;
  reg [width-1:0] q6;
  reg [width-1:0] q7;
  reg [width-1:0] q8;
  reg [width-1:0] q9;
  reg [width-1:0] q10;
  reg [width-1:0] q11;
  reg [width-1:0] q12;
  reg [width-1:0] q13;
  reg [width-1:0] q14;
  reg [width-1:0] q15;

  fifo_mux_16_1 #(.bw(width), .simd(1)) storage_mux (
    .in0(q0), .in1(q1), .in2(q2), .in3(q3),
    .in4(q4), .in5(q5), .in6(q6), .in7(q7),
    .in8(q8), .in9(q9), .in10(q10), .in11(q11),
    .in12(q12), .in13(q13), .in14(q14), .in15(q15),
    .sel(rd_sel),
    .out(out)
  );

  always @(posedge wr_clk) begin
    if (wr_en) begin
      case (wr_sel)
        4'h0: q0  <= in;
        4'h1: q1  <= in;
        4'h2: q2  <= in;
        4'h3: q3  <= in;
        4'h4: q4  <= in;
        4'h5: q5  <= in;
        4'h6: q6  <= in;
        4'h7: q7  <= in;
        4'h8: q8  <= in;
        4'h9: q9  <= in;
        4'hA: q10 <= in;
        4'hB: q11 <= in;
        4'hC: q12 <= in;
        4'hD: q13 <= in;
        4'hE: q14 <= in;
        default: q15 <= in;
      endcase
    end
  end

endmodule
