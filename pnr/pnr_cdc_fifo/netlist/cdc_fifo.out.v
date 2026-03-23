/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : K-2015.06-SP2
// Date      : Fri Mar 20 22:04:37 2026
/////////////////////////////////////////////////////////////


module fifo_mux_2_1_bw8_simd1_7 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;
  wire   n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16,
         n17;

  INVD0 U1 ( .I(sel), .ZN(n15) );
  CKND2D0 U2 ( .A1(in0[0]), .A2(n15), .ZN(n8) );
  CKND2D0 U3 ( .A1(in0[1]), .A2(n15), .ZN(n12) );
  CKND2D0 U4 ( .A1(in1[1]), .A2(sel), .ZN(n11) );
  CKND2D0 U5 ( .A1(in0[2]), .A2(n15), .ZN(n6) );
  CKND2D0 U6 ( .A1(in0[3]), .A2(n15), .ZN(n17) );
  CKND2D0 U7 ( .A1(in0[4]), .A2(n15), .ZN(n14) );
  CKND2D0 U8 ( .A1(in0[5]), .A2(n15), .ZN(n4) );
  CKND2D0 U9 ( .A1(in0[6]), .A2(n15), .ZN(n10) );
  CKND2D0 U10 ( .A1(in1[7]), .A2(sel), .ZN(n1) );
  CKND2D0 U11 ( .A1(n8), .A2(n7), .ZN(out[0]) );
  CKND2D0 U12 ( .A1(in1[0]), .A2(sel), .ZN(n7) );
  CKND2D0 U13 ( .A1(n6), .A2(n5), .ZN(out[2]) );
  CKND2D0 U14 ( .A1(in1[2]), .A2(sel), .ZN(n5) );
  CKND2D0 U15 ( .A1(n17), .A2(n16), .ZN(out[3]) );
  CKND2D0 U16 ( .A1(in1[3]), .A2(sel), .ZN(n16) );
  CKND2D0 U17 ( .A1(n14), .A2(n13), .ZN(out[4]) );
  CKND2D0 U18 ( .A1(in1[4]), .A2(sel), .ZN(n13) );
  CKND2D0 U19 ( .A1(n4), .A2(n3), .ZN(out[5]) );
  CKND2D0 U20 ( .A1(in1[5]), .A2(sel), .ZN(n3) );
  CKND2D0 U21 ( .A1(n10), .A2(n9), .ZN(out[6]) );
  CKND2D0 U22 ( .A1(in1[6]), .A2(sel), .ZN(n9) );
  CKND2D0 U23 ( .A1(n2), .A2(n1), .ZN(out[7]) );
  CKND2D0 U24 ( .A1(in0[7]), .A2(n15), .ZN(n2) );
  CKND2D0 U25 ( .A1(n12), .A2(n11), .ZN(out[1]) );
endmodule


module fifo_mux_2_1_bw8_simd1_8 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U2 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
  MUX2D0 U5 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U6 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U7 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U8 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
endmodule


module fifo_mux_2_1_bw8_simd1_9 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
  MUX2D0 U2 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U5 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U6 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U7 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U8 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
endmodule


module fifo_mux_2_1_bw8_simd1_10 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
  MUX2D0 U2 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U5 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U6 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U7 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U8 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
endmodule


module fifo_mux_2_1_bw8_simd1_11 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
  MUX2D0 U2 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U5 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U6 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U7 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U8 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
endmodule


module fifo_mux_2_1_bw8_simd1_12 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
  MUX2D0 U2 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U5 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U6 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U7 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U8 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
endmodule


module fifo_mux_2_1_bw8_simd1_13 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
  MUX2D0 U2 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U5 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U6 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U7 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U8 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
endmodule


module fifo_mux_8_1_bw8_simd1_1 ( out, sel, in0, in1, in2, in3, in4, in5, in6, 
        in7 );
  output [7:0] out;
  input [2:0] sel;
  input [7:0] in0;
  input [7:0] in1;
  input [7:0] in2;
  input [7:0] in3;
  input [7:0] in4;
  input [7:0] in5;
  input [7:0] in6;
  input [7:0] in7;

  wire   [7:0] out_sub0_0;
  wire   [7:0] out_sub0_1;
  wire   [7:0] out_sub0_2;
  wire   [7:0] out_sub0_3;
  wire   [7:0] out_sub1_0;
  wire   [7:0] out_sub1_1;

  fifo_mux_2_1_bw8_simd1_13 fifo_mux_2_1a ( .in0(in0), .in1(in1), .sel(sel[0]), 
        .out(out_sub0_0) );
  fifo_mux_2_1_bw8_simd1_12 fifo_mux_2_1b ( .in0(in2), .in1(in3), .sel(sel[0]), 
        .out(out_sub0_1) );
  fifo_mux_2_1_bw8_simd1_11 fifo_mux_2_1c ( .in0(in4), .in1(in5), .sel(sel[0]), 
        .out(out_sub0_2) );
  fifo_mux_2_1_bw8_simd1_10 fifo_mux_2_1d ( .in0(in6), .in1(in7), .sel(sel[0]), 
        .out(out_sub0_3) );
  fifo_mux_2_1_bw8_simd1_9 fifo_mux_2_1e ( .in0(out_sub0_0), .in1(out_sub0_1), 
        .sel(sel[1]), .out(out_sub1_0) );
  fifo_mux_2_1_bw8_simd1_8 fifo_mux_2_1f ( .in0(out_sub0_2), .in1(out_sub0_3), 
        .sel(sel[1]), .out(out_sub1_1) );
  fifo_mux_2_1_bw8_simd1_7 fifo_mux_2_1g ( .in0(out_sub1_0), .in1(out_sub1_1), 
        .sel(sel[2]), .out(out) );
endmodule


module fifo_mux_2_1_bw8_simd1_14 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;
  wire   n1, n2, n3, n4, n5, n6, n7, n8, n9;

  INVD1 U1 ( .I(sel), .ZN(n9) );
  ND2D1 U2 ( .A1(in1[7]), .A2(sel), .ZN(n1) );
  IOA21D4 U3 ( .A1(in0[7]), .A2(n9), .B(n1), .ZN(out[7]) );
  ND2D1 U4 ( .A1(in1[5]), .A2(sel), .ZN(n2) );
  IOA21D4 U5 ( .A1(in0[5]), .A2(n9), .B(n2), .ZN(out[5]) );
  ND2D1 U6 ( .A1(in1[2]), .A2(sel), .ZN(n3) );
  IOA21D4 U7 ( .A1(in0[2]), .A2(n9), .B(n3), .ZN(out[2]) );
  ND2D1 U8 ( .A1(in1[6]), .A2(sel), .ZN(n4) );
  IOA21D4 U9 ( .A1(in0[6]), .A2(n9), .B(n4), .ZN(out[6]) );
  ND2D1 U10 ( .A1(in1[1]), .A2(sel), .ZN(n5) );
  IOA21D4 U11 ( .A1(in0[1]), .A2(n9), .B(n5), .ZN(out[1]) );
  ND2D1 U12 ( .A1(in1[4]), .A2(sel), .ZN(n6) );
  IOA21D4 U13 ( .A1(in0[4]), .A2(n9), .B(n6), .ZN(out[4]) );
  ND2D1 U14 ( .A1(in1[3]), .A2(sel), .ZN(n7) );
  IOA21D4 U15 ( .A1(in0[3]), .A2(n9), .B(n7), .ZN(out[3]) );
  ND2D1 U16 ( .A1(in1[0]), .A2(sel), .ZN(n8) );
  IOA21D4 U17 ( .A1(in0[0]), .A2(n9), .B(n8), .ZN(out[0]) );
endmodule


