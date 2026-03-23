// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Modified for fixed-width scratchpad storage in ECE 260B Project, UCSD
// Please do not spread this code without permission
module sram_64b_w256 (CLK, D, Q, CEN, WEN, A);

  input CLK;
  input WEN;
  input CEN;
  input [63:0] D;
  input [7:0] A;
  output reg [63:0] Q;

  reg [63:0] memory [0:255];
  integer idx;

  initial begin
    for (idx = 0; idx < 256; idx = idx + 1)
      memory[idx] = 64'd0;
    Q = 64'd0;
  end

  always @(posedge CLK) begin
    if (!CEN && WEN)
      Q <= memory[A];
    else if (!CEN && !WEN)
      memory[A] <= D;
  end

endmodule
