// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Modified by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
module mac_array (
    clk,
    reset,
    in,
    out,
    fifo_wr,
    inst);

  parameter col = 8;
  parameter bw = 8;
  parameter bw_psum = 2*bw+6;
  parameter pr = 8;

  input  clk;
  input  reset;
  input  [pr*bw-1:0] in;
  input  [1:0] inst; // [1]: execute, [0]: load

  output reg [col-1:0] fifo_wr;
  output reg [bw_psum*col-1:0] out;

  wire [2*(col+1)-1:0] inst_temp;
  wire [col:0] q_zero_temp;
  wire [2*(col+1)*bw*pr-1:0] q_temp;
  wire [col-1:0] fifo_wr_raw;
  wire [bw_psum*col-1:0] out_raw;

  // -----------------------------
  // Input boundary register stage
  // -----------------------------
  reg  [pr*bw-1:0] in_r;
  reg  [1:0]       inst_r;

  wire [pr*bw-1:0] in_use;
  wire [1:0]       inst_use;

  assign in_use   = in_r;
  assign inst_use = inst_r;

  always @(posedge clk)
  begin
    if (reset)
    begin
      in_r   <= {pr*bw{1'b0}};
      inst_r <= 2'b0;
    end
    else
    begin
      in_r   <= in;
      inst_r <= inst;
    end
  end

  wire q_in_zero;
  wire q_load_zero;

  genvar i;
  assign q_load_zero = ~|in_use;
  assign q_in_zero   = inst_use[0] ? q_load_zero : 1'b0;

  assign inst_temp[1:0] = inst_use;
  assign q_temp[bw*pr-1:0] = in_use;
  assign q_zero_temp[0] = q_in_zero;

  for (i=1; i < col+1 ; i=i+1)
  begin : col_idx
    mac_col #(.bw(bw), .bw_psum(bw_psum), .pr(pr), .col_id(i)) mac_col_inst (
              .q_in(q_temp[pr*bw*i-1:pr*bw*(i-1)]),
              .q_out(q_temp[pr*bw*(i+1)-1:pr*bw*i]),
              .q_zero_in(q_zero_temp[i-1]),
              .q_zero_out(q_zero_temp[i]),
              .clk(clk),
              .reset(reset),
              .fifo_wr(fifo_wr_raw[i-1]),
              .i_inst(inst_temp[2*i-1:2*(i-1)]),
              .o_inst(inst_temp[2*(i+1)-1:2*i]),
              .out(out_raw[bw_psum*i-1:bw_psum*(i-1)])
            );
  end

  // Final output register stage to reduce MAC-array boundary timing pressure.
  always @(posedge clk)
  begin
    if (reset)
    begin
      fifo_wr <= {col{1'b0}};
      out <= {bw_psum*col{1'b0}};
    end
    else
    begin
      fifo_wr <= fifo_wr_raw;
      out <= out_raw;
    end
  end

endmodule