module fifo_mux_2_1_bw8_simd1_0 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;
  wire   n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15, n16,
         n17;

  INVD0 U1 ( .I(sel), .ZN(n15) );
  CKND2D0 U2 ( .A1(in0[0]), .A2(n15), .ZN(n8) );
  CKND2D0 U3 ( .A1(in1[1]), .A2(sel), .ZN(n11) );
  CKND2D0 U4 ( .A1(in0[1]), .A2(n15), .ZN(n12) );
  CKND2D0 U5 ( .A1(n6), .A2(n5), .ZN(out[2]) );
  CKND2D0 U6 ( .A1(in0[2]), .A2(n15), .ZN(n6) );
  CKND2D0 U7 ( .A1(in0[3]), .A2(n15), .ZN(n17) );
  CKND2D0 U8 ( .A1(in1[3]), .A2(sel), .ZN(n16) );
  CKND2D0 U9 ( .A1(n14), .A2(n13), .ZN(out[4]) );
  CKND2D0 U10 ( .A1(in0[4]), .A2(n15), .ZN(n14) );
  CKND2D0 U11 ( .A1(in1[4]), .A2(sel), .ZN(n13) );
  CKND2D0 U12 ( .A1(n4), .A2(n3), .ZN(out[5]) );
  CKND2D0 U13 ( .A1(in0[5]), .A2(n15), .ZN(n4) );
  CKND2D0 U14 ( .A1(in1[5]), .A2(sel), .ZN(n3) );
  CKND2D0 U15 ( .A1(n10), .A2(n9), .ZN(out[6]) );
  CKND2D0 U16 ( .A1(in0[6]), .A2(n15), .ZN(n10) );
  CKND2D0 U17 ( .A1(in1[6]), .A2(sel), .ZN(n9) );
  CKND2D0 U18 ( .A1(n2), .A2(n1), .ZN(out[7]) );
  CKND2D0 U19 ( .A1(in0[7]), .A2(n15), .ZN(n2) );
  CKND2D0 U20 ( .A1(in1[7]), .A2(sel), .ZN(n1) );
  CKND2D0 U21 ( .A1(n12), .A2(n11), .ZN(out[1]) );
  CKND2D0 U22 ( .A1(in1[0]), .A2(sel), .ZN(n7) );
  CKND2D0 U23 ( .A1(in1[2]), .A2(sel), .ZN(n5) );
  CKND2D0 U24 ( .A1(n8), .A2(n7), .ZN(out[0]) );
  CKND2D0 U25 ( .A1(n17), .A2(n16), .ZN(out[3]) );
endmodule


module fifo_mux_2_1_bw8_simd1_1 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U2 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U5 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U6 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U7 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U8 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
endmodule


module fifo_mux_2_1_bw8_simd1_2 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
  MUX2D0 U2 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U5 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U6 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U7 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U8 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
endmodule


module fifo_mux_2_1_bw8_simd1_3 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
  MUX2D0 U2 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U5 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U6 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U7 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U8 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
endmodule


module fifo_mux_2_1_bw8_simd1_4 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
  MUX2D0 U2 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U5 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U6 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U7 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U8 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
endmodule


module fifo_mux_2_1_bw8_simd1_5 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
  MUX2D0 U2 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U5 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U6 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U7 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U8 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
endmodule


module fifo_mux_2_1_bw8_simd1_6 ( in0, in1, sel, out );
  input [7:0] in0;
  input [7:0] in1;
  output [7:0] out;
  input sel;


  MUX2D0 U1 ( .I0(in0[7]), .I1(in1[7]), .S(sel), .Z(out[7]) );
  MUX2D0 U2 ( .I0(in0[5]), .I1(in1[5]), .S(sel), .Z(out[5]) );
  MUX2D0 U3 ( .I0(in0[2]), .I1(in1[2]), .S(sel), .Z(out[2]) );
  MUX2D0 U4 ( .I0(in0[0]), .I1(in1[0]), .S(sel), .Z(out[0]) );
  MUX2D0 U5 ( .I0(in0[6]), .I1(in1[6]), .S(sel), .Z(out[6]) );
  MUX2D0 U6 ( .I0(in0[1]), .I1(in1[1]), .S(sel), .Z(out[1]) );
  MUX2D0 U7 ( .I0(in0[4]), .I1(in1[4]), .S(sel), .Z(out[4]) );
  MUX2D0 U8 ( .I0(in0[3]), .I1(in1[3]), .S(sel), .Z(out[3]) );
endmodule


module fifo_mux_8_1_bw8_simd1_0 ( out, sel, in0, in1, in2, in3, in4, in5, in6, 
        in7 );
  output [7:0] out;
  input [2:0] sel;
  input [7:0] in0;
  input [7:0] in1;
  input [7:0] in2;
  input [7:0] in3;
  input [7:0] in4;
  input [7:0] in5;
  input [7:0] in6;
  input [7:0] in7;

  wire   [7:0] out_sub0_0;
  wire   [7:0] out_sub0_1;
  wire   [7:0] out_sub0_2;
  wire   [7:0] out_sub0_3;
  wire   [7:0] out_sub1_0;
  wire   [7:0] out_sub1_1;

  fifo_mux_2_1_bw8_simd1_6 fifo_mux_2_1a ( .in0(in0), .in1(in1), .sel(sel[0]), 
        .out(out_sub0_0) );
  fifo_mux_2_1_bw8_simd1_5 fifo_mux_2_1b ( .in0(in2), .in1(in3), .sel(sel[0]), 
        .out(out_sub0_1) );
  fifo_mux_2_1_bw8_simd1_4 fifo_mux_2_1c ( .in0(in4), .in1(in5), .sel(sel[0]), 
        .out(out_sub0_2) );
  fifo_mux_2_1_bw8_simd1_3 fifo_mux_2_1d ( .in0(in6), .in1(in7), .sel(sel[0]), 
        .out(out_sub0_3) );
  fifo_mux_2_1_bw8_simd1_2 fifo_mux_2_1e ( .in0(out_sub0_0), .in1(out_sub0_1), 
        .sel(sel[1]), .out(out_sub1_0) );
  fifo_mux_2_1_bw8_simd1_1 fifo_mux_2_1f ( .in0(out_sub0_2), .in1(out_sub0_3), 
        .sel(sel[1]), .out(out_sub1_1) );
  fifo_mux_2_1_bw8_simd1_0 fifo_mux_2_1g ( .in0(out_sub1_0), .in1(out_sub1_1), 
        .sel(sel[2]), .out(out) );
endmodule


module fifo_mux_16_1_bw8_simd1 ( out, sel, in0, in1, in2, in3, in4, in5, in6, 
        in7, in8, in9, in10, in11, in12, in13, in14, in15 );
  output [7:0] out;
  input [3:0] sel;
  input [7:0] in0;
  input [7:0] in1;
  input [7:0] in2;
  input [7:0] in3;
  input [7:0] in4;
  input [7:0] in5;
  input [7:0] in6;
  input [7:0] in7;
  input [7:0] in8;
  input [7:0] in9;
  input [7:0] in10;
  input [7:0] in11;
  input [7:0] in12;
  input [7:0] in13;
  input [7:0] in14;
  input [7:0] in15;
  wire   n1;
  wire   [7:0] out_sub0;
  wire   [7:0] out_sub1;

  fifo_mux_8_1_bw8_simd1_1 mux_8_1a ( .out(out_sub0), .sel({sel[2:1], n1}), 
        .in0(in0), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .in5(in5), 
        .in6(in6), .in7(in7) );
  fifo_mux_8_1_bw8_simd1_0 mux_8_1b ( .out(out_sub1), .sel({sel[2:1], n1}), 
        .in0(in8), .in1(in9), .in2(in10), .in3(in11), .in4(in12), .in5(in13), 
        .in6(in14), .in7(in15) );
  fifo_mux_2_1_bw8_simd1_14 mux_2_1a ( .in0(out_sub0), .in1(out_sub1), .sel(
        sel[3]), .out(out) );
  BUFFD16 U1 ( .I(sel[0]), .Z(n1) );
endmodule


