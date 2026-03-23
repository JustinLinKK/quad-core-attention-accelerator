// Created by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
module cdc_fifo (
    src_clk,
    dst_clk,
    reset,
    src_data,
    src_valid,
    src_ready,
    dst_data,
    dst_valid,
    dst_ready);

  parameter message_w = 8;
  parameter depth = 16;  // Use 16 to cover one full PMEM bank burst.
  parameter addr_w = 4;  // log2(depth), depth must be power-of-two.

  input  src_clk;
  input  dst_clk;
  input  reset;
  input  [message_w-1:0] src_data;
  input  src_valid;
  output src_ready;
  output [message_w-1:0] dst_data;
  output dst_valid;
  input  dst_ready;

  localparam ptr_w = addr_w + 1;

  reg [ptr_w-1:0] wr_bin;
  reg [ptr_w-1:0] wr_gray;
  reg [ptr_w-1:0] rd_bin;
  reg [ptr_w-1:0] rd_gray;

  reg [ptr_w-1:0] rd_gray_sync1;
  reg [ptr_w-1:0] rd_gray_sync2;
  reg [ptr_w-1:0] wr_gray_sync1;
  reg [ptr_w-1:0] wr_gray_sync2;

  wire [ptr_w-1:0] wr_bin_next;
  wire [ptr_w-1:0] wr_gray_next;
  wire [ptr_w-1:0] rd_bin_next;
  wire [ptr_w-1:0] rd_gray_next;
  wire fifo_full;
  wire fifo_empty;
  wire [message_w-1:0] fifo_rd_data;
  wire fifo_wr_en;

  // CDC FIFO flow (easy view):
  // 1) SRC side writes when src_valid && src_ready.
  // 2) Write/read pointers are kept in both binary and Gray code.
  // 3) Gray pointers are synchronized across clock domains with 2FF sync.
  // 4) SRC computes fifo_full from synchronized read pointer.
  // 5) DST computes fifo_empty from synchronized write pointer.
  // 6) DST reads when dst_valid && dst_ready.
  // This keeps data safe even when src_clk and dst_clk are unrelated.

  initial
  begin
    if (depth != 16 || addr_w != 4)
      $error("cdc_fifo storage backend currently supports depth=16, addr_w=4");
  end

  // Next-pointer generation:
  // - binary is used for memory addressing
  // - Gray is used for cross-domain synchronization
  assign wr_bin_next  = wr_bin + 1'b1;
  assign wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
  assign rd_bin_next  = rd_bin + 1'b1;
  assign rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

  // Status generation using synchronized cross-domain Gray pointers.
  assign fifo_empty = (rd_gray == wr_gray_sync2);
  assign fifo_full  = (wr_gray_next == {~rd_gray_sync2[ptr_w-1:ptr_w-2], rd_gray_sync2[ptr_w-3:0]});

  // Handshake view:
  // src_ready=1 means SRC is allowed to push.
  // dst_valid=1 means DST can pop.
  assign src_ready = !fifo_full;
  assign dst_valid = !fifo_empty;
  assign dst_data = fifo_rd_data;
  assign fifo_wr_en = src_valid && !fifo_full;

  // Shared 16-depth storage:
  // write in SRC clock domain, read index from DST pointer.
  fifo_storage16 #(.width(message_w)) storage_inst (
                   .wr_clk(src_clk),
                   .wr_en(fifo_wr_en),
                   .wr_sel(wr_bin[3:0]),
                   .in(src_data),
                   .rd_sel(rd_bin[3:0]),
                   .out(fifo_rd_data)
                 );

  always @(posedge src_clk)
  begin
    if (reset)
    begin
      wr_bin <= {ptr_w{1'b0}};
      wr_gray <= {ptr_w{1'b0}};
      rd_gray_sync1 <= {ptr_w{1'b0}};
      rd_gray_sync2 <= {ptr_w{1'b0}};
    end
    else
    begin
      // Bring read pointer safely into SRC domain (2FF synchronizer).
      rd_gray_sync1 <= rd_gray;
      rd_gray_sync2 <= rd_gray_sync1;

      // Push one entry when SRC handshake succeeds.
      if (fifo_wr_en)
      begin
        wr_bin <= wr_bin_next;
        wr_gray <= wr_gray_next;
      end
    end
  end

  always @(posedge dst_clk)
  begin
    if (reset)
    begin
      rd_bin <= {ptr_w{1'b0}};
      rd_gray <= {ptr_w{1'b0}};
      wr_gray_sync1 <= {ptr_w{1'b0}};
      wr_gray_sync2 <= {ptr_w{1'b0}};
    end
    else
    begin
      // Bring write pointer safely into DST domain (2FF synchronizer).
      wr_gray_sync1 <= wr_gray;
      wr_gray_sync2 <= wr_gray_sync1;

      // Pop one entry when DST handshake succeeds.
      if (dst_ready && !fifo_empty)
      begin
        rd_bin <= rd_bin_next;
        rd_gray <= rd_gray_next;
      end
    end
  end

endmodule
