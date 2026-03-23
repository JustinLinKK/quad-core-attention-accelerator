// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Modified by Jingbin Lin in ECE 260B Project, UCSD
// Please do not spread this code without permission 
module core (clk, sum_out, sum_in, ext_sum_wr, managed_load_mode, q_load_done, k_load_done, mem_in, out, inst, reset,
             core_status, core_phase, core_busy, mac_done, acc_done,
             div_done, tile_ready_valid, tile_ready_bank, ofifo_valid);

// inst bit mapping:
// [22]=v_fallback, [21]=pmem_bank_cmd,
// [20]=core_enable, [19]=multi_core, [18]=sfp_acc, [17]=sfp_div,
// [16]=b2_cfg_wr, [15:12]=qkmem_add, [11:8]=pmem_add,
// [7]=execute, [6]=load, [5]=qmem_rd, [4]=qmem_wr,
// [3]=kmem_rd, [2]=kmem_wr, [1]=pmem_rd, [0]=pmem_wr.
//
// core_status mapping:
// [0]=load_tile0, [1]=load_tile1, [2]=mac_tile0, [3]=mac_tile1,
// [4]=psum_tile0, [5]=psum_tile1, [6]=norm_tile0, [7]=norm_tile1,
// [8]=sum_valid, [9]=ext_sum_empty,
// [10]=pmem_bank0_ready, [11]=pmem_bank1_ready (1=ready, 0=busy/not-ready).
//
// Clocking note:
// - This module is single-clock (`clk`) internally.
// - Cross-core / cross-phase clock behavior is handled one level up
//   in `fullchip.v` through CDC FIFOs, not inside this module.

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+6;
parameter sum_out_bw = bw_psum+4;
parameter pr = 8;
parameter sum_in_bw = sum_out_bw+2;


input  [sum_in_bw-1:0] sum_in;
input  ext_sum_wr;
input  managed_load_mode;
input  q_load_done;
input  k_load_done;
input  [pr*bw-1:0] mem_in;
input  clk;
input  [22:0] inst;
input  reset;

output [11:0] core_status;
output [sum_out_bw-1:0] sum_out;
output [bw_psum*col-1:0] out;
output [3:0] core_phase;
output core_busy;
output mac_done;
output acc_done;
output div_done;
output tile_ready_valid;
output tile_ready_bank;
output ofifo_valid;

reg   mac_clk_en_latch;
reg   sfp_clk_en_latch;
reg   mac_soft_reset_q;
reg   [4:0] mac_hold_ctr_q;
reg   [3:0] mac_exec_drain_ctr_q;
reg   ofifo_clear_q;
reg   [col-1:0] fifo_wr_q;
reg   sfp_div_req_q;
reg   sfp_div_busy_q;
reg   sfp_div_result_valid_q;
reg   q_compute_bank_sel;
reg   k_compute_bank_sel;
reg   pmem_ready_bank_sel;
reg   pmem_mac_wr_d;
reg   pmem_mac_wr_bank;
reg   [3:0] pmem_mac_wr_add_q;
reg   pmem_mac_gap_q;
reg   qmem_rd_d;
reg   qmem_wr_d;
reg   kmem_wr_d;
reg   q_bank_switch_pending;
reg   k_bank_switch_pending;
reg   tile_inflight; // Indicates a tile is in-flight between execute start and PMEM write completion.
reg   pmem_ready_valid;
reg   [sum_out_bw-1:0] threshold_bank0_q;
reg   [sum_out_bw-1:0] threshold_bank1_q;

// Two-bank local memories:
// - q_compute_bank_sel / k_compute_bank_sel: bank currently consumed by MAC.
// - Opposite bank is the load target for next tile.
// - pmem_ready_bank_sel: bank that holds the finished tile result for SFP.
// - pmem_mac_wr_bank: bank captured at MAC->PMEM burst start, so PMEM write
//   stays on one bank even if load-side selectors later change.