module fifo_storage16_width8 ( wr_clk, wr_en, wr_sel, in, rd_sel, out );
  input [3:0] wr_sel;
  input [7:0] in;
  input [3:0] rd_sel;
  output [7:0] out;
  input wr_clk, wr_en;
  wire   n4, n8, n11, n14, n16, n41, n42, n43, n44, n45, n46, n47, n48, n49,
         n50, n51, n52, n53, n54, n55, n56, n57, n58, n59, n60, n61, n62, n63,
         n64, n65, n66, n67, n68, n69, n70, n71, n72, n73, n74, n75, n76, n77,
         n78, n79, n80, n81, n82, n83, n84, n85, n86, n87, n88, n89, n90, n91,
         n92, n93, n94, n95, n96, n97, n98, n99, n100, n101, n102, n103, n104,
         n105, n106, n107, n108, n109, n110, n111, n112, n113, n114, n115,
         n116, n117, n118, n119, n120, n121, n122, n123, n124, n125, n126,
         n127, n128, n129, n130, n1, n2, n3, n5, n6, n7, n9, n10, n12, n13,
         n15, n17, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29,
         n30, n31, n32;
  wire   [7:0] q0;
  wire   [7:0] q1;
  wire   [7:0] q2;
  wire   [7:0] q3;
  wire   [7:0] q4;
  wire   [7:0] q5;
  wire   [7:0] q6;
  wire   [7:0] q7;
  wire   [7:0] q8;
  wire   [7:0] q9;
  wire   [7:0] q10;
  wire   [7:0] q11;
  wire   [7:0] q12;
  wire   [7:0] q13;
  wire   [7:0] q14;
  wire   [7:0] q15;

  fifo_mux_16_1_bw8_simd1 storage_mux ( .out(out), .sel(rd_sel), .in0(q0), 
        .in1(q1), .in2(q2), .in3(q3), .in4(q4), .in5(q5), .in6(q6), .in7(q7), 
        .in8(q8), .in9(q9), .in10(q10), .in11(q11), .in12(q12), .in13(q13), 
        .in14(q14), .in15(q15) );
  DFQD1 q13_reg_7_ ( .D(n130), .CP(wr_clk), .Q(q13[7]) );
  DFQD1 q13_reg_6_ ( .D(n129), .CP(wr_clk), .Q(q13[6]) );
  DFQD1 q13_reg_5_ ( .D(n128), .CP(wr_clk), .Q(q13[5]) );
  DFQD1 q13_reg_4_ ( .D(n127), .CP(wr_clk), .Q(q13[4]) );
  DFQD1 q13_reg_3_ ( .D(n126), .CP(wr_clk), .Q(q13[3]) );
  DFQD1 q13_reg_2_ ( .D(n125), .CP(wr_clk), .Q(q13[2]) );
  DFQD1 q13_reg_1_ ( .D(n124), .CP(wr_clk), .Q(q13[1]) );
  DFQD1 q13_reg_0_ ( .D(n123), .CP(wr_clk), .Q(q13[0]) );
  DFQD1 q12_reg_7_ ( .D(n122), .CP(wr_clk), .Q(q12[7]) );
  DFQD1 q12_reg_6_ ( .D(n121), .CP(wr_clk), .Q(q12[6]) );
  DFQD1 q12_reg_5_ ( .D(n120), .CP(wr_clk), .Q(q12[5]) );
  DFQD1 q12_reg_4_ ( .D(n119), .CP(wr_clk), .Q(q12[4]) );
  DFQD1 q12_reg_3_ ( .D(n118), .CP(wr_clk), .Q(q12[3]) );
  DFQD1 q12_reg_2_ ( .D(n117), .CP(wr_clk), .Q(q12[2]) );
  DFQD1 q12_reg_1_ ( .D(n116), .CP(wr_clk), .Q(q12[1]) );
  DFQD1 q12_reg_0_ ( .D(n115), .CP(wr_clk), .Q(q12[0]) );
  DFQD1 q11_reg_7_ ( .D(n114), .CP(wr_clk), .Q(q11[7]) );
  DFQD1 q11_reg_6_ ( .D(n113), .CP(wr_clk), .Q(q11[6]) );
  DFQD1 q11_reg_5_ ( .D(n112), .CP(wr_clk), .Q(q11[5]) );
  DFQD1 q11_reg_4_ ( .D(n111), .CP(wr_clk), .Q(q11[4]) );
  DFQD1 q11_reg_3_ ( .D(n110), .CP(wr_clk), .Q(q11[3]) );
  DFQD1 q11_reg_2_ ( .D(n109), .CP(wr_clk), .Q(q11[2]) );
  DFQD1 q11_reg_1_ ( .D(n108), .CP(wr_clk), .Q(q11[1]) );
  DFQD1 q11_reg_0_ ( .D(n107), .CP(wr_clk), .Q(q11[0]) );
  DFQD1 q14_reg_7_ ( .D(n106), .CP(wr_clk), .Q(q14[7]) );
  DFQD1 q14_reg_6_ ( .D(n105), .CP(wr_clk), .Q(q14[6]) );
  DFQD1 q14_reg_5_ ( .D(n104), .CP(wr_clk), .Q(q14[5]) );
  DFQD1 q14_reg_4_ ( .D(n103), .CP(wr_clk), .Q(q14[4]) );
  DFQD1 q14_reg_3_ ( .D(n102), .CP(wr_clk), .Q(q14[3]) );
  DFQD1 q14_reg_2_ ( .D(n101), .CP(wr_clk), .Q(q14[2]) );
  DFQD1 q14_reg_1_ ( .D(n100), .CP(wr_clk), .Q(q14[1]) );
  DFQD1 q14_reg_0_ ( .D(n99), .CP(wr_clk), .Q(q14[0]) );
  EDFQD1 q15_reg_7_ ( .D(in[7]), .E(n29), .CP(wr_clk), .Q(q15[7]) );
  EDFQD1 q15_reg_6_ ( .D(in[6]), .E(n29), .CP(wr_clk), .Q(q15[6]) );
  EDFQD1 q15_reg_5_ ( .D(in[5]), .E(n29), .CP(wr_clk), .Q(q15[5]) );
  EDFQD1 q15_reg_4_ ( .D(in[4]), .E(n29), .CP(wr_clk), .Q(q15[4]) );
  EDFQD1 q15_reg_3_ ( .D(in[3]), .E(n29), .CP(wr_clk), .Q(q15[3]) );
  EDFQD1 q15_reg_2_ ( .D(in[2]), .E(n29), .CP(wr_clk), .Q(q15[2]) );
  EDFQD1 q15_reg_1_ ( .D(in[1]), .E(n29), .CP(wr_clk), .Q(q15[1]) );
  EDFQD1 q15_reg_0_ ( .D(in[0]), .E(n29), .CP(wr_clk), .Q(q15[0]) );
  EDFQD1 q0_reg_7_ ( .D(in[7]), .E(n32), .CP(wr_clk), .Q(q0[7]) );
  EDFQD1 q0_reg_6_ ( .D(in[6]), .E(n32), .CP(wr_clk), .Q(q0[6]) );
  EDFQD1 q0_reg_5_ ( .D(in[5]), .E(n32), .CP(wr_clk), .Q(q0[5]) );
  EDFQD1 q0_reg_4_ ( .D(in[4]), .E(n32), .CP(wr_clk), .Q(q0[4]) );
  EDFQD1 q0_reg_3_ ( .D(in[3]), .E(n32), .CP(wr_clk), .Q(q0[3]) );
  EDFQD1 q0_reg_2_ ( .D(in[2]), .E(n32), .CP(wr_clk), .Q(q0[2]) );
  EDFQD1 q0_reg_1_ ( .D(in[1]), .E(n32), .CP(wr_clk), .Q(q0[1]) );
  EDFQD1 q0_reg_0_ ( .D(in[0]), .E(n32), .CP(wr_clk), .Q(q0[0]) );
  EDFQD1 q1_reg_7_ ( .D(in[7]), .E(n31), .CP(wr_clk), .Q(q1[7]) );
  EDFQD1 q1_reg_6_ ( .D(in[6]), .E(n31), .CP(wr_clk), .Q(q1[6]) );
  EDFQD1 q1_reg_5_ ( .D(in[5]), .E(n31), .CP(wr_clk), .Q(q1[5]) );
  EDFQD1 q1_reg_4_ ( .D(in[4]), .E(n31), .CP(wr_clk), .Q(q1[4]) );
  EDFQD1 q1_reg_3_ ( .D(in[3]), .E(n31), .CP(wr_clk), .Q(q1[3]) );
  EDFQD1 q1_reg_2_ ( .D(in[2]), .E(n31), .CP(wr_clk), .Q(q1[2]) );
  EDFQD1 q1_reg_1_ ( .D(in[1]), .E(n31), .CP(wr_clk), .Q(q1[1]) );
  EDFQD1 q1_reg_0_ ( .D(in[0]), .E(n31), .CP(wr_clk), .Q(q1[0]) );
  DFQD1 q2_reg_7_ ( .D(n98), .CP(wr_clk), .Q(q2[7]) );
  DFQD1 q2_reg_6_ ( .D(n97), .CP(wr_clk), .Q(q2[6]) );
  DFQD1 q2_reg_5_ ( .D(n96), .CP(wr_clk), .Q(q2[5]) );
  DFQD1 q2_reg_4_ ( .D(n95), .CP(wr_clk), .Q(q2[4]) );
  DFQD1 q2_reg_3_ ( .D(n94), .CP(wr_clk), .Q(q2[3]) );
  DFQD1 q2_reg_2_ ( .D(n93), .CP(wr_clk), .Q(q2[2]) );
  DFQD1 q2_reg_1_ ( .D(n92), .CP(wr_clk), .Q(q2[1]) );
  DFQD1 q2_reg_0_ ( .D(n91), .CP(wr_clk), .Q(q2[0]) );
  DFQD1 q3_reg_7_ ( .D(n90), .CP(wr_clk), .Q(q3[7]) );
  DFQD1 q3_reg_6_ ( .D(n89), .CP(wr_clk), .Q(q3[6]) );
  DFQD1 q3_reg_5_ ( .D(n88), .CP(wr_clk), .Q(q3[5]) );
  DFQD1 q3_reg_4_ ( .D(n87), .CP(wr_clk), .Q(q3[4]) );
  DFQD1 q3_reg_3_ ( .D(n86), .CP(wr_clk), .Q(q3[3]) );
  DFQD1 q3_reg_2_ ( .D(n85), .CP(wr_clk), .Q(q3[2]) );
  DFQD1 q3_reg_1_ ( .D(n84), .CP(wr_clk), .Q(q3[1]) );
  DFQD1 q3_reg_0_ ( .D(n83), .CP(wr_clk), .Q(q3[0]) );
  DFQD1 q4_reg_7_ ( .D(n82), .CP(wr_clk), .Q(q4[7]) );
  DFQD1 q4_reg_6_ ( .D(n81), .CP(wr_clk), .Q(q4[6]) );
  DFQD1 q4_reg_5_ ( .D(n80), .CP(wr_clk), .Q(q4[5]) );
  DFQD1 q4_reg_4_ ( .D(n79), .CP(wr_clk), .Q(q4[4]) );
  DFQD1 q4_reg_3_ ( .D(n78), .CP(wr_clk), .Q(q4[3]) );
  DFQD1 q4_reg_2_ ( .D(n77), .CP(wr_clk), .Q(q4[2]) );
  DFQD1 q4_reg_1_ ( .D(n76), .CP(wr_clk), .Q(q4[1]) );
  EDFQD1 q4_reg_0_ ( .D(in[0]), .E(n16), .CP(wr_clk), .Q(q4[0]) );
  DFQD1 q5_reg_7_ ( .D(n75), .CP(wr_clk), .Q(q5[7]) );
  DFQD1 q5_reg_6_ ( .D(n74), .CP(wr_clk), .Q(q5[6]) );
  DFQD1 q5_reg_5_ ( .D(n73), .CP(wr_clk), .Q(q5[5]) );
  DFQD1 q5_reg_4_ ( .D(n72), .CP(wr_clk), .Q(q5[4]) );
  DFQD1 q5_reg_3_ ( .D(n71), .CP(wr_clk), .Q(q5[3]) );
  DFQD1 q5_reg_2_ ( .D(n70), .CP(wr_clk), .Q(q5[2]) );
  DFQD1 q5_reg_1_ ( .D(n69), .CP(wr_clk), .Q(q5[1]) );
  EDFQD1 q5_reg_0_ ( .D(in[0]), .E(n14), .CP(wr_clk), .Q(q5[0]) );
  DFQD1 q6_reg_7_ ( .D(n68), .CP(wr_clk), .Q(q6[7]) );
  DFQD1 q6_reg_6_ ( .D(n67), .CP(wr_clk), .Q(q6[6]) );
  DFQD1 q6_reg_5_ ( .D(n66), .CP(wr_clk), .Q(q6[5]) );
  DFQD1 q6_reg_4_ ( .D(n65), .CP(wr_clk), .Q(q6[4]) );
  DFQD1 q6_reg_3_ ( .D(n64), .CP(wr_clk), .Q(q6[3]) );
  DFQD1 q6_reg_2_ ( .D(n63), .CP(wr_clk), .Q(q6[2]) );
  DFQD1 q6_reg_1_ ( .D(n62), .CP(wr_clk), .Q(q6[1]) );
  EDFQD1 q6_reg_0_ ( .D(in[0]), .E(n11), .CP(wr_clk), .Q(q6[0]) );
  DFQD1 q7_reg_7_ ( .D(n61), .CP(wr_clk), .Q(q7[7]) );
  DFQD1 q7_reg_6_ ( .D(n60), .CP(wr_clk), .Q(q7[6]) );
  DFQD1 q7_reg_5_ ( .D(n59), .CP(wr_clk), .Q(q7[5]) );
  DFQD1 q7_reg_4_ ( .D(n58), .CP(wr_clk), .Q(q7[4]) );
  DFQD1 q7_reg_3_ ( .D(n57), .CP(wr_clk), .Q(q7[3]) );
  DFQD1 q7_reg_2_ ( .D(n56), .CP(wr_clk), .Q(q7[2]) );
  DFQD1 q7_reg_1_ ( .D(n55), .CP(wr_clk), .Q(q7[1]) );
  EDFQD1 q7_reg_0_ ( .D(in[0]), .E(n8), .CP(wr_clk), .Q(q7[0]) );
  EDFQD1 q8_reg_7_ ( .D(in[7]), .E(n30), .CP(wr_clk), .Q(q8[7]) );
  EDFQD1 q8_reg_6_ ( .D(in[6]), .E(n30), .CP(wr_clk), .Q(q8[6]) );
  EDFQD1 q8_reg_5_ ( .D(in[5]), .E(n30), .CP(wr_clk), .Q(q8[5]) );
  EDFQD1 q8_reg_4_ ( .D(in[4]), .E(n30), .CP(wr_clk), .Q(q8[4]) );
  EDFQD1 q8_reg_3_ ( .D(in[3]), .E(n30), .CP(wr_clk), .Q(q8[3]) );
  EDFQD1 q8_reg_2_ ( .D(in[2]), .E(n30), .CP(wr_clk), .Q(q8[2]) );
  EDFQD1 q8_reg_1_ ( .D(in[1]), .E(n30), .CP(wr_clk), .Q(q8[1]) );
  EDFQD1 q8_reg_0_ ( .D(in[0]), .E(n30), .CP(wr_clk), .Q(q8[0]) );
  DFQD1 q9_reg_7_ ( .D(n54), .CP(wr_clk), .Q(q9[7]) );
  DFQD1 q9_reg_6_ ( .D(n53), .CP(wr_clk), .Q(q9[6]) );
  DFQD1 q9_reg_5_ ( .D(n52), .CP(wr_clk), .Q(q9[5]) );
  DFQD1 q9_reg_4_ ( .D(n51), .CP(wr_clk), .Q(q9[4]) );
  DFQD1 q9_reg_3_ ( .D(n50), .CP(wr_clk), .Q(q9[3]) );
  DFQD1 q9_reg_2_ ( .D(n49), .CP(wr_clk), .Q(q9[2]) );
  DFQD1 q9_reg_1_ ( .D(n48), .CP(wr_clk), .Q(q9[1]) );
  EDFQD1 q9_reg_0_ ( .D(in[0]), .E(n4), .CP(wr_clk), .Q(q9[0]) );
  DFQD1 q10_reg_7_ ( .D(n47), .CP(wr_clk), .Q(q10[7]) );
  DFQD1 q10_reg_6_ ( .D(n46), .CP(wr_clk), .Q(q10[6]) );
  DFQD1 q10_reg_5_ ( .D(n45), .CP(wr_clk), .Q(q10[5]) );
  DFQD1 q10_reg_4_ ( .D(n44), .CP(wr_clk), .Q(q10[4]) );
  DFQD1 q10_reg_3_ ( .D(n43), .CP(wr_clk), .Q(q10[3]) );
  DFQD1 q10_reg_2_ ( .D(n42), .CP(wr_clk), .Q(q10[2]) );
  DFQD1 q10_reg_1_ ( .D(n41), .CP(wr_clk), .Q(q10[1]) );
  EDFQD1 q10_reg_0_ ( .D(in[0]), .E(n28), .CP(wr_clk), .Q(q10[0]) );
  MUX2D0 U3 ( .I0(q11[0]), .I1(in[0]), .S(n13), .Z(n107) );
  NR2XD1 U4 ( .A1(n19), .A2(n21), .ZN(n20) );
  NR2XD1 U5 ( .A1(n15), .A2(n24), .ZN(n17) );
  NR2D3 U6 ( .A1(n25), .A2(n21), .ZN(n28) );
  NR2D4 U7 ( .A1(n25), .A2(n18), .ZN(n27) );
  INVD2 U8 ( .I(wr_en), .ZN(n3) );
  MUX2D0 U9 ( .I0(q14[1]), .I1(in[1]), .S(n27), .Z(n100) );
  MUX2D0 U10 ( .I0(q11[6]), .I1(in[6]), .S(n13), .Z(n113) );
  NR2D3 U11 ( .A1(n15), .A2(n1), .ZN(n4) );
  NR2D4 U12 ( .A1(n3), .A2(n2), .ZN(n10) );
  ND2D3 U13 ( .A1(n10), .A2(wr_sel[0]), .ZN(n15) );
  CKMUX2D1 U14 ( .I0(q11[7]), .I1(in[7]), .S(n13), .Z(n114) );
  CKMUX2D1 U15 ( .I0(q11[5]), .I1(in[5]), .S(n13), .Z(n112) );
  CKMUX2D1 U16 ( .I0(q11[4]), .I1(in[4]), .S(n13), .Z(n111) );
  CKMUX2D1 U17 ( .I0(q11[3]), .I1(in[3]), .S(n13), .Z(n110) );
  CKMUX2D1 U18 ( .I0(q11[2]), .I1(in[2]), .S(n13), .Z(n109) );
  CKMUX2D1 U19 ( .I0(q11[1]), .I1(in[1]), .S(n13), .Z(n108) );
  NR2XD3 U20 ( .A1(n25), .A2(n24), .ZN(n26) );
  INVD0 U21 ( .I(wr_sel[0]), .ZN(n9) );
  INVD0 U22 ( .I(wr_sel[3]), .ZN(n2) );
  CKND2D0 U23 ( .A1(n12), .A2(wr_sel[1]), .ZN(n21) );
  INVD0 U24 ( .I(wr_sel[2]), .ZN(n12) );
  ND2D2 U25 ( .A1(n10), .A2(n9), .ZN(n25) );
  CKND2D0 U26 ( .A1(n5), .A2(wr_sel[2]), .ZN(n24) );
  INVD0 U27 ( .I(wr_sel[1]), .ZN(n5) );
  OR2D0 U28 ( .A1(wr_sel[2]), .A2(wr_sel[1]), .Z(n1) );
  CKND2D0 U29 ( .A1(wr_sel[2]), .A2(wr_sel[1]), .ZN(n18) );
  NR2D2 U30 ( .A1(n15), .A2(n21), .ZN(n13) );
  MUX2D0 U31 ( .I0(q9[1]), .I1(in[1]), .S(n4), .Z(n48) );
  MUX2D0 U32 ( .I0(q9[2]), .I1(in[2]), .S(n4), .Z(n49) );
  MUX2D0 U33 ( .I0(q9[3]), .I1(in[3]), .S(n4), .Z(n50) );
  MUX2D0 U34 ( .I0(q9[4]), .I1(in[4]), .S(n4), .Z(n51) );
  MUX2D0 U35 ( .I0(q9[5]), .I1(in[5]), .S(n4), .Z(n52) );
  MUX2D0 U36 ( .I0(q9[6]), .I1(in[6]), .S(n4), .Z(n53) );
  NR2D2 U37 ( .A1(n25), .A2(n1), .ZN(n30) );
  MUX2D0 U38 ( .I0(q7[1]), .I1(in[1]), .S(n8), .Z(n55) );
  MUX2D0 U39 ( .I0(q7[2]), .I1(in[2]), .S(n8), .Z(n56) );
  MUX2D0 U40 ( .I0(q7[3]), .I1(in[3]), .S(n8), .Z(n57) );
  MUX2D0 U41 ( .I0(q7[4]), .I1(in[4]), .S(n8), .Z(n58) );
  MUX2D0 U42 ( .I0(q7[5]), .I1(in[5]), .S(n8), .Z(n59) );
  MUX2D0 U43 ( .I0(q7[6]), .I1(in[6]), .S(n8), .Z(n60) );
  MUX2D0 U44 ( .I0(q7[7]), .I1(in[7]), .S(n8), .Z(n61) );
  MUX2D0 U45 ( .I0(q6[1]), .I1(in[1]), .S(n11), .Z(n62) );
  MUX2D0 U46 ( .I0(q6[2]), .I1(in[2]), .S(n11), .Z(n63) );
  MUX2D0 U47 ( .I0(q6[3]), .I1(in[3]), .S(n11), .Z(n64) );
  MUX2D0 U48 ( .I0(q6[4]), .I1(in[4]), .S(n11), .Z(n65) );
  MUX2D0 U49 ( .I0(q6[6]), .I1(in[6]), .S(n11), .Z(n67) );
  MUX2D0 U50 ( .I0(q6[7]), .I1(in[7]), .S(n11), .Z(n68) );
  MUX2D0 U51 ( .I0(q5[1]), .I1(in[1]), .S(n14), .Z(n69) );
  MUX2D0 U52 ( .I0(q5[2]), .I1(in[2]), .S(n14), .Z(n70) );
  MUX2D0 U53 ( .I0(q5[3]), .I1(in[3]), .S(n14), .Z(n71) );
  MUX2D0 U54 ( .I0(q5[4]), .I1(in[4]), .S(n14), .Z(n72) );
  MUX2D0 U55 ( .I0(q5[5]), .I1(in[5]), .S(n14), .Z(n73) );
  MUX2D0 U56 ( .I0(q5[6]), .I1(in[6]), .S(n14), .Z(n74) );
  MUX2D0 U57 ( .I0(q5[7]), .I1(in[7]), .S(n14), .Z(n75) );
  MUX2D0 U58 ( .I0(q4[1]), .I1(in[1]), .S(n16), .Z(n76) );
  MUX2D0 U59 ( .I0(q4[2]), .I1(in[2]), .S(n16), .Z(n77) );
  MUX2D0 U60 ( .I0(q4[3]), .I1(in[3]), .S(n16), .Z(n78) );
  MUX2D0 U61 ( .I0(q4[5]), .I1(in[5]), .S(n16), .Z(n80) );
  MUX2D0 U62 ( .I0(q4[6]), .I1(in[6]), .S(n16), .Z(n81) );
  MUX2D0 U63 ( .I0(q4[7]), .I1(in[7]), .S(n16), .Z(n82) );
  MUX2D0 U64 ( .I0(q3[0]), .I1(in[0]), .S(n20), .Z(n83) );
  MUX2D0 U65 ( .I0(q3[1]), .I1(in[1]), .S(n20), .Z(n84) );
  MUX2D0 U66 ( .I0(q3[2]), .I1(in[2]), .S(n20), .Z(n85) );
  MUX2D0 U67 ( .I0(q3[3]), .I1(in[3]), .S(n20), .Z(n86) );
  MUX2D0 U68 ( .I0(q3[4]), .I1(in[4]), .S(n20), .Z(n87) );
  MUX2D0 U69 ( .I0(q3[5]), .I1(in[5]), .S(n20), .Z(n88) );
  MUX2D0 U70 ( .I0(q3[6]), .I1(in[6]), .S(n20), .Z(n89) );
  MUX2D0 U71 ( .I0(q3[7]), .I1(in[7]), .S(n20), .Z(n90) );
  MUX2D0 U72 ( .I0(q2[0]), .I1(in[0]), .S(n23), .Z(n91) );
  MUX2D0 U73 ( .I0(q2[1]), .I1(in[1]), .S(n23), .Z(n92) );
  MUX2D0 U74 ( .I0(q2[2]), .I1(in[2]), .S(n23), .Z(n93) );
  MUX2D0 U75 ( .I0(q2[4]), .I1(in[4]), .S(n23), .Z(n95) );
  MUX2D0 U76 ( .I0(q2[5]), .I1(in[5]), .S(n23), .Z(n96) );
  MUX2D0 U77 ( .I0(q2[6]), .I1(in[6]), .S(n23), .Z(n97) );
  MUX2D0 U78 ( .I0(q2[7]), .I1(in[7]), .S(n23), .Z(n98) );
  NR2D2 U79 ( .A1(n15), .A2(n18), .ZN(n29) );
  MUX2D0 U80 ( .I0(q14[2]), .I1(in[2]), .S(n27), .Z(n101) );
  MUX2D0 U81 ( .I0(q14[3]), .I1(in[3]), .S(n27), .Z(n102) );
  MUX2D0 U82 ( .I0(q14[4]), .I1(in[4]), .S(n27), .Z(n103) );
  MUX2D0 U83 ( .I0(q14[5]), .I1(in[5]), .S(n27), .Z(n104) );
  MUX2D0 U84 ( .I0(q14[6]), .I1(in[6]), .S(n27), .Z(n105) );
  MUX2D0 U85 ( .I0(q14[7]), .I1(in[7]), .S(n27), .Z(n106) );
  MUX2D0 U86 ( .I0(q12[0]), .I1(in[0]), .S(n26), .Z(n115) );
  MUX2D0 U87 ( .I0(q12[1]), .I1(in[1]), .S(n26), .Z(n116) );
  MUX2D0 U88 ( .I0(q12[2]), .I1(in[2]), .S(n26), .Z(n117) );
  MUX2D0 U89 ( .I0(q12[3]), .I1(in[3]), .S(n26), .Z(n118) );
  MUX2D0 U90 ( .I0(q12[4]), .I1(in[4]), .S(n26), .Z(n119) );
  MUX2D0 U91 ( .I0(q12[5]), .I1(in[5]), .S(n26), .Z(n120) );
  MUX2D0 U92 ( .I0(q12[6]), .I1(in[6]), .S(n26), .Z(n121) );
  MUX2D0 U93 ( .I0(q12[7]), .I1(in[7]), .S(n26), .Z(n122) );
  MUX2D0 U94 ( .I0(q13[0]), .I1(in[0]), .S(n17), .Z(n123) );
  MUX2D0 U95 ( .I0(q13[1]), .I1(in[1]), .S(n17), .Z(n124) );
  MUX2D0 U96 ( .I0(q13[2]), .I1(in[2]), .S(n17), .Z(n125) );
  MUX2D0 U97 ( .I0(q13[3]), .I1(in[3]), .S(n17), .Z(n126) );
  MUX2D0 U98 ( .I0(q13[4]), .I1(in[4]), .S(n17), .Z(n127) );
  MUX2D0 U99 ( .I0(q13[6]), .I1(in[6]), .S(n17), .Z(n129) );
  MUX2D0 U100 ( .I0(q13[7]), .I1(in[7]), .S(n17), .Z(n130) );
  MUX2D0 U101 ( .I0(q9[7]), .I1(in[7]), .S(n4), .Z(n54) );
  MUX2D0 U102 ( .I0(q6[5]), .I1(in[5]), .S(n11), .Z(n66) );
  MUX2D0 U103 ( .I0(q4[4]), .I1(in[4]), .S(n16), .Z(n79) );
  MUX2D0 U104 ( .I0(q2[3]), .I1(in[3]), .S(n23), .Z(n94) );
  MUX2D0 U105 ( .I0(q13[5]), .I1(in[5]), .S(n17), .Z(n128) );
  IND3D2 U106 ( .A1(wr_sel[3]), .B1(wr_sel[0]), .B2(wr_en), .ZN(n19) );
  NR2XD1 U107 ( .A1(n19), .A2(n18), .ZN(n8) );
  NR2XD1 U108 ( .A1(n19), .A2(n24), .ZN(n14) );
  INVD0 U109 ( .I(q14[0]), .ZN(n7) );
  CKND2D0 U110 ( .A1(n27), .A2(in[0]), .ZN(n6) );
  OAI21D0 U111 ( .A1(n27), .A2(n7), .B(n6), .ZN(n99) );
  NR2D2 U112 ( .A1(n19), .A2(n1), .ZN(n31) );
  IND3D2 U113 ( .A1(wr_sel[3]), .B1(n9), .B2(wr_en), .ZN(n22) );
  NR2D2 U114 ( .A1(n22), .A2(n1), .ZN(n32) );
  CKMUX2D1 U115 ( .I0(q10[4]), .I1(in[4]), .S(n28), .Z(n44) );
  CKMUX2D1 U116 ( .I0(q10[2]), .I1(in[2]), .S(n28), .Z(n42) );
  CKMUX2D1 U117 ( .I0(q10[1]), .I1(in[1]), .S(n28), .Z(n41) );
  CKMUX2D1 U118 ( .I0(q10[3]), .I1(in[3]), .S(n28), .Z(n43) );
  CKMUX2D1 U119 ( .I0(q10[6]), .I1(in[6]), .S(n28), .Z(n46) );
  CKMUX2D1 U120 ( .I0(q10[7]), .I1(in[7]), .S(n28), .Z(n47) );
  CKMUX2D1 U121 ( .I0(q10[5]), .I1(in[5]), .S(n28), .Z(n45) );
  NR2D2 U122 ( .A1(n22), .A2(n18), .ZN(n11) );
  NR2D2 U123 ( .A1(n22), .A2(n24), .ZN(n16) );
  NR2D2 U124 ( .A1(n22), .A2(n21), .ZN(n23) );
