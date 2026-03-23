// Created by Jingbin Lin in ECE 260B Project, UCSD
// Step6 shared scratchpad wrapper: 64-bit slice writes into 256-bit multicore rows
// Please do not spread this code without permission
module sram_256b_w64 (CLK, D, Q, CEN, WEN, A, SEL);

  input  CLK;
  input  WEN;
  input  CEN;
  input  [63:0] D;
  input  [5:0] A;
  input  [1:0] SEL;
  output reg [255:0] Q;

  reg [255:0] memory [0:63];
  integer idx;

  initial begin
    for (idx = 0; idx < 64; idx = idx + 1)
      memory[idx] = 256'd0;
    Q = 256'd0;
  end

  always @(posedge CLK) begin
    if (!CEN && WEN) begin
      Q <= memory[A];
    end else if (!CEN && !WEN) begin
      case (SEL)
        2'b00: memory[A][63:0] <= D;
        2'b01: memory[A][127:64] <= D;
        2'b10: memory[A][191:128] <= D;
        default: memory[A][255:192] <= D;
      endcase
    end
  end

endmodule