wire   [bw_psum*col-1:0] pmem_out;
wire   [bw_psum*col-1:0] pmem_out_0;
wire   [bw_psum*col-1:0] pmem_out_1;
wire  [pr*bw-1:0] mac_in;
wire  [pr*bw-1:0] kmem_out;
wire  [pr*bw-1:0] qmem_out;
wire  [pr*bw-1:0] qmem_mac_in;
wire  [pr*bw-1:0] qmem_out_0;
wire  [pr*bw-1:0] qmem_out_1;
wire  [pr*bw-1:0] kmem_out_0;
wire  [pr*bw-1:0] kmem_out_1;
wire  [bw_psum*col-1:0] pmem_in;
wire  [bw_psum*col-1:0] fifo_out;
wire  [bw_psum*col-1:0] sfp_out;
wire  [bw_psum*col-1:0] array_out;
wire  [col-1:0] fifo_wr;
wire  fifo_valid;
wire  ofifo_rd;
wire  ofifo_reset;
wire [3:0] qkmem_add;
wire [3:0] kmem_add;
wire [3:0] pmem_add;
wire  qmem_rd;
wire  qmem_rd_req;
wire  qmem_wr; 
wire  qmem_wr_req;
wire  kmem_rd;
wire  kmem_rd_req;
wire  kmem_wr; 
wire  kmem_wr_req;
wire  pmem_rd;
wire  pmem_rd_req;
wire  pmem_wr; 
wire  pmem_wr_cmd;
wire  pmem_wr_req;
wire  pmem_bank_cmd;
wire  b2_cfg_wr;
wire  b2_cfg_bank_sel;
wire  v_fallback_req;
wire  kmem_tile_wr;
wire  qmem0_cen;
wire  qmem1_cen;
wire  kmem0_cen;
wire  kmem1_cen;
wire  pmem0_cen;
wire  pmem1_cen;
wire  qmem0_wen;
wire  qmem1_wen;
wire  kmem0_wen;
wire  kmem1_wen;
wire  pmem0_wen;
wire  pmem1_wen;
wire  sfp_pmem_mode;
wire  pmem_ready_access;
wire  pmem_bank_sel;
wire  pmem_mac_active;
wire  pmem_mac_last_commit;
wire  pmem_mac_wr;
wire  core_enable;
wire  multi_core;
wire  sfp_acc;
wire  sfp_div;
wire  sfp_div_start_int;
wire  sfp_div_busy_int;
wire  sfp_div_pmem_mode;
wire  sum_valid_int;
wire  ext_sum_empty_int;
wire  sfp_div_done_int;
wire [sum_out_bw-1:0] sum_out_int;
wire  mac_exec_int;
wire  mac_active;
wire  mac_active_req;
wire  sfp_active;
wire  sfp_active_req;
wire  mac_clk_g;
wire  sfp_clk_g;
wire  mac_reset_int;
wire [col-1:0] fifo_wr_raw;
wire [bw_psum*col-1:0] array_out_raw;
wire [pr*bw-1:0] kmem_fallback_in;
wire [pr*bw-1:0] kmem_write_data;
wire [3:0] pmem_add_eff;
wire [sum_out_bw-1:0] threshold_cfg_value_w;
wire [sum_out_bw-1:0] threshold_bank0_prog_w;
wire [sum_out_bw-1:0] threshold_bank1_prog_w;
wire threshold_apply_bank_sel_w;
wire threshold_apply_wr_w;
wire [sum_out_bw-1:0] threshold_apply_value_w;
localparam integer sfp_div_stages = (bw_psum + 1) / 2;
localparam integer sfp_div_data_latency = 3 * sfp_div_stages;
localparam integer sfp_div_done_latency = sfp_div_data_latency + 1;
localparam integer sfp_pipe_hold_cycles = sfp_div_done_latency;
localparam integer sfp_hold_ctr_w = (sfp_pipe_hold_cycles <= 1) ? 1 : $clog2(sfp_pipe_hold_cycles + 1);
reg [sfp_hold_ctr_w-1:0] sfp_hold_ctr_q;
localparam [3:0] core_phase_idle      = 4'd0;
localparam [3:0] core_phase_load      = 4'd1;
localparam [3:0] core_phase_mac       = 4'd2;
localparam [3:0] core_phase_pmem_wr   = 4'd3;
localparam [3:0] core_phase_acc       = 4'd4;
localparam [3:0] core_phase_wait_ext  = 4'd5;
localparam [3:0] core_phase_div       = 4'd6;
localparam [3:0] core_phase_fallback  = 4'd7;
reg [3:0] core_phase_int;