endmodule


module cdc_fifo ( src_clk, dst_clk, reset, src_data, src_valid, src_ready, 
        dst_data, dst_valid, dst_ready );
  input [7:0] src_data;
  output [7:0] dst_data;
  input src_clk, dst_clk, reset, src_valid, dst_ready;
  output src_ready, dst_valid;
  wire   fifo_wr_en, N6, N7, N8, N9, N10, N12, N13, N14, N17, N18, N19, N20,
         N21, N22, N23, N24, N25, N26, N28, N29, N32, N33, N34, N35, N36, N37,
         N39, N40, N41, N42, N43, N44, N45, N46, N47, N48, n30, n31, n32, n33,
         n34, n35, n36, n37, n38, n39, n40, n41, n42, n43, n44, n45, n46, n47,
         n48, n49, n50, n51, n52, n53, n54, n55, n56, n57, n58, n59, n60, n61,
         n62, n63, n64, n65, n66, n67, n68, n69, n70, n71, n72, n73, n74, n75,
         n76, n77, n79, n81, n82, n83;
  wire   [4:0] wr_bin;
  wire   [4:0] rd_bin;
  wire   [4:0] rd_gray;
  wire   [4:0] wr_gray_sync2;
  wire   [4:0] rd_gray_sync2;
  wire   [4:0] wr_gray;
  wire   [4:0] rd_gray_sync1;
  wire   [4:0] wr_gray_sync1;

  fifo_storage16_width8 storage_inst ( .wr_clk(src_clk), .wr_en(fifo_wr_en), 
        .wr_sel(wr_bin[3:0]), .in(src_data), .rd_sel({rd_bin[3:2], n31, 
        rd_bin[0]}), .out(dst_data) );
  DFQD1 rd_gray_sync1_reg_0_ ( .D(N17), .CP(src_clk), .Q(rd_gray_sync1[0]) );
  DFQD1 rd_gray_sync2_reg_0_ ( .D(N22), .CP(src_clk), .Q(rd_gray_sync2[0]) );
  EDFQD1 wr_bin_reg_4_ ( .D(n81), .E(N6), .CP(src_clk), .Q(wr_bin[4]) );
  EDFQD1 wr_gray_reg_0_ ( .D(N12), .E(N6), .CP(src_clk), .Q(wr_gray[0]) );
  DFQD1 wr_gray_sync1_reg_0_ ( .D(N39), .CP(dst_clk), .Q(wr_gray_sync1[0]) );
  DFQD1 wr_gray_sync2_reg_0_ ( .D(N44), .CP(dst_clk), .Q(wr_gray_sync2[0]) );
  EDFQD1 wr_gray_reg_1_ ( .D(N13), .E(N6), .CP(src_clk), .Q(wr_gray[1]) );
  DFQD1 wr_gray_sync1_reg_1_ ( .D(N40), .CP(dst_clk), .Q(wr_gray_sync1[1]) );
  DFQD1 wr_gray_sync2_reg_1_ ( .D(N45), .CP(dst_clk), .Q(wr_gray_sync2[1]) );
  EDFQD1 wr_gray_reg_2_ ( .D(N14), .E(N6), .CP(src_clk), .Q(wr_gray[2]) );
  DFQD1 wr_gray_sync1_reg_2_ ( .D(N41), .CP(dst_clk), .Q(wr_gray_sync1[2]) );
  DFQD1 wr_gray_sync2_reg_2_ ( .D(N46), .CP(dst_clk), .Q(wr_gray_sync2[2]) );
  EDFQD1 wr_gray_reg_3_ ( .D(n79), .E(N6), .CP(src_clk), .Q(wr_gray[3]) );
  DFQD1 wr_gray_sync1_reg_3_ ( .D(N42), .CP(dst_clk), .Q(wr_gray_sync1[3]) );
  DFQD1 wr_gray_sync2_reg_3_ ( .D(N47), .CP(dst_clk), .Q(wr_gray_sync2[3]) );
  EDFQD1 wr_gray_reg_4_ ( .D(n81), .E(N6), .CP(src_clk), .Q(wr_gray[4]) );
  DFQD1 wr_gray_sync1_reg_4_ ( .D(N43), .CP(dst_clk), .Q(wr_gray_sync1[4]) );
  DFQD1 wr_gray_sync2_reg_4_ ( .D(N48), .CP(dst_clk), .Q(wr_gray_sync2[4]) );
  EDFQD1 rd_bin_reg_3_ ( .D(N32), .E(N28), .CP(dst_clk), .Q(rd_bin[3]) );
  EDFQD1 rd_bin_reg_4_ ( .D(N33), .E(N28), .CP(dst_clk), .Q(rd_bin[4]) );
  EDFQD1 rd_gray_reg_1_ ( .D(N35), .E(N28), .CP(dst_clk), .Q(rd_gray[1]) );
  DFQD1 rd_gray_sync1_reg_1_ ( .D(N18), .CP(src_clk), .Q(rd_gray_sync1[1]) );
  DFQD1 rd_gray_sync2_reg_1_ ( .D(N23), .CP(src_clk), .Q(rd_gray_sync2[1]) );
  EDFQD1 rd_gray_reg_2_ ( .D(N36), .E(N28), .CP(dst_clk), .Q(rd_gray[2]) );
  DFQD1 rd_gray_sync1_reg_2_ ( .D(N19), .CP(src_clk), .Q(rd_gray_sync1[2]) );
  DFQD1 rd_gray_sync2_reg_2_ ( .D(N24), .CP(src_clk), .Q(rd_gray_sync2[2]) );
  EDFQD1 rd_gray_reg_3_ ( .D(N37), .E(N28), .CP(dst_clk), .Q(rd_gray[3]) );
  DFQD1 rd_gray_sync1_reg_3_ ( .D(N20), .CP(src_clk), .Q(rd_gray_sync1[3]) );
  DFQD1 rd_gray_sync2_reg_3_ ( .D(N25), .CP(src_clk), .Q(rd_gray_sync2[3]) );
  EDFQD1 rd_gray_reg_4_ ( .D(N33), .E(N28), .CP(dst_clk), .Q(rd_gray[4]) );
  DFQD1 rd_gray_sync1_reg_4_ ( .D(N21), .CP(src_clk), .Q(rd_gray_sync1[4]) );
  DFQD1 rd_gray_sync2_reg_4_ ( .D(N26), .CP(src_clk), .Q(rd_gray_sync2[4]) );
  EDFQD4 wr_bin_reg_1_ ( .D(N8), .E(N6), .CP(src_clk), .Q(wr_bin[1]) );
  EDFQD4 wr_bin_reg_0_ ( .D(N7), .E(N6), .CP(src_clk), .Q(wr_bin[0]) );
  EDFQD4 wr_bin_reg_2_ ( .D(N9), .E(N6), .CP(src_clk), .Q(wr_bin[2]) );
  EDFQD1 rd_bin_reg_2_ ( .D(n82), .E(N28), .CP(dst_clk), .Q(rd_bin[2]) );
  EDFQD4 rd_bin_reg_0_ ( .D(N29), .E(N28), .CP(dst_clk), .Q(rd_bin[0]) );
  EDFQD1 wr_bin_reg_3_ ( .D(N10), .E(N6), .CP(src_clk), .Q(wr_bin[3]) );
  EDFQD1 rd_bin_reg_1_ ( .D(n83), .E(N28), .CP(dst_clk), .Q(rd_bin[1]) );
  EDFQD1 rd_gray_reg_0_ ( .D(N34), .E(N28), .CP(dst_clk), .Q(rd_gray[0]) );
  IOA21D1 U75 ( .A1(n53), .A2(dst_ready), .B(n63), .ZN(N28) );
  AOI221D0 U76 ( .A1(n58), .A2(wr_gray_sync2[1]), .B1(wr_gray_sync2[0]), .B2(
        n62), .C(n45), .ZN(n49) );
  OAI221D0 U77 ( .A1(n59), .A2(wr_gray_sync2[2]), .B1(n60), .B2(
        wr_gray_sync2[3]), .C(n46), .ZN(n47) );
  OAI21D0 U78 ( .A1(n74), .A2(rd_bin[2]), .B(n66), .ZN(n77) );
  NR2D0 U79 ( .A1(n77), .A2(reset), .ZN(n82) );
  NR2D0 U80 ( .A1(reset), .A2(n57), .ZN(N33) );
  NR2D1 U81 ( .A1(reset), .A2(n76), .ZN(N32) );
  INR2D0 U82 ( .A1(wr_gray_sync1[0]), .B1(reset), .ZN(N44) );
  CKAN2D0 U83 ( .A1(rd_gray_sync1[2]), .A2(n63), .Z(N24) );
  INVD1 U84 ( .I(rd_bin[1]), .ZN(n30) );
  INR2D0 U85 ( .A1(wr_gray_sync1[4]), .B1(reset), .ZN(N48) );
  INR2D0 U86 ( .A1(wr_gray_sync1[3]), .B1(reset), .ZN(N47) );
  INR2D0 U87 ( .A1(wr_gray_sync1[2]), .B1(reset), .ZN(N46) );
  INR2D0 U88 ( .A1(wr_gray_sync1[1]), .B1(reset), .ZN(N45) );
  INVD2 U89 ( .I(n50), .ZN(dst_valid) );
  XOR2D0 U90 ( .A1(rd_bin[4]), .A2(n55), .Z(n57) );
  CKAN2D0 U91 ( .A1(n54), .A2(n63), .Z(n79) );
  INVD4 U92 ( .I(n30), .ZN(n31) );
  CKND2 U93 ( .I(wr_bin[2]), .ZN(n32) );
  XNR2D0 U94 ( .A1(wr_bin[1]), .A2(rd_gray_sync2[0]), .ZN(n35) );
  INVD1 U95 ( .I(rd_gray[4]), .ZN(n61) );
  NR2XD3 U96 ( .A1(n67), .A2(n32), .ZN(n71) );
  NR2D2 U97 ( .A1(n71), .A2(wr_bin[3]), .ZN(n69) );
  ND2D2 U98 ( .A1(n71), .A2(wr_bin[3]), .ZN(n70) );
  ND2D1 U99 ( .A1(n67), .A2(n32), .ZN(n72) );
  INVD2 U100 ( .I(n41), .ZN(n43) );
  XNR2D1 U101 ( .A1(n51), .A2(rd_gray_sync2[2]), .ZN(n36) );
  XNR2D0 U102 ( .A1(n64), .A2(n33), .ZN(n34) );
  INVD0 U103 ( .I(rd_gray_sync2[1]), .ZN(n33) );
  OAI22D0 U104 ( .A1(n58), .A2(wr_gray_sync2[1]), .B1(n62), .B2(
        wr_gray_sync2[0]), .ZN(n45) );
  ND3D2 U105 ( .A1(n40), .A2(n39), .A3(n38), .ZN(n41) );
  NR3D1 U106 ( .A1(n36), .A2(n35), .A3(n34), .ZN(n39) );
  CKXOR2D1 U107 ( .A1(n54), .A2(rd_gray_sync2[3]), .Z(n40) );
  XNR2D0 U108 ( .A1(n52), .A2(rd_gray_sync2[4]), .ZN(n38) );
  INVD0 U109 ( .I(rd_gray[3]), .ZN(n60) );
  INVD0 U110 ( .I(rd_gray[2]), .ZN(n59) );
  NR2D0 U111 ( .A1(n31), .A2(rd_bin[0]), .ZN(n73) );
  IND2D0 U112 ( .A1(n66), .B1(rd_bin[3]), .ZN(n55) );
  INVD0 U113 ( .I(rd_bin[3]), .ZN(n56) );
  XNR2D1 U114 ( .A1(n69), .A2(wr_bin[4]), .ZN(n54) );
  INVD0 U115 ( .I(rd_gray[0]), .ZN(n62) );
  INVD0 U116 ( .I(reset), .ZN(n63) );
  NR2D0 U117 ( .A1(rd_bin[0]), .A2(reset), .ZN(N29) );
  NR2D0 U118 ( .A1(wr_bin[0]), .A2(reset), .ZN(N7) );
  IOA21D0 U119 ( .A1(n83), .A2(n77), .B(n75), .ZN(N35) );
  OAI21D0 U120 ( .A1(n74), .A2(n73), .B(n82), .ZN(n75) );
  NR2D0 U121 ( .A1(n65), .A2(reset), .ZN(N13) );
  NR2D0 U122 ( .A1(wr_bin[1]), .A2(reset), .ZN(N12) );
  ND2D1 U123 ( .A1(n44), .A2(n63), .ZN(N6) );
  NR2D0 U124 ( .A1(reset), .A2(n31), .ZN(N34) );
  INVD0 U125 ( .I(rd_gray[1]), .ZN(n58) );
  INVD0 U126 ( .I(n53), .ZN(n50) );
  ND2D4 U127 ( .A1(wr_bin[0]), .A2(wr_bin[1]), .ZN(n67) );
  XNR2D1 U128 ( .A1(n72), .A2(wr_bin[3]), .ZN(n51) );
  NR2D2 U129 ( .A1(wr_bin[0]), .A2(wr_bin[1]), .ZN(n68) );
  XNR2D1 U130 ( .A1(n68), .A2(wr_bin[2]), .ZN(n64) );
  INVD1 U131 ( .I(wr_bin[4]), .ZN(n37) );
  XNR2D1 U132 ( .A1(n70), .A2(n37), .ZN(n52) );
  BUFFD2 U133 ( .I(n41), .Z(src_ready) );
  INVD1 U134 ( .I(src_valid), .ZN(n42) );
  NR2XD4 U135 ( .A1(n43), .A2(n42), .ZN(fifo_wr_en) );
  INVD0 U136 ( .I(fifo_wr_en), .ZN(n44) );
  AOI22D1 U137 ( .A1(wr_gray_sync2[2]), .A2(n59), .B1(wr_gray_sync2[3]), .B2(
        n60), .ZN(n46) );
  AOI21D1 U138 ( .A1(wr_gray_sync2[4]), .A2(n61), .B(n47), .ZN(n48) );
  OAI211D1 U139 ( .A1(wr_gray_sync2[4]), .A2(n61), .B(n49), .C(n48), .ZN(n53)
         );
  NR2D0 U140 ( .A1(n51), .A2(reset), .ZN(N14) );
  NR2D0 U141 ( .A1(n52), .A2(reset), .ZN(n81) );
  AN2XD1 U142 ( .A1(n31), .A2(rd_bin[0]), .Z(n74) );
  ND2D1 U143 ( .A1(n74), .A2(rd_bin[2]), .ZN(n66) );
  MUX2ND0 U144 ( .I0(n56), .I1(rd_bin[3]), .S(n66), .ZN(n76) );
  AO22D0 U145 ( .A1(N33), .A2(n76), .B1(N32), .B2(n57), .Z(N37) );
  CKAN2D0 U146 ( .A1(wr_gray[4]), .A2(n63), .Z(N43) );
  CKAN2D0 U147 ( .A1(wr_gray[0]), .A2(n63), .Z(N39) );
  CKAN2D0 U148 ( .A1(wr_gray[2]), .A2(n63), .Z(N41) );
  NR2D0 U149 ( .A1(reset), .A2(n58), .ZN(N18) );
  NR2D0 U150 ( .A1(reset), .A2(n59), .ZN(N19) );
  CKAN2D0 U151 ( .A1(wr_gray[1]), .A2(n63), .Z(N40) );
  CKAN2D0 U152 ( .A1(wr_gray[3]), .A2(n63), .Z(N42) );
  NR2D0 U153 ( .A1(reset), .A2(n60), .ZN(N20) );
  NR2D0 U154 ( .A1(reset), .A2(n61), .ZN(N21) );
  NR2D0 U155 ( .A1(reset), .A2(n62), .ZN(N17) );
  CKAN2D0 U156 ( .A1(rd_gray_sync1[1]), .A2(n63), .Z(N23) );
  CKAN2D0 U157 ( .A1(rd_gray_sync1[3]), .A2(n63), .Z(N25) );
  CKAN2D0 U158 ( .A1(rd_gray_sync1[4]), .A2(n63), .Z(N26) );
  CKAN2D0 U159 ( .A1(rd_gray_sync1[0]), .A2(n63), .Z(N22) );
  INVD0 U160 ( .I(n64), .ZN(n65) );
  INR3D0 U161 ( .A1(n67), .B1(n68), .B2(reset), .ZN(N8) );
  INR3D0 U162 ( .A1(n70), .B1(n69), .B2(reset), .ZN(N10) );
  NR3D0 U163 ( .A1(n74), .A2(reset), .A3(n73), .ZN(n83) );
  INR3D0 U164 ( .A1(n72), .B1(n71), .B2(reset), .ZN(N9) );
  AO22D0 U165 ( .A1(N32), .A2(n77), .B1(n82), .B2(n76), .Z(N36) );
endmodule

