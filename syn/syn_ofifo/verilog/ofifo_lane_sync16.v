// Created for Step5 OFIFO timing closure.
// Single-lane 16-deep FIFO with registered read data.
module ofifo_lane_sync16 (rd_clk, wr_clk, in, out, rd, wr, o_full, o_empty, reset);

  parameter bw = 4;
  parameter simd = 1;

  input  rd_clk;
  input  wr_clk;
  input  rd;
  input  wr;
  input  reset;
  output o_full;
  output o_empty;
  input  [simd*bw-1:0] in;
  output [simd*bw-1:0] out;

  wire full, empty;
  reg [4:0] rd_ptr;
  reg [4:0] wr_ptr;
  reg [simd*bw-1:0] out_q;
  reg [simd*bw-1:0] rd_data;

  reg [simd*bw-1:0] q0;
  reg [simd*bw-1:0] q1;
  reg [simd*bw-1:0] q2;
  reg [simd*bw-1:0] q3;
  reg [simd*bw-1:0] q4;
  reg [simd*bw-1:0] q5;
  reg [simd*bw-1:0] q6;
  reg [simd*bw-1:0] q7;
  reg [simd*bw-1:0] q8;
  reg [simd*bw-1:0] q9;
  reg [simd*bw-1:0] q10;
  reg [simd*bw-1:0] q11;
  reg [simd*bw-1:0] q12;
  reg [simd*bw-1:0] q13;
  reg [simd*bw-1:0] q14;
  reg [simd*bw-1:0] q15;

  assign empty = (wr_ptr == rd_ptr) ? 1'b1 : 1'b0;
  assign full  = ((wr_ptr[3:0] == rd_ptr[3:0]) && (wr_ptr[4] != rd_ptr[4])) ? 1'b1 : 1'b0;

  assign o_full  = full;
  assign o_empty = empty;
  assign out = out_q;

  always @(*) begin
    case (rd_ptr[3:0])
      4'b0000: rd_data = q0;
      4'b0001: rd_data = q1;
      4'b0010: rd_data = q2;
      4'b0011: rd_data = q3;
      4'b0100: rd_data = q4;
      4'b0101: rd_data = q5;
      4'b0110: rd_data = q6;
      4'b0111: rd_data = q7;
      4'b1000: rd_data = q8;
      4'b1001: rd_data = q9;
      4'b1010: rd_data = q10;
      4'b1011: rd_data = q11;
      4'b1100: rd_data = q12;
      4'b1101: rd_data = q13;
      4'b1110: rd_data = q14;
      default: rd_data = q15;
    endcase
  end

  always @ (posedge rd_clk) begin
    if (reset) begin
      rd_ptr <= 5'b00000;
      out_q <= {simd*bw{1'b0}};
    end
    else if ((rd == 1'b1) && (empty == 1'b0)) begin
      rd_ptr <= rd_ptr + 1'b1;
      out_q <= rd_data;
    end
  end

  always @ (posedge wr_clk) begin
    if (reset) begin
      wr_ptr <= 5'b00000;
    end
    else begin
      if ((wr == 1'b1) && (full == 1'b0)) begin
        wr_ptr <= wr_ptr + 1'b1;

        case (wr_ptr[3:0])
          4'b0000: q0  <= in;
          4'b0001: q1  <= in;
          4'b0010: q2  <= in;
          4'b0011: q3  <= in;
          4'b0100: q4  <= in;
          4'b0101: q5  <= in;
          4'b0110: q6  <= in;
          4'b0111: q7  <= in;
          4'b1000: q8  <= in;
          4'b1001: q9  <= in;
          4'b1010: q10 <= in;
          4'b1011: q11 <= in;
          4'b1100: q12 <= in;
          4'b1101: q13 <= in;
          4'b1110: q14 <= in;
          4'b1111: q15 <= in;
        endcase
      end
    end
  end

endmodule