// -----------------------------------------------------------------------------
// Helper functions for 2-bank SRAM control equations.
// -----------------------------------------------------------------------------
// Ping-pong CEN (chip enable for read) helper (active-low).
// Meaning:
// - `compute_sel`: current read bank.
// - write target: opposite bank.
// - cen means "Chip Enable Not", so active-low.
// Example (`compute_sel=0`): 
// - bank0 is selected to read and stream out to MAC, so bank0 must be enabled for read but not write.
// - in this case, bank1 should be enabled for write (if `wr_en` is high) but not read (if `rd_en` is high) to take new tile data
// - bank_id=0, rd_en=1, wr_en=0 -> CEN=0 (enable bank0 for read)
// - bank_id=1, rd_en=0, wr_en=1 -> CEN=0 (enable bank1 for write)
// - bank_id=0, rd_en=0, wr_en=1 -> CEN=1 (bank0 disabled for write)
function bank_cen_pingpong;
  input compute_sel;
  input bank_id;
  input rd_en;
  input wr_en;
  begin
    bank_cen_pingpong = !(((compute_sel == bank_id) && rd_en) || ((compute_sel != bank_id) && wr_en));
  end
endfunction

// Ping-pong WEN (write enable) helper (active-low).
// Example (`compute_sel=1`, so write target is bank0):
// - bank_id=0, wr_en=1 -> WEN=0 (write allowed)
// - bank_id=1, wr_en=1 -> WEN=1 (write blocked)
function bank_wen_pingpong;
  input compute_sel;
  input bank_id;
  input wr_en;
  begin
    bank_wen_pingpong = !((compute_sel != bank_id) && wr_en);
  end
endfunction

// Direct-select CEN helper (active-low).
// Meaning:
// - `bank_sel`: explicitly selected PMEM bank.
// Example (`bank_sel=1`):
// - bank_id=1, rd_en=1, wr_en=0 -> CEN=0
// - bank_id=1, rd_en=0, wr_en=1 -> CEN=0
// - bank_id=0, rd_en=1, wr_en=1 -> CEN=1 (not selected)
function bank_cen_direct;
  input bank_sel;
  input bank_id;
  input rd_en;
  input wr_en;
  begin
    bank_cen_direct = !((bank_sel == bank_id) && (rd_en || wr_en));
  end
endfunction

// Direct-select WEN helper (active-low).
// Example (`bank_sel=0`, wr_en=1):
// - bank_id=0 -> WEN=0 (selected bank writes)
// - bank_id=1 -> WEN=1 (other bank does not write)
function bank_wen_direct;
  input bank_sel;
  input bank_id;
  input wr_en;
  begin
    bank_wen_direct = !((bank_sel == bank_id) && wr_en);
  end
endfunction

