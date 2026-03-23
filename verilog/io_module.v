module io_module (
    clk,
    reset,
    rx_valid,
    rx_data,
    rx_ready,
    tx_valid,
    tx_data,
    tx_last,
    tx_ready,
    mem_in,
    mem_in_mask,
    inst,
    multi_core_inst,
    core_enable_mask,
    group_link,
    sfp_acc_inst,
    sfp_div_inst,
    ext_sum_wr,
    sum_in,
    sum_out,
    sum_valid,
    ext_sum_empty,
    out,
    core_status
);

parameter num_cores = 4;
parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+6;
parameter sum_out_bw = bw_psum + 4;
parameter sum_in_bw = sum_out_bw + 2;

input clk;
input reset;
input rx_valid;
input [63:0] rx_data;
output rx_ready;
output tx_valid;
output [63:0] tx_data;
output tx_last;
input tx_ready;

output [63:0] mem_in;
output [num_cores-1:0] mem_in_mask;
output [16:0] inst;
output [num_cores-1:0] multi_core_inst;
output [num_cores-1:0] core_enable_mask;
output [num_cores-2:0] group_link;
output [num_cores-1:0] sfp_acc_inst;
output [num_cores-1:0] sfp_div_inst;
output ext_sum_wr;
output [sum_in_bw-1:0] sum_in;

input [sum_out_bw-1:0] sum_out;
input sum_valid;
input ext_sum_empty;
input [bw_psum*col-1:0] out;
input [num_cores*12-1:0] core_status;

workproc_controller #(
    .num_cores(num_cores),
    .col(col),
    .bw(bw),
    .bw_psum(bw_psum),
    .sum_out_bw(sum_out_bw),
    .sum_in_bw(sum_in_bw)
) u_workproc_controller (
    .clk(clk),
    .reset(reset),
    .rx_valid(rx_valid),
    .rx_data(rx_data),
    .rx_ready(rx_ready),
    .tx_valid(tx_valid),
    .tx_data(tx_data),
    .tx_last(tx_last),
    .tx_ready(tx_ready),
    .mem_in(mem_in),
    .mem_in_mask(mem_in_mask),
    .inst(inst),
    .multi_core_inst(multi_core_inst),
    .core_enable_mask(core_enable_mask),
    .group_link(group_link),
    .sfp_acc_inst(sfp_acc_inst),
    .sfp_div_inst(sfp_div_inst),
    .ext_sum_wr(ext_sum_wr),
    .sum_in(sum_in),
    .sum_out(sum_out),
    .sum_valid(sum_valid),
    .ext_sum_empty(ext_sum_empty),
    .out(out),
    .core_status(core_status)
);

endmodule
