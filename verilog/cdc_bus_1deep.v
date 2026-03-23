// Created by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
module cdc_bus_1deep (src_clk, dst_clk, reset, src_data, src_valid, src_ready, dst_data, dst_valid, dst_ready);

parameter message_w = 8;

// Source domain interface.
input  src_clk;
input  [message_w-1:0] src_data;
input  src_valid;
output src_ready;

// Destination domain interface.
input  dst_clk;
output reg [message_w-1:0] dst_data;
output reg dst_valid;
input  dst_ready;

input  reset;

// Internal state.
reg [message_w-1:0] src_hold_data;
reg req_tgl_src;
reg ack_tgl_dst;
reg ack_sync_ff1;
reg ack_sync_ff2;
reg req_sync_ff1;
reg req_sync_ff2;
reg req_seen_dst;

// Source can send only when previous transfer is acknowledged.
assign src_ready = (req_tgl_src == ack_sync_ff2);

// Source clock domain:
// capture payload and emit request toggle when src_valid/src_ready handshakes.
always @(posedge src_clk) begin
  if (reset) begin
    src_hold_data <= {message_w{1'b0}};
    req_tgl_src <= 1'b0;
    ack_sync_ff1 <= 1'b0;
    ack_sync_ff2 <= 1'b0;
  end
  else begin
    ack_sync_ff1 <= ack_tgl_dst;
    ack_sync_ff2 <= ack_sync_ff1;

    if (src_valid && src_ready) begin
      src_hold_data <= src_data;
      req_tgl_src <= ~req_tgl_src;
    end
  end
end

// Destination clock domain:
// detect new request toggle, present dst_valid, and acknowledge after dst_ready.
always @(posedge dst_clk) begin
  if (reset) begin
    req_sync_ff1 <= 1'b0;
    req_sync_ff2 <= 1'b0;
    req_seen_dst <= 1'b0;
    dst_data <= {message_w{1'b0}};
    dst_valid <= 1'b0;
    ack_tgl_dst <= 1'b0;
  end
  else begin
    req_sync_ff1 <= req_tgl_src;
    req_sync_ff2 <= req_sync_ff1;

    if (!dst_valid && (req_sync_ff2 != req_seen_dst)) begin
      dst_data <= src_hold_data;
      dst_valid <= 1'b1;
      req_seen_dst <= req_sync_ff2;
    end

    if (dst_valid && dst_ready) begin
      dst_valid <= 1'b0;
      ack_tgl_dst <= req_seen_dst;
    end
  end
end

endmodule