// -----------------------------------------------------------------------------
// inst_decode: decode instruction bits and gate by core_enable.
// -----------------------------------------------------------------------------
assign out = pmem_out;
assign qkmem_add = inst[15:12];
assign kmem_add = qkmem_add;
assign pmem_add = inst[11:8];
assign qmem_rd_req = inst[5]; 
assign qmem_wr_req = inst[4]; 
assign kmem_rd_req = inst[3]; 
assign kmem_wr_req = inst[2];
assign pmem_rd_req = inst[1];
assign pmem_wr_req = inst[0];
assign b2_cfg_wr = inst[16] && core_enable;
assign b2_cfg_bank_sel = qkmem_add[0];
assign pmem_bank_cmd = inst[21];
assign v_fallback_req = inst[22] && core_enable;
assign core_enable = inst[20];
assign multi_core = inst[19] && core_enable;
// And operation on below control signals with core_enable to ensure no activity when core is disabled.
assign sfp_acc = inst[18] && core_enable;
assign sfp_div = inst[17] && core_enable;
// OFIFO pop is internally driven when MAC results are being consumed into PMEM.
assign ofifo_rd = pmem_mac_wr;
// All memory read/wire are single wire since we handle internal pingpong control inside the core.
assign qmem_rd = qmem_rd_req && core_enable;
assign qmem_wr = qmem_wr_req && core_enable;
assign kmem_rd = kmem_rd_req && core_enable;
assign kmem_tile_wr = kmem_wr_req && core_enable;
assign kmem_wr = kmem_tile_wr || v_fallback_req;
assign pmem_rd = (pmem_rd_req && core_enable) || v_fallback_req;
assign pmem_wr_cmd = pmem_wr_req && core_enable;
assign pmem_wr = (pmem_wr_cmd && sfp_pmem_mode) || pmem_mac_wr_d;

// -----------------------------------------------------------------------------
// bank_scheduler: choose active banks and publish state/status.
// -----------------------------------------------------------------------------
assign sfp_div_start_int = sfp_div && !sfp_div_req_q && !sfp_div_busy_q && !sfp_div_result_valid_q;
assign sfp_div_busy_int = sfp_div_start_int || sfp_div_busy_q;
assign sfp_div_pmem_mode = sfp_div_busy_int || sfp_div_result_valid_q;
assign sfp_pmem_mode = sfp_acc || sfp_div_pmem_mode;
assign pmem_ready_access = (pmem_rd && pmem_ready_valid && !pmem_bank_cmd &&
                            !pmem_mac_wr && !pmem_mac_wr_d && !pmem_mac_gap_q &&
                            !inst[7] && !inst[6] && !qmem_rd && !kmem_rd) ||
                           sfp_pmem_mode || v_fallback_req;
// PMEM bank policy:
// - SFP path reads/writes the most recently completed PMEM bank.
// - MAC write path uses the bank captured at burst start.
// - Otherwise PMEM follows the active compute tile bank.
assign pmem_bank_sel = (pmem_bank_cmd && (pmem_rd || v_fallback_req)) ? qkmem_add[0] :
                       (pmem_ready_access ? pmem_ready_bank_sel :
                        (pmem_mac_wr_d ? pmem_mac_wr_bank : q_compute_bank_sel));
