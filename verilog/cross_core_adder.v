// Created by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission
module cross_core_adder (
    clk,
    reset,
    multi_core_inst,
    core_enable_mask,
    group_link,
    ext_sum_wr_cmd,
    core_sum_in,
    sum_valid_in,
    core_sum_pop_ready,
    core_sum_to_cores,
    core_ext_sum_wr,
    sum_out,
    sum_valid_out);

  parameter bw = 8;
  parameter bw_psum = 2*bw+6;
  parameter sum_out_bw = bw_psum + 4;
  parameter num_cores = 4;
  parameter sum_in_bw = sum_out_bw + 2;

  input  clk;
  input  reset;
  input  [num_cores-1:0] multi_core_inst;
  input  [num_cores-1:0] core_enable_mask;
  input  [num_cores-2:0] group_link;
  input  ext_sum_wr_cmd;
  input  [num_cores*sum_out_bw-1:0] core_sum_in;
  input  [num_cores-1:0] sum_valid_in;
  output [num_cores-1:0] core_sum_pop_ready;
  output reg [num_cores*sum_in_bw-1:0] core_sum_to_cores;
  output reg [num_cores-1:0] core_ext_sum_wr;
  output reg [num_cores*sum_in_bw-1:0] sum_out;
  output reg [num_cores-1:0] sum_valid_out;

  integer i;
  integer g;
  reg [num_cores-1:0] group_done_mask;
  reg group_ready;

  reg [sum_out_bw-1:0] core_sum_store [0:num_cores-1];
  reg [num_cores-1:0] core_sum_seen;
  reg ext_wr_pending_q;

  reg s0_valid_q;
  reg s0_ext_wr_q;
  reg [num_cores-1:0] s0_seen_mask_q;
  reg [num_cores-1:0] s0_multicore_mask_q;
  reg [num_cores-2:0] s0_group_link_q;
  reg [sum_in_bw-1:0] s0_x0_q;
  reg [sum_in_bw-1:0] s0_x1_q;
  reg [sum_in_bw-1:0] s0_x2_q;
  reg [sum_in_bw-1:0] s0_x3_q;

  reg s1_valid_q;
  reg s1_ext_wr_q;
  reg [2:0] s1_group_count_q;
  reg [num_cores-1:0] s1_seen_mask_q;
  reg [num_cores-1:0] s1_group_mask0_q;
  reg [num_cores-1:0] s1_group_mask1_q;
  reg [num_cores-1:0] s1_group_mask2_q;
  reg [num_cores-1:0] s1_group_mask3_q;
  reg [sum_in_bw-1:0] s1_group_sum0_q;
  reg [sum_in_bw-1:0] s1_group_sum1_q;
  reg [sum_in_bw-1:0] s1_group_sum2_q;
  reg [sum_in_bw-1:0] s1_group_sum3_q;

  wire [num_cores-1:0] multicore_mask;
  wire [num_cores-1:0] incoming_mask;
  wire [num_cores-1:0] seen_after_capture;
  wire reduce_fire;
  wire [sum_in_bw-1:0] x0_after_capture;
  wire [sum_in_bw-1:0] x1_after_capture;
  wire [sum_in_bw-1:0] x2_after_capture;
  wire [sum_in_bw-1:0] x3_after_capture;
  wire [sum_in_bw-1:0] sum01_s0;
  wire [sum_in_bw-1:0] sum23_s0;

  assign multicore_mask = core_enable_mask & multi_core_inst;
  assign core_sum_pop_ready = multicore_mask & ~core_sum_seen;
  assign incoming_mask = sum_valid_in & core_sum_pop_ready;
  assign reduce_fire = (|incoming_mask) | ext_sum_wr_cmd | ext_wr_pending_q;

  assign seen_after_capture[0] = multicore_mask[0] && (core_sum_seen[0] || incoming_mask[0]);
  assign seen_after_capture[1] = multicore_mask[1] && (core_sum_seen[1] || incoming_mask[1]);
  assign seen_after_capture[2] = multicore_mask[2] && (core_sum_seen[2] || incoming_mask[2]);
  assign seen_after_capture[3] = multicore_mask[3] && (core_sum_seen[3] || incoming_mask[3]);

  assign x0_after_capture = seen_after_capture[0] ? {{(sum_in_bw-sum_out_bw){1'b0}}, (incoming_mask[0] ? core_sum_in[sum_out_bw*1-1:sum_out_bw*0] : core_sum_store[0])} : {sum_in_bw{1'b0}};
  assign x1_after_capture = seen_after_capture[1] ? {{(sum_in_bw-sum_out_bw){1'b0}}, (incoming_mask[1] ? core_sum_in[sum_out_bw*2-1:sum_out_bw*1] : core_sum_store[1])} : {sum_in_bw{1'b0}};
  assign x2_after_capture = seen_after_capture[2] ? {{(sum_in_bw-sum_out_bw){1'b0}}, (incoming_mask[2] ? core_sum_in[sum_out_bw*3-1:sum_out_bw*2] : core_sum_store[2])} : {sum_in_bw{1'b0}};
  assign x3_after_capture = seen_after_capture[3] ? {{(sum_in_bw-sum_out_bw){1'b0}}, (incoming_mask[3] ? core_sum_in[sum_out_bw*4-1:sum_out_bw*3] : core_sum_store[3])} : {sum_in_bw{1'b0}};

  assign sum01_s0 = s0_x0_q + s0_x1_q;
  assign sum23_s0 = s0_x2_q + s0_x3_q;

  always @(posedge clk) begin
    if (reset) begin
      core_ext_sum_wr <= {num_cores{1'b0}};
      core_sum_to_cores <= {num_cores*sum_in_bw{1'b0}};
      sum_out <= {num_cores*sum_in_bw{1'b0}};
      sum_valid_out <= {num_cores{1'b0}};
      core_sum_seen <= {num_cores{1'b0}};
      ext_wr_pending_q <= 1'b0;
      s0_valid_q <= 1'b0;
      s0_ext_wr_q <= 1'b0;
      s0_seen_mask_q <= {num_cores{1'b0}};
      s0_multicore_mask_q <= {num_cores{1'b0}};
      s0_group_link_q <= {(num_cores-1){1'b0}};
      s0_x0_q <= {sum_in_bw{1'b0}};
      s0_x1_q <= {sum_in_bw{1'b0}};
      s0_x2_q <= {sum_in_bw{1'b0}};
      s0_x3_q <= {sum_in_bw{1'b0}};
      s1_valid_q <= 1'b0;
      s1_ext_wr_q <= 1'b0;
      s1_group_count_q <= 3'd0;
      s1_seen_mask_q <= {num_cores{1'b0}};
      s1_group_mask0_q <= {num_cores{1'b0}};
      s1_group_mask1_q <= {num_cores{1'b0}};
      s1_group_mask2_q <= {num_cores{1'b0}};
      s1_group_mask3_q <= {num_cores{1'b0}};
      s1_group_sum0_q <= {sum_in_bw{1'b0}};
      s1_group_sum1_q <= {sum_in_bw{1'b0}};
      s1_group_sum2_q <= {sum_in_bw{1'b0}};
      s1_group_sum3_q <= {sum_in_bw{1'b0}};
      for (i = 0; i < num_cores; i = i + 1)
        core_sum_store[i] <= {sum_out_bw{1'b0}};
    end else begin
      core_ext_sum_wr <= {num_cores{1'b0}};
      sum_valid_out <= {num_cores{1'b0}};
      group_done_mask = {num_cores{1'b0}};

      for (i = 0; i < num_cores; i = i + 1) begin
        if (!multicore_mask[i])
          core_sum_seen[i] <= 1'b0;
        else if (incoming_mask[i]) begin
          core_sum_store[i] <= core_sum_in[i*sum_out_bw +: sum_out_bw];
          core_sum_seen[i] <= 1'b1;
        end
      end

      if (ext_sum_wr_cmd)
        ext_wr_pending_q <= 1'b1;

      if (reduce_fire) begin
        s0_valid_q <= |multicore_mask;
        s0_ext_wr_q <= ext_sum_wr_cmd | ext_wr_pending_q;
        s0_seen_mask_q <= seen_after_capture;
        s0_multicore_mask_q <= multicore_mask;
        s0_group_link_q <= group_link;
        s0_x0_q <= x0_after_capture;
        s0_x1_q <= x1_after_capture;
        s0_x2_q <= x2_after_capture;
        s0_x3_q <= x3_after_capture;
      end else begin
        s0_valid_q <= 1'b0;
        s0_ext_wr_q <= 1'b0;
      end

      s1_valid_q <= s0_valid_q;
      s1_ext_wr_q <= s0_ext_wr_q;
      s1_seen_mask_q <= s0_seen_mask_q;
      s1_group_mask0_q <= {num_cores{1'b0}};
      s1_group_mask1_q <= {num_cores{1'b0}};
      s1_group_mask2_q <= {num_cores{1'b0}};
      s1_group_mask3_q <= {num_cores{1'b0}};
      s1_group_sum0_q <= {sum_in_bw{1'b0}};
      s1_group_sum1_q <= {sum_in_bw{1'b0}};
      s1_group_sum2_q <= {sum_in_bw{1'b0}};
      s1_group_sum3_q <= {sum_in_bw{1'b0}};
      s1_group_count_q <= 3'd0;

      if (s0_valid_q) begin
        case (s0_group_link_q)
          3'b111: begin
            s1_group_mask0_q <= s0_multicore_mask_q;
            s1_group_sum0_q <= sum01_s0 + sum23_s0;
            s1_group_count_q <= 3'd1;
          end
          3'b101: begin
            s1_group_mask0_q <= s0_multicore_mask_q & 4'b0011;
            s1_group_mask1_q <= s0_multicore_mask_q & 4'b1100;
            s1_group_sum0_q <= sum01_s0;
            s1_group_sum1_q <= sum23_s0;
            s1_group_count_q <= 3'd2;
          end
          3'b010: begin
            s1_group_mask0_q <= s0_multicore_mask_q & 4'b0011;
            s1_group_mask1_q <= s0_multicore_mask_q & 4'b0100;
            s1_group_mask2_q <= s0_multicore_mask_q & 4'b1000;
            s1_group_sum0_q <= sum01_s0;
            s1_group_sum1_q <= s0_x2_q;
            s1_group_sum2_q <= s0_x3_q;
            s1_group_count_q <= 3'd3;
          end
          default: begin
            s1_group_mask0_q <= s0_multicore_mask_q & 4'b0001;
            s1_group_mask1_q <= s0_multicore_mask_q & 4'b0010;
            s1_group_mask2_q <= s0_multicore_mask_q & 4'b0100;
            s1_group_mask3_q <= s0_multicore_mask_q & 4'b1000;
            s1_group_sum0_q <= s0_x0_q;
            s1_group_sum1_q <= s0_x1_q;
            s1_group_sum2_q <= s0_x2_q;
            s1_group_sum3_q <= s0_x3_q;
            s1_group_count_q <= 3'd4;
          end
        endcase
      end

      if (s1_valid_q) begin
        group_ready = (0 < s1_group_count_q) &&
                      (|s1_group_mask0_q) &&
                      ((s1_group_mask0_q & s1_seen_mask_q) == s1_group_mask0_q);
        if (group_ready) begin
          for (i = 0; i < num_cores; i = i + 1) begin
            if (s1_group_mask0_q[i]) begin
              sum_out[i*sum_in_bw +: sum_in_bw] <= s1_group_sum0_q;
              sum_valid_out[i] <= 1'b1;
              if (s1_ext_wr_q) begin
                core_sum_to_cores[i*sum_in_bw +: sum_in_bw] <= s1_group_sum0_q;
                core_ext_sum_wr[i] <= 1'b1;
                group_done_mask[i] = 1'b1;
              end
            end
          end
        end

        group_ready = (1 < s1_group_count_q) &&
                      (|s1_group_mask1_q) &&
                      ((s1_group_mask1_q & s1_seen_mask_q) == s1_group_mask1_q);
        if (group_ready) begin
          for (i = 0; i < num_cores; i = i + 1) begin
            if (s1_group_mask1_q[i]) begin
              sum_out[i*sum_in_bw +: sum_in_bw] <= s1_group_sum1_q;
              sum_valid_out[i] <= 1'b1;
              if (s1_ext_wr_q) begin
                core_sum_to_cores[i*sum_in_bw +: sum_in_bw] <= s1_group_sum1_q;
                core_ext_sum_wr[i] <= 1'b1;
                group_done_mask[i] = 1'b1;
              end
            end
          end
        end

        group_ready = (2 < s1_group_count_q) &&
                      (|s1_group_mask2_q) &&
                      ((s1_group_mask2_q & s1_seen_mask_q) == s1_group_mask2_q);
        if (group_ready) begin
          for (i = 0; i < num_cores; i = i + 1) begin
            if (s1_group_mask2_q[i]) begin
              sum_out[i*sum_in_bw +: sum_in_bw] <= s1_group_sum2_q;
              sum_valid_out[i] <= 1'b1;
              if (s1_ext_wr_q) begin
                core_sum_to_cores[i*sum_in_bw +: sum_in_bw] <= s1_group_sum2_q;
                core_ext_sum_wr[i] <= 1'b1;
                group_done_mask[i] = 1'b1;
              end
            end
          end
        end

        group_ready = (3 < s1_group_count_q) &&
                      (|s1_group_mask3_q) &&
                      ((s1_group_mask3_q & s1_seen_mask_q) == s1_group_mask3_q);
        if (group_ready) begin
          for (i = 0; i < num_cores; i = i + 1) begin
            if (s1_group_mask3_q[i]) begin
              sum_out[i*sum_in_bw +: sum_in_bw] <= s1_group_sum3_q;
              sum_valid_out[i] <= 1'b1;
              if (s1_ext_wr_q) begin
                core_sum_to_cores[i*sum_in_bw +: sum_in_bw] <= s1_group_sum3_q;
                core_ext_sum_wr[i] <= 1'b1;
                group_done_mask[i] = 1'b1;
              end
            end
          end
        end

        if (s1_ext_wr_q) begin
          for (i = 0; i < num_cores; i = i + 1) begin
            if (group_done_mask[i])
              core_sum_seen[i] <= 1'b0;
          end
          if (|group_done_mask)
            ext_wr_pending_q <= 1'b0;
        end
      end
    end
  end

endmodule
