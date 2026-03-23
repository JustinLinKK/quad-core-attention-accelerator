// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission
module sram_64b_w16 (CLK, D, Q, CEN, WEN, A);

  input  CLK;
  input  WEN;
  input  CEN;
  input  [63:0] D;
  input  [3:0] A;
  output reg [63:0] Q;

  reg [63:0] memory0;
  reg [63:0] memory1;
  reg [63:0] memory2;
  reg [63:0] memory3;
  reg [63:0] memory4;
  reg [63:0] memory5;
  reg [63:0] memory6;
  reg [63:0] memory7;
  reg [63:0] memory8;
  reg [63:0] memory9;
  reg [63:0] memory10;
  reg [63:0] memory11;
  reg [63:0] memory12;
  reg [63:0] memory13;
  reg [63:0] memory14;
  reg [63:0] memory15;

  initial begin
      memory0  = 64'b0;
      memory1  = 64'b0;
      memory2  = 64'b0;
      memory3  = 64'b0;
      memory4  = 64'b0;
      memory5  = 64'b0;
      memory6  = 64'b0;
      memory7  = 64'b0;
      memory8  = 64'b0;
      memory9  = 64'b0;
      memory10 = 64'b0;
      memory11 = 64'b0;
      memory12 = 64'b0;
      memory13 = 64'b0;
      memory14 = 64'b0;
      memory15 = 64'b0;
      Q = 64'b0;
    end

  always @ (posedge CLK) begin

   if (!CEN && WEN) begin // read
     case (A)
      4'b0000: Q <= memory0;
      4'b0001: Q <= memory1;
      4'b0010: Q <= memory2;
      4'b0011: Q <= memory3;
      4'b0100: Q <= memory4;
      4'b0101: Q <= memory5;
      4'b0110: Q <= memory6;
      4'b0111: Q <= memory7;
      4'b1000: Q <= memory8;
      4'b1001: Q <= memory9;
      4'b1010: Q <= memory10;
      4'b1011: Q <= memory11;
      4'b1100: Q <= memory12;
      4'b1101: Q <= memory13;
      4'b1110: Q <= memory14;
      4'b1111: Q <= memory15;
    endcase
   end

   else if (!CEN && !WEN) begin // write
     case (A)
      4'b0000: memory0  <= D;
      4'b0001: memory1  <= D;
      4'b0010: memory2  <= D;
      4'b0011: memory3  <= D;
      4'b0100: memory4  <= D;
      4'b0101: memory5  <= D;
      4'b0110: memory6  <= D;
      4'b0111: memory7  <= D;
      4'b1000: memory8  <= D;
      4'b1001: memory9  <= D;
      4'b1010: memory10 <= D;
      4'b1011: memory11 <= D;
      4'b1100: memory12 <= D;
      4'b1101: memory13 <= D;
      4'b1110: memory14 <= D;
      4'b1111: memory15 <= D;
    endcase
  end
end

endmodule
