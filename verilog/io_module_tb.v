`timescale 1ns/1ps

module io_module_tb;

reg clk;
reg adder_clk;
reg reset;
reg rx_valid;
reg [63:0] rx_data;
wire rx_ready;
wire tx_valid;
wire [63:0] tx_data;
wire tx_last;
reg tx_ready;

wire [25:0] sum_out_dbg;
wire sum_valid_dbg;
wire ext_sum_empty_dbg;
wire [703:0] out_dbg;
wire [47:0] core_status_dbg;

fullchip_future u_dut (
    .clk(clk),
    .adder_clk(adder_clk),
    .core_clk({4{clk}}),
    .mem_in(64'd0),
    .mem_in_mask(4'b1111),
    .core_inst({4{24'd0}}),
    .reset(reset),
    .half_precision(1'b0),
    .group_link(3'd0),
    .ext_sum_wr(1'b0),
    .sum_in(28'd0),
    .sum_out(sum_out_dbg),
    .sum_valid(sum_valid_dbg),
    .ext_sum_empty(ext_sum_empty_dbg),
    .out(out_dbg),
    .core_status(core_status_dbg),
    .use_io_ctrl(1'b1),
    .rx_valid(rx_valid),
    .rx_data(rx_data),
    .rx_ready(rx_ready),
    .tx_valid(tx_valid),
    .tx_data(tx_data),
    .tx_last(tx_last),
    .tx_ready(tx_ready)
);

always #5 clk = ~clk;
always #4 adder_clk = ~adder_clk;

task push_word;
    input [63:0] w;
    begin
        @(posedge clk);
        while (!rx_ready) @(posedge clk);
        rx_data <= w;
        rx_valid <= 1'b1;
        @(posedge clk);
        rx_valid <= 1'b0;
        rx_data <= 64'd0;
    end
endtask

integer i;
initial begin
    clk = 1'b0;
    adder_clk = 1'b0;
    reset = 1'b1;
    rx_valid = 1'b0;
    rx_data = 64'd0;
    tx_ready = 1'b1;

    repeat (4) @(posedge clk);
    reset = 1'b0;

    // 1) Setup command
    push_word({8'h01, 37'd0, 4'b1111, 4'b1111, 3'b001, 4'b0011, 4'b1111});

    // 2) Load K for cores 0 and 1, length=2 vectors.
    push_word({8'h10, 43'd0, 8'd2, 4'b0011, 1'b0});
    push_word(64'h0102_0304_0506_0708);
    push_word(64'h1112_1314_1516_1718);

    // 3) Load Q for cores 0 and 1, length=2 vectors.
    push_word({8'h10, 43'd0, 8'd2, 4'b0011, 1'b1});
    push_word(64'h2122_2324_2526_2728);
    push_word(64'h3132_3334_3536_3738);

    // 4) Run MAC + SFP_ACC with q_len=2, k_len=2.
    push_word({8'h20, 40'd0, 8'd2, 8'd2});

    // 5) Run DIV + output for rows=2.
    push_word({8'h21, 48'd0, 8'd2});

    // 6) Observe responses/output words.
    for (i = 0; i < 60; i = i + 1) begin
        @(posedge clk);
        if (tx_valid && tx_ready)
            $display("tx: data=%h last=%b", tx_data, tx_last);
    end

    $finish;
end

endmodule