assign pmem_mac_wr = pmem_wr_cmd && !sfp_pmem_mode && fifo_valid && !pmem_mac_wr_d;
assign pmem_mac_active = pmem_mac_wr || pmem_mac_wr_d || pmem_mac_gap_q;
assign pmem_mac_last_commit = pmem_mac_gap_q && !pmem_mac_wr;
assign core_status[0] = (qmem_wr && q_compute_bank_sel) || (kmem_tile_wr && k_compute_bank_sel);             // load_tile0
assign core_status[1] = (qmem_wr && !q_compute_bank_sel) || (kmem_tile_wr && !k_compute_bank_sel);           // load_tile1
assign core_status[2] = inst[7] && !q_compute_bank_sel;                                                      // mac_tile0
assign core_status[3] = inst[7] && q_compute_bank_sel;                                                       // mac_tile1
assign core_status[4] = pmem_mac_wr_d && !pmem_bank_sel;                          // psum_tile0_write_activity
assign core_status[5] = pmem_mac_wr_d && pmem_bank_sel;                           // psum_tile1_write_activity
assign core_status[6] = sfp_pmem_mode && (pmem_rd || pmem_wr) && !pmem_bank_sel; // norm_tile0
assign core_status[7] = sfp_pmem_mode && (pmem_rd || pmem_wr) && pmem_bank_sel;  // norm_tile1
assign core_status[8] = core_enable && sum_valid_int;                             // sum_valid
assign core_status[9] = core_enable ? ext_sum_empty_int : 1'b1;                   // ext_sum_empty
assign core_status[10] = core_enable && pmem_ready_valid && !pmem_ready_bank_sel;  // pmem_bank0_ready
assign core_status[11] = core_enable && pmem_ready_valid && pmem_ready_bank_sel;   // pmem_bank1_ready
assign sum_out = core_enable ? sum_out_int : {sum_out_bw{1'b0}};                 // zero output when core is disabled
assign core_phase = core_phase_int;
assign core_busy = core_enable &&
                   (qmem_wr || kmem_tile_wr || inst[7] || pmem_mac_active || sfp_acc ||
                    sfp_div_pmem_mode || v_fallback_req || tile_inflight || mac_active ||
                    sfp_active || q_bank_switch_pending || k_bank_switch_pending ||
                    (multi_core && !ext_sum_empty_int));
assign mac_done = core_enable && pmem_mac_last_commit;
assign acc_done = core_enable && sum_valid_int;
assign div_done = core_enable && sfp_div_done_int;
assign tile_ready_valid = core_enable && pmem_ready_valid;
assign tile_ready_bank = pmem_ready_bank_sel;
assign ofifo_valid = core_enable && fifo_valid;

assign qmem0_cen = bank_cen_pingpong(q_compute_bank_sel, 1'b0, qmem_rd, qmem_wr);
assign qmem1_cen = bank_cen_pingpong(q_compute_bank_sel, 1'b1, qmem_rd, qmem_wr);
assign kmem0_cen = bank_cen_pingpong(k_compute_bank_sel, 1'b0, kmem_rd, kmem_wr);
assign kmem1_cen = bank_cen_pingpong(k_compute_bank_sel, 1'b1, kmem_rd, kmem_wr);
assign qmem0_wen = bank_wen_pingpong(q_compute_bank_sel, 1'b0, qmem_wr);
assign qmem1_wen = bank_wen_pingpong(q_compute_bank_sel, 1'b1, qmem_wr);
assign kmem0_wen = bank_wen_pingpong(k_compute_bank_sel, 1'b0, kmem_wr);
assign kmem1_wen = bank_wen_pingpong(k_compute_bank_sel, 1'b1, kmem_wr);
assign pmem0_cen = bank_cen_direct(pmem_bank_sel, 1'b0, pmem_rd, pmem_wr); // PMEM uses direct bank select based on active policy.
assign pmem1_cen = bank_cen_direct(pmem_bank_sel, 1'b1, pmem_rd, pmem_wr);
assign pmem0_wen = bank_wen_direct(pmem_bank_sel, 1'b0, pmem_wr);
assign pmem1_wen = bank_wen_direct(pmem_bank_sel, 1'b1, pmem_wr);

// -----------------------------------------------------------------------------
// datapath_wiring: muxes and local clock/isolation enables.
// -----------------------------------------------------------------------------
assign qmem_out = q_compute_bank_sel ? qmem_out_1 : qmem_out_0;
assign kmem_out = k_compute_bank_sel ? kmem_out_1 : kmem_out_0;
assign pmem_out = pmem_bank_sel ? pmem_out_1 : pmem_out_0;
assign pmem_add_eff = pmem_mac_wr_d ? pmem_mac_wr_add_q : pmem_add;
assign mac_exec_int = (inst[7] && qmem_rd) || (mac_exec_drain_ctr_q != 4'd0);
assign qmem_mac_in = (mac_exec_int && !qmem_rd && !qmem_rd_d) ? {pr*bw{1'b0}} : qmem_out;
assign mac_in  = inst[6] ? kmem_out : qmem_mac_in;
assign pmem_in = sfp_div_pmem_mode ? sfp_out : fifo_out;
assign mac_active_req = core_enable && (mac_exec_int || inst[6]);
assign mac_active = mac_active_req || (mac_hold_ctr_q != 5'd0);
assign sfp_active_req = core_enable && (sfp_acc || sfp_div_busy_int || ext_sum_wr || b2_cfg_wr);
assign sfp_active = sfp_active_req || (sfp_hold_ctr_q != {sfp_hold_ctr_w{1'b0}});
assign mac_reset_int = reset || mac_soft_reset_q;
assign mac_clk_g = clk & (mac_clk_en_latch || mac_reset_int);
assign sfp_clk_g = clk & (sfp_clk_en_latch || reset);
// Operand isolation: suppress toggles when block is inactive.
assign fifo_wr = fifo_wr_q;
assign array_out = array_out_raw;
assign kmem_write_data = v_fallback_req ? kmem_fallback_in : mem_in;
assign ofifo_reset = reset || ofifo_clear_q;
assign threshold_cfg_value_w = mem_in[sum_out_bw-1:0];
assign threshold_bank0_prog_w = (b2_cfg_wr && !b2_cfg_bank_sel) ? threshold_cfg_value_w : threshold_bank0_q;
assign threshold_bank1_prog_w = (b2_cfg_wr && b2_cfg_bank_sel) ? threshold_cfg_value_w : threshold_bank1_q;
assign threshold_apply_bank_sel_w = pmem_mac_last_commit ? pmem_mac_wr_bank : pmem_ready_bank_sel;
assign threshold_apply_wr_w = b2_cfg_wr || pmem_mac_last_commit;
assign threshold_apply_value_w = threshold_apply_bank_sel_w ? threshold_bank1_prog_w : threshold_bank0_prog_w;

always @(*) begin
  core_phase_int = core_phase_idle;
  if (core_enable) begin
    if (v_fallback_req)
      core_phase_int = core_phase_fallback;
    else if (sfp_div_pmem_mode)
      core_phase_int = core_phase_div;
    else if (multi_core && !ext_sum_empty_int)
      core_phase_int = core_phase_wait_ext;
    else if (sfp_acc)
      core_phase_int = core_phase_acc;
    else if (pmem_mac_active)
      core_phase_int = core_phase_pmem_wr;
    else if (inst[7] || mac_active)
      core_phase_int = core_phase_mac;
    else if (qmem_wr || kmem_tile_wr)
      core_phase_int = core_phase_load;
  end
end

genvar lane;
generate
  for (lane = 0; lane < pr; lane = lane + 1)
  begin : kmem_fallback_pack
    assign kmem_fallback_in[(lane*bw) +: bw] = pmem_out[((col-1-lane)*bw_psum) +: bw];
  end
endgenerate

always @ (clk or mac_active or reset)
begin
  if (reset)
    mac_clk_en_latch <= 1'b0;
  else if (!clk)
    mac_clk_en_latch <= mac_active;
end

always @ (clk or sfp_active or reset)
begin
  if (reset)
    sfp_clk_en_latch <= 1'b0;
  else if (!clk)
    sfp_clk_en_latch <= sfp_active;
end

mac_array #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) mac_array_instance (
        .in(mac_in), 
        .clk(mac_clk_g), 
        .reset(mac_reset_int), 
        .inst({mac_exec_int, inst[6]}),     
        .fifo_wr(fifo_wr_raw),     
	.out(array_out_raw)
);

ofifo #(.bw(bw_psum), .col(col))  ofifo_inst (
        .reset(ofifo_reset),
        .clk(clk),
        .in(array_out),
        .wr(fifo_wr),
        .rd(ofifo_rd),
        .o_valid(fifo_valid),
        .out(fifo_out)
);

sfp_optimized #(
        .col(col),
        .bw(bw),
        .bw_psum(bw_psum),
        .sum_out_bw(sum_out_bw),
        .sum_in_bw(sum_in_bw)
      ) sfp_row_inst (
        .clk(sfp_clk_g),
        .reset(reset),
        .acc(sfp_acc),
        .div(sfp_div_start_int),
        .multi_core(multi_core),
        .ext_sum_wr(ext_sum_wr),
        .threshold_sum_wr(threshold_apply_wr_w),
        .threshold_sum_in(threshold_apply_value_w),
        .sum_in(sum_in),
        .sum_out(sum_out_int),
        .sum_valid(sum_valid_int),
        .ext_sum_empty(ext_sum_empty_int),
        .div_done(sfp_div_done_int),
        .sfp_in(pmem_out),
        .sfp_out(sfp_out)
);


sram_64b_w16 qmem_instance_0 (
        .CLK(clk),
        .D(mem_in),
        .Q(qmem_out_0),
        .CEN(qmem0_cen),
        .WEN(qmem0_wen), 
        .A(qkmem_add)
);

sram_64b_w16 qmem_instance_1 (
        .CLK(clk),
        .D(mem_in),
        .Q(qmem_out_1),
        .CEN(qmem1_cen),
        .WEN(qmem1_wen), 
        .A(qkmem_add)
);

sram_64b_w16 kmem_instance_0 (
        .CLK(clk),
        .D(kmem_write_data),
        .Q(kmem_out_0),
        .CEN(kmem0_cen),
        .WEN(kmem0_wen), 
        .A(kmem_add)
);

sram_64b_w16 kmem_instance_1 (
        .CLK(clk),
        .D(kmem_write_data),
        .Q(kmem_out_1),
        .CEN(kmem1_cen),
        .WEN(kmem1_wen), 
        .A(kmem_add)
);

sram_176b_w16 psum_mem_instance_0 (
        .CLK(clk),
        .D(pmem_in),
        .Q(pmem_out_0),
        .CEN(pmem0_cen),
        .WEN(pmem0_wen), 
        .A(pmem_add_eff)
);

sram_176b_w16 psum_mem_instance_1 (
        .CLK(clk),
        .D(pmem_in),
        .Q(pmem_out_1),
        .CEN(pmem1_cen),
        .WEN(pmem1_wen), 
        .A(pmem_add_eff)
);



  // Tile/bank sequencer:
  // 1) Detect end of Q/K load burst and request promotion.
  // 2) If no tile is in-flight, apply pending promotion immediately.
  // 3) Mark tile in-flight on execute, clear on PMEM MAC burst completion.
  // 4) Publish completed PMEM bank to SFP through pmem_ready_bank_sel.
  always @(posedge clk) begin
      if (reset) begin
         mac_soft_reset_q <= 1'b0;
         mac_hold_ctr_q <= 5'd0;
         mac_exec_drain_ctr_q <= 4'd0;
         ofifo_clear_q <= 1'b0;
         fifo_wr_q <= {col{1'b0}};
         sfp_div_req_q <= 1'b0;
         sfp_div_busy_q <= 1'b0;
         sfp_div_result_valid_q <= 1'b0;
         sfp_hold_ctr_q <= {sfp_hold_ctr_w{1'b0}};
         q_compute_bank_sel <= 1'b0;
         k_compute_bank_sel <= 1'b0;
         pmem_ready_bank_sel <= 1'b0;
         pmem_mac_wr_d <= 1'b0;
         pmem_mac_wr_bank <= 1'b0;
         pmem_mac_wr_add_q <= 4'd0;
         pmem_mac_gap_q <= 1'b0;
         qmem_rd_d <= 1'b0;
         qmem_wr_d <= 1'b0;
         kmem_wr_d <= 1'b0;
         q_bank_switch_pending <= 1'b0;
         k_bank_switch_pending <= 1'b0;
         tile_inflight <= 1'b0;
         pmem_ready_valid <= 1'b0;
         threshold_bank0_q <= {sum_out_bw{1'b0}};
         threshold_bank1_q <= {sum_out_bw{1'b0}};
      end else begin
         mac_soft_reset_q <= 1'b0;
         ofifo_clear_q <= 1'b0;
         sfp_div_req_q <= sfp_div;
         if (mac_active_req)
            mac_hold_ctr_q <= col + 1;
         else if (mac_hold_ctr_q != 5'd0)
            mac_hold_ctr_q <= mac_hold_ctr_q - 1'b1;
         if (sfp_div_start_int) begin
            sfp_div_busy_q <= 1'b1;
            sfp_div_result_valid_q <= 1'b0;
         end
         if (sfp_div_done_int)
            sfp_div_busy_q <= 1'b0;
         if (pmem_wr && (sfp_div_result_valid_q || sfp_div_done_int))
            sfp_div_result_valid_q <= 1'b0;
         else if (sfp_div_done_int)
            sfp_div_result_valid_q <= 1'b1;
         if (core_enable && inst[7] && qmem_rd)
            mac_exec_drain_ctr_q <= col - 1;
         else if (mac_exec_drain_ctr_q != 4'd0)
            mac_exec_drain_ctr_q <= mac_exec_drain_ctr_q - 1'b1;
         fifo_wr_q <= fifo_wr_raw;
         if (sfp_active_req)
            sfp_hold_ctr_q <= sfp_pipe_hold_cycles - 1;
         else if (sfp_hold_ctr_q != {sfp_hold_ctr_w{1'b0}})
            sfp_hold_ctr_q <= sfp_hold_ctr_q - 1'b1;
         if (b2_cfg_wr) begin
            if (b2_cfg_bank_sel)
               threshold_bank1_q <= threshold_cfg_value_w;
            else
               threshold_bank0_q <= threshold_cfg_value_w;
         end
         // Hold compute-bank promotion while a tile is in flight.
         // This prevents load completion of tile N+1 from changing
         // read/write banks before tile N PMEM writeback has finished.
         if (!tile_inflight) begin // No tile in-flight, so allow any pending bank switch to take effect.
            if (q_bank_switch_pending) begin
               q_compute_bank_sel <= ~q_compute_bank_sel;
               q_bank_switch_pending <= 1'b0;
            end
            if (k_bank_switch_pending) begin
               k_compute_bank_sel <= ~k_compute_bank_sel;
               k_bank_switch_pending <= 1'b0;
            end
         end
         if (q_load_done || (!managed_load_mode && qmem_wr_d && !qmem_wr)) begin // Q-mem tile load finished, so request bank switch on next cycle.
            if (tile_inflight)
               q_bank_switch_pending <= 1'b1;
            else
               q_compute_bank_sel <= ~q_compute_bank_sel;
         end
         if (k_load_done || (!managed_load_mode && kmem_wr_d && !kmem_wr)) begin // Any K-mem tile load burst finished, so request bank switch on next cycle.
            if (tile_inflight)
               k_bank_switch_pending <= 1'b1;
            else
               k_compute_bank_sel <= ~k_compute_bank_sel;
         end
         qmem_rd_d <= qmem_rd;
         qmem_wr_d <= qmem_wr; // Capture current Q-mem write to detect burst end.
         kmem_wr_d <= kmem_wr; // Capture any K-mem write to detect burst end, including fallback.

         // Tile is considered in-flight from execute start until
         // PMEM MAC write burst completion.
         if (inst[7]) begin // Execute starts on inst[7], so mark tile in-flight.
            tile_inflight <= 1'b1;
            pmem_ready_valid <= 1'b0;
         end

         if (pmem_mac_gap_q && pmem_mac_wr)
            pmem_mac_gap_q <= 1'b0;
         // At MAC dequeue request, capture target bank and PMEM row for the
         // following-cycle write commit.
         if (pmem_mac_wr) begin
            pmem_mac_wr_bank <= q_compute_bank_sel;
            pmem_mac_wr_add_q <= pmem_add;
         end
         // On the last MAC commit, expose that bank to the SFP side.
         if (pmem_mac_last_commit) begin
            pmem_ready_bank_sel <= pmem_mac_wr_bank;
            tile_inflight <= 1'b0;
            pmem_ready_valid <= 1'b1;
            ofifo_clear_q <= 1'b1;
            mac_soft_reset_q <= 1'b1;
            pmem_mac_gap_q <= 1'b0;
         end
         if (pmem_mac_wr_d && !pmem_mac_wr)
            pmem_mac_gap_q <= 1'b1;
         pmem_mac_wr_d <= pmem_mac_wr;
      end
  end

  // Debug print for PMEM write traffic.
  always @(posedge clk) begin
      if(pmem_wr)
         $display("Memory write to PSUM mem add %x %x ", pmem_add_eff, pmem_in); 
  end



endmodule
