/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : K-2015.06-SP2
// Date      : Sat Mar 21 13:36:54 2026
/////////////////////////////////////////////////////////////


module fullchip_spad_controller ( clk, reset, cfg_core_enable_mask, load_start, 
        load_is_q, load_core_mask, load_len, load_base, run_start, run_q_len, 
        run_k_len, core_agent_busy, cmd_valid, cmd_ready, cmd_core_mask, 
        cmd_payload_core_zero, cmd_payload_core_one, cmd_payload_core_two, 
        cmd_payload_core_three, load_row_valid, load_row_ready, 
        load_row_core_mask, busy, done, spad_rd_req_valid, spad_rd_req_ready, 
        spad_rd_addr, spad_rd_rsp_valid, spad_rd_rsp_ready );
  input [3:0] cfg_core_enable_mask;
  input [3:0] load_core_mask;
  input [7:0] load_len;
  input [7:0] load_base;
  input [7:0] run_q_len;
  input [7:0] run_k_len;
  input [3:0] core_agent_busy;
  output [3:0] cmd_core_mask;
  output [18:0] cmd_payload_core_zero;
  output [18:0] cmd_payload_core_one;
  output [18:0] cmd_payload_core_two;
  output [18:0] cmd_payload_core_three;
  output [3:0] load_row_core_mask;
  output [7:0] spad_rd_addr;
  input clk, reset, load_start, load_is_q, run_start, cmd_ready,
         load_row_ready, spad_rd_req_ready, spad_rd_rsp_valid;
  output cmd_valid, load_row_valid, busy, done, spad_rd_req_valid,
         spad_rd_rsp_ready;
  wire   active_load_is_q, busy_seen_any, N236, N237, N238, N239, N240, N241,
         N242, N243, N244, N245, N246, N247, N248, N249, N250, N251, N252,
         N253, N254, N255, N256, N257, N258, N259, N260, N261, N262, N263,
         N264, N265, N266, N267, N268, N269, N270, N271, N272, N273, N274,
         N275, N276, N277, N278, N279, N280, N281, N282, N283, N284, N285,
         N286, N287, N288, N289, N290, N291, N292, N293, N294, N352, N353,
         N354, N355, N356, N357, N358, N359, N360, N361, N362, N363, N364,
         N365, N366, N367, N368, N369, N370, N371, N372, N373, N374, N375,
         N376, N377, N378, N379, N380, N381, N382, n3, n83, n84, n85, n86, n87,
         n88, n89, n90, n91, n92, n93, n94, n95, n96, n97, n98, n99, n100,
         n101, n102, n103, n104, n105, n106, n107, n108, n109, n110, n111,
         n112, n113, n114, n115, n116, n117, n118, n119, n120, n121, n122,
         n123, n124, n125, n126, n127, n128, n129, n130, n131, n132, n133,
         n134, n135, n136, n137, n138, n139, n140, n141, n142, n143, n144,
         n145, n146, n147, n148, n149, n150, n151, n152, n153, n154, n155,
         n156, n157, n158, n159, n160, n161, n162, n163, n164, n165, n166,
         n167, n168, n169, n170, n171, n172, n173, n174;
  wire   [2:0] state;
  wire   [3:0] active_cmd_mask;
  wire   [7:0] active_load_len;
  wire   [1:0] active_op;
  wire   [7:0] active_run_k_len;
  wire   [7:0] active_run_q_len;
  wire   [7:0] idx_q;
  wire   [3:0] active_load_base;

  EDFQD1 state_reg_0_ ( .D(N237), .E(N236), .CP(clk), .Q(state[0]) );
  EDFQD1 active_load_is_q_reg ( .D(N241), .E(N240), .CP(clk), .Q(
        active_load_is_q) );
  EDFQD1 active_load_base_reg_3_ ( .D(N258), .E(N240), .CP(clk), .Q(
        active_load_base[3]) );
  EDFQD1 active_load_base_reg_2_ ( .D(N257), .E(N240), .CP(clk), .Q(
        active_load_base[2]) );
  EDFQD1 active_load_base_reg_1_ ( .D(N256), .E(N240), .CP(clk), .Q(
        active_load_base[1]) );
  EDFQD1 active_load_base_reg_0_ ( .D(N255), .E(N240), .CP(clk), .Q(
        active_load_base[0]) );
  EDFQD1 active_load_len_reg_7_ ( .D(N254), .E(N240), .CP(clk), .Q(
        active_load_len[7]) );
  EDFQD1 active_load_len_reg_6_ ( .D(N253), .E(N240), .CP(clk), .Q(
        active_load_len[6]) );
  EDFQD1 active_load_len_reg_5_ ( .D(N252), .E(N240), .CP(clk), .Q(
        active_load_len[5]) );
  EDFQD1 active_load_len_reg_4_ ( .D(N251), .E(N240), .CP(clk), .Q(
        active_load_len[4]) );
  EDFQD1 active_load_len_reg_3_ ( .D(N250), .E(N240), .CP(clk), .Q(
        active_load_len[3]) );
  EDFQD1 active_load_len_reg_2_ ( .D(N249), .E(N240), .CP(clk), .Q(
        active_load_len[2]) );
  EDFQD1 active_load_len_reg_1_ ( .D(N248), .E(N240), .CP(clk), .Q(
        active_load_len[1]) );
  EDFQD1 active_load_len_reg_0_ ( .D(N247), .E(N240), .CP(clk), .Q(
        active_load_len[0]) );
  EDFQD1 active_run_q_len_reg_0_ ( .D(N260), .E(N259), .CP(clk), .Q(
        active_run_q_len[0]) );
  EDFQD1 active_run_k_len_reg_7_ ( .D(N275), .E(N259), .CP(clk), .Q(
        active_run_k_len[7]) );
  EDFQD1 active_run_k_len_reg_6_ ( .D(N274), .E(N259), .CP(clk), .Q(
        active_run_k_len[6]) );
  EDFQD1 active_run_k_len_reg_5_ ( .D(N273), .E(N259), .CP(clk), .Q(
        active_run_k_len[5]) );
  EDFQD1 active_run_k_len_reg_4_ ( .D(N272), .E(N259), .CP(clk), .Q(
        active_run_k_len[4]) );
  EDFQD1 active_run_k_len_reg_3_ ( .D(N271), .E(N259), .CP(clk), .Q(
        active_run_k_len[3]) );
  EDFQD1 active_run_k_len_reg_2_ ( .D(N270), .E(N259), .CP(clk), .Q(
        active_run_k_len[2]) );
  EDFQD1 active_run_k_len_reg_1_ ( .D(N269), .E(N259), .CP(clk), .Q(
        active_run_k_len[1]) );
  EDFQD1 active_run_k_len_reg_0_ ( .D(N268), .E(N259), .CP(clk), .Q(
        active_run_k_len[0]) );
  EDFQD1 active_run_q_len_reg_7_ ( .D(N267), .E(N259), .CP(clk), .Q(
        active_run_q_len[7]) );
  EDFQD1 active_run_q_len_reg_6_ ( .D(N266), .E(N259), .CP(clk), .Q(
        active_run_q_len[6]) );
  EDFQD1 active_run_q_len_reg_5_ ( .D(N265), .E(N259), .CP(clk), .Q(
        active_run_q_len[5]) );
  EDFQD1 active_run_q_len_reg_4_ ( .D(N264), .E(N259), .CP(clk), .Q(
        active_run_q_len[4]) );
  EDFQD1 active_run_q_len_reg_3_ ( .D(N263), .E(N259), .CP(clk), .Q(
        active_run_q_len[3]) );
  EDFQD1 active_run_q_len_reg_2_ ( .D(N262), .E(N259), .CP(clk), .Q(
        active_run_q_len[2]) );
  EDFQD1 active_run_q_len_reg_1_ ( .D(N261), .E(N259), .CP(clk), .Q(
        active_run_q_len[1]) );
  EDFQD1 active_cmd_mask_reg_0_ ( .D(N243), .E(N242), .CP(clk), .Q(
        active_cmd_mask[0]) );
  EDFQD1 active_op_reg_1_ ( .D(N286), .E(N242), .CP(clk), .Q(active_op[1]) );
  EDFQD1 active_op_reg_0_ ( .D(N285), .E(N242), .CP(clk), .Q(active_op[0]) );
  EDFQD1 active_cmd_mask_reg_3_ ( .D(N246), .E(N242), .CP(clk), .Q(
        active_cmd_mask[3]) );
  EDFQD1 active_cmd_mask_reg_2_ ( .D(N245), .E(N242), .CP(clk), .Q(
        active_cmd_mask[2]) );
  EDFQD1 active_cmd_mask_reg_1_ ( .D(N244), .E(N242), .CP(clk), .Q(
        active_cmd_mask[1]) );
  EDFQD1 busy_seen_any_reg ( .D(N287), .E(N288), .CP(clk), .Q(busy_seen_any)
         );
  EDFQD1 idx_q_reg_2_ ( .D(N279), .E(N276), .CP(clk), .Q(idx_q[2]) );
  EDFQD1 idx_q_reg_4_ ( .D(N281), .E(N276), .CP(clk), .Q(idx_q[4]) );
  EDFQD1 idx_q_reg_6_ ( .D(N283), .E(N276), .CP(clk), .Q(idx_q[6]) );
  EDFQD1 idx_q_reg_3_ ( .D(N280), .E(N276), .CP(clk), .Q(idx_q[3]) );
  EDFQD1 idx_q_reg_5_ ( .D(N282), .E(N276), .CP(clk), .Q(idx_q[5]) );
  EDFQD1 idx_q_reg_7_ ( .D(N284), .E(N276), .CP(clk), .Q(idx_q[7]) );
  DFQD1 load_row_core_mask_reg_0_ ( .D(N372), .CP(clk), .Q(
        load_row_core_mask[0]) );
  DFQD1 load_row_core_mask_reg_1_ ( .D(N373), .CP(clk), .Q(
        load_row_core_mask[1]) );
  DFQD1 load_row_core_mask_reg_2_ ( .D(N374), .CP(clk), .Q(
        load_row_core_mask[2]) );
  DFQD1 load_row_core_mask_reg_3_ ( .D(N375), .CP(clk), .Q(
        load_row_core_mask[3]) );
  DFQD1 load_row_valid_reg ( .D(N371), .CP(clk), .Q(load_row_valid) );
  EDFQD1 state_reg_2_ ( .D(N239), .E(N236), .CP(clk), .Q(state[2]) );
  EDFQD1 state_reg_1_ ( .D(N238), .E(N236), .CP(clk), .Q(state[1]) );
  EDFQD1 spad_rd_addr_reg_0_ ( .D(N378), .E(N377), .CP(clk), .Q(
        spad_rd_addr[0]) );
  EDFQD1 spad_rd_addr_reg_1_ ( .D(N379), .E(N377), .CP(clk), .Q(
        spad_rd_addr[1]) );
  EDFQD1 spad_rd_addr_reg_2_ ( .D(N380), .E(N377), .CP(clk), .Q(
        spad_rd_addr[2]) );
  EDFQD1 spad_rd_addr_reg_3_ ( .D(N381), .E(N377), .CP(clk), .Q(
        spad_rd_addr[3]) );
  EDFQD1 spad_rd_addr_reg_7_ ( .D(N382), .E(N377), .CP(clk), .Q(
        spad_rd_addr[7]) );
  EDFQD1 spad_rd_addr_reg_4_ ( .D(n3), .E(N377), .CP(clk), .Q(spad_rd_addr[4])
         );
  EDFQD1 spad_rd_addr_reg_5_ ( .D(n3), .E(N377), .CP(clk), .Q(spad_rd_addr[5])
         );
  EDFQD1 spad_rd_addr_reg_6_ ( .D(n3), .E(N377), .CP(clk), .Q(spad_rd_addr[6])
         );
  DFQD1 cmd_valid_reg ( .D(N290), .CP(clk), .Q(cmd_valid) );
  DFQD1 cmd_payload_core_three_reg_16_ ( .D(N368), .CP(clk), .Q(
        cmd_payload_core_three[16]) );
  DFQD1 cmd_payload_core_two_reg_16_ ( .D(N368), .CP(clk), .Q(
        cmd_payload_core_two[16]) );
  DFQD1 cmd_payload_core_one_reg_16_ ( .D(N368), .CP(clk), .Q(
        cmd_payload_core_one[16]) );
  DFQD1 cmd_payload_core_zero_reg_16_ ( .D(N368), .CP(clk), .Q(
        cmd_payload_core_zero[16]) );
  DFQD1 cmd_payload_core_three_reg_8_ ( .D(N360), .CP(clk), .Q(
        cmd_payload_core_three[8]) );
  DFQD1 cmd_payload_core_two_reg_8_ ( .D(N360), .CP(clk), .Q(
        cmd_payload_core_two[8]) );
  DFQD1 cmd_payload_core_one_reg_8_ ( .D(N360), .CP(clk), .Q(
        cmd_payload_core_one[8]) );
  DFQD1 cmd_payload_core_zero_reg_8_ ( .D(N360), .CP(clk), .Q(
        cmd_payload_core_zero[8]) );
  DFQD1 cmd_payload_core_three_reg_15_ ( .D(N367), .CP(clk), .Q(
        cmd_payload_core_three[15]) );
  DFQD1 cmd_payload_core_two_reg_15_ ( .D(N367), .CP(clk), .Q(
        cmd_payload_core_two[15]) );
  DFQD1 cmd_payload_core_one_reg_15_ ( .D(N367), .CP(clk), .Q(
        cmd_payload_core_one[15]) );
  DFQD1 cmd_payload_core_zero_reg_15_ ( .D(N367), .CP(clk), .Q(
        cmd_payload_core_zero[15]) );
  DFQD1 cmd_payload_core_three_reg_14_ ( .D(N366), .CP(clk), .Q(
        cmd_payload_core_three[14]) );
  DFQD1 cmd_payload_core_two_reg_14_ ( .D(N366), .CP(clk), .Q(
        cmd_payload_core_two[14]) );
  DFQD1 cmd_payload_core_one_reg_14_ ( .D(N366), .CP(clk), .Q(
        cmd_payload_core_one[14]) );
  DFQD1 cmd_payload_core_zero_reg_14_ ( .D(N366), .CP(clk), .Q(
        cmd_payload_core_zero[14]) );
  DFQD1 cmd_payload_core_three_reg_13_ ( .D(N365), .CP(clk), .Q(
        cmd_payload_core_three[13]) );
  DFQD1 cmd_payload_core_two_reg_13_ ( .D(N365), .CP(clk), .Q(
        cmd_payload_core_two[13]) );
  DFQD1 cmd_payload_core_one_reg_13_ ( .D(N365), .CP(clk), .Q(
        cmd_payload_core_one[13]) );
  DFQD1 cmd_payload_core_zero_reg_13_ ( .D(N365), .CP(clk), .Q(
        cmd_payload_core_zero[13]) );
  DFQD1 cmd_payload_core_three_reg_12_ ( .D(N364), .CP(clk), .Q(
        cmd_payload_core_three[12]) );
  DFQD1 cmd_payload_core_two_reg_12_ ( .D(N364), .CP(clk), .Q(
        cmd_payload_core_two[12]) );
  DFQD1 cmd_payload_core_one_reg_12_ ( .D(N364), .CP(clk), .Q(
        cmd_payload_core_one[12]) );
  DFQD1 cmd_payload_core_zero_reg_12_ ( .D(N364), .CP(clk), .Q(
        cmd_payload_core_zero[12]) );
  DFQD1 cmd_payload_core_three_reg_11_ ( .D(N363), .CP(clk), .Q(
        cmd_payload_core_three[11]) );
  DFQD1 cmd_payload_core_two_reg_11_ ( .D(N363), .CP(clk), .Q(
        cmd_payload_core_two[11]) );
  DFQD1 cmd_payload_core_one_reg_11_ ( .D(N363), .CP(clk), .Q(
        cmd_payload_core_one[11]) );
  DFQD1 cmd_payload_core_zero_reg_11_ ( .D(N363), .CP(clk), .Q(
        cmd_payload_core_zero[11]) );
  DFQD1 cmd_payload_core_three_reg_10_ ( .D(N362), .CP(clk), .Q(
        cmd_payload_core_three[10]) );
  DFQD1 cmd_payload_core_two_reg_10_ ( .D(N362), .CP(clk), .Q(
        cmd_payload_core_two[10]) );
  DFQD1 cmd_payload_core_one_reg_10_ ( .D(N362), .CP(clk), .Q(
        cmd_payload_core_one[10]) );
  DFQD1 cmd_payload_core_zero_reg_10_ ( .D(N362), .CP(clk), .Q(
        cmd_payload_core_zero[10]) );
  DFQD1 cmd_payload_core_three_reg_9_ ( .D(N361), .CP(clk), .Q(
        cmd_payload_core_three[9]) );
  DFQD1 cmd_payload_core_two_reg_9_ ( .D(N361), .CP(clk), .Q(
        cmd_payload_core_two[9]) );
  DFQD1 cmd_payload_core_one_reg_9_ ( .D(N361), .CP(clk), .Q(
        cmd_payload_core_one[9]) );
  DFQD1 cmd_payload_core_zero_reg_9_ ( .D(N361), .CP(clk), .Q(
        cmd_payload_core_zero[9]) );
  DFQD1 cmd_core_mask_reg_0_ ( .D(N291), .CP(clk), .Q(cmd_core_mask[0]) );
  DFQD1 cmd_payload_core_three_reg_18_ ( .D(N370), .CP(clk), .Q(
        cmd_payload_core_three[18]) );
  DFQD1 cmd_payload_core_two_reg_18_ ( .D(N370), .CP(clk), .Q(
        cmd_payload_core_two[18]) );
  DFQD1 cmd_payload_core_one_reg_18_ ( .D(N370), .CP(clk), .Q(
        cmd_payload_core_one[18]) );
  DFQD1 cmd_payload_core_zero_reg_18_ ( .D(N370), .CP(clk), .Q(
        cmd_payload_core_zero[18]) );
  DFQD1 cmd_payload_core_three_reg_17_ ( .D(N369), .CP(clk), .Q(
        cmd_payload_core_three[17]) );
  DFQD1 cmd_payload_core_two_reg_17_ ( .D(N369), .CP(clk), .Q(
        cmd_payload_core_two[17]) );
  DFQD1 cmd_payload_core_one_reg_17_ ( .D(N369), .CP(clk), .Q(
        cmd_payload_core_one[17]) );
  DFQD1 cmd_payload_core_zero_reg_17_ ( .D(N369), .CP(clk), .Q(
        cmd_payload_core_zero[17]) );
  DFQD1 cmd_payload_core_three_reg_7_ ( .D(N359), .CP(clk), .Q(
        cmd_payload_core_three[7]) );
  DFQD1 cmd_payload_core_two_reg_7_ ( .D(N359), .CP(clk), .Q(
        cmd_payload_core_two[7]) );
  DFQD1 cmd_payload_core_one_reg_7_ ( .D(N359), .CP(clk), .Q(
        cmd_payload_core_one[7]) );
  DFQD1 cmd_payload_core_zero_reg_7_ ( .D(N359), .CP(clk), .Q(
        cmd_payload_core_zero[7]) );
  DFQD1 cmd_payload_core_three_reg_6_ ( .D(N358), .CP(clk), .Q(
        cmd_payload_core_three[6]) );
  DFQD1 cmd_payload_core_two_reg_6_ ( .D(N358), .CP(clk), .Q(
        cmd_payload_core_two[6]) );
  DFQD1 cmd_payload_core_one_reg_6_ ( .D(N358), .CP(clk), .Q(
        cmd_payload_core_one[6]) );
  DFQD1 cmd_payload_core_zero_reg_6_ ( .D(N358), .CP(clk), .Q(
        cmd_payload_core_zero[6]) );
  DFQD1 cmd_payload_core_three_reg_5_ ( .D(N357), .CP(clk), .Q(
        cmd_payload_core_three[5]) );
  DFQD1 cmd_payload_core_two_reg_5_ ( .D(N357), .CP(clk), .Q(
        cmd_payload_core_two[5]) );
  DFQD1 cmd_payload_core_one_reg_5_ ( .D(N357), .CP(clk), .Q(
        cmd_payload_core_one[5]) );
  DFQD1 cmd_payload_core_zero_reg_5_ ( .D(N357), .CP(clk), .Q(
        cmd_payload_core_zero[5]) );
  DFQD1 cmd_payload_core_three_reg_4_ ( .D(N356), .CP(clk), .Q(
        cmd_payload_core_three[4]) );
  DFQD1 cmd_payload_core_two_reg_4_ ( .D(N356), .CP(clk), .Q(
        cmd_payload_core_two[4]) );
  DFQD1 cmd_payload_core_one_reg_4_ ( .D(N356), .CP(clk), .Q(
        cmd_payload_core_one[4]) );
  DFQD1 cmd_payload_core_zero_reg_4_ ( .D(N356), .CP(clk), .Q(
        cmd_payload_core_zero[4]) );
  DFQD1 cmd_payload_core_three_reg_3_ ( .D(N355), .CP(clk), .Q(
        cmd_payload_core_three[3]) );
  DFQD1 cmd_payload_core_two_reg_3_ ( .D(N355), .CP(clk), .Q(
        cmd_payload_core_two[3]) );
  DFQD1 cmd_payload_core_one_reg_3_ ( .D(N355), .CP(clk), .Q(
        cmd_payload_core_one[3]) );
  DFQD1 cmd_payload_core_zero_reg_3_ ( .D(N355), .CP(clk), .Q(
        cmd_payload_core_zero[3]) );
  DFQD1 cmd_payload_core_three_reg_2_ ( .D(N354), .CP(clk), .Q(
        cmd_payload_core_three[2]) );
  DFQD1 cmd_payload_core_two_reg_2_ ( .D(N354), .CP(clk), .Q(
        cmd_payload_core_two[2]) );
  DFQD1 cmd_payload_core_one_reg_2_ ( .D(N354), .CP(clk), .Q(
        cmd_payload_core_one[2]) );
  DFQD1 cmd_payload_core_zero_reg_2_ ( .D(N354), .CP(clk), .Q(
        cmd_payload_core_zero[2]) );
  DFQD1 cmd_payload_core_three_reg_1_ ( .D(N353), .CP(clk), .Q(
        cmd_payload_core_three[1]) );
  DFQD1 cmd_payload_core_two_reg_1_ ( .D(N353), .CP(clk), .Q(
        cmd_payload_core_two[1]) );
  DFQD1 cmd_payload_core_one_reg_1_ ( .D(N353), .CP(clk), .Q(
        cmd_payload_core_one[1]) );
  DFQD1 cmd_payload_core_zero_reg_1_ ( .D(N353), .CP(clk), .Q(
        cmd_payload_core_zero[1]) );
  DFQD1 cmd_payload_core_three_reg_0_ ( .D(N352), .CP(clk), .Q(
        cmd_payload_core_three[0]) );
  DFQD1 cmd_payload_core_two_reg_0_ ( .D(N352), .CP(clk), .Q(
        cmd_payload_core_two[0]) );
  DFQD1 cmd_payload_core_one_reg_0_ ( .D(N352), .CP(clk), .Q(
        cmd_payload_core_one[0]) );
  DFQD1 cmd_payload_core_zero_reg_0_ ( .D(N352), .CP(clk), .Q(
        cmd_payload_core_zero[0]) );
  DFQD1 cmd_core_mask_reg_3_ ( .D(N294), .CP(clk), .Q(cmd_core_mask[3]) );
  DFQD1 cmd_core_mask_reg_2_ ( .D(N293), .CP(clk), .Q(cmd_core_mask[2]) );
  DFQD1 cmd_core_mask_reg_1_ ( .D(N292), .CP(clk), .Q(cmd_core_mask[1]) );
  DFQD1 spad_rd_req_valid_reg ( .D(N376), .CP(clk), .Q(spad_rd_req_valid) );
  DFQD1 done_reg ( .D(N289), .CP(clk), .Q(done) );
  EDFQD4 idx_q_reg_0_ ( .D(N277), .E(N276), .CP(clk), .Q(idx_q[0]) );
  EDFQD1 idx_q_reg_1_ ( .D(N278), .E(N276), .CP(clk), .Q(idx_q[1]) );
  CKXOR2D0 U175 ( .A1(idx_q[7]), .A2(n120), .Z(n144) );
  INR2D0 U176 ( .A1(active_load_is_q), .B1(n161), .ZN(N368) );
  CKAN2D0 U177 ( .A1(n106), .A2(n157), .Z(N380) );
  CKND2D1 U178 ( .A1(idx_q[0]), .A2(idx_q[1]), .ZN(n129) );
  CKAN2D0 U179 ( .A1(idx_q[0]), .A2(active_load_len[0]), .Z(n132) );
  INR2D0 U180 ( .A1(run_q_len[0]), .B1(reset), .ZN(N260) );
  INR2D0 U181 ( .A1(run_k_len[7]), .B1(reset), .ZN(N275) );
  INR2D0 U182 ( .A1(run_k_len[6]), .B1(reset), .ZN(N274) );
  INR2D0 U183 ( .A1(run_k_len[5]), .B1(reset), .ZN(N273) );
  INR2D0 U184 ( .A1(run_k_len[4]), .B1(reset), .ZN(N272) );
  INR2D0 U185 ( .A1(run_k_len[3]), .B1(reset), .ZN(N271) );
  INR2D0 U186 ( .A1(run_k_len[2]), .B1(reset), .ZN(N270) );
  INR2D0 U187 ( .A1(run_k_len[1]), .B1(reset), .ZN(N269) );
  INR2D0 U188 ( .A1(run_k_len[0]), .B1(reset), .ZN(N268) );
  INR2D0 U189 ( .A1(run_q_len[7]), .B1(reset), .ZN(N267) );
  INR2D0 U190 ( .A1(run_q_len[6]), .B1(reset), .ZN(N266) );
  INR2D0 U191 ( .A1(run_q_len[5]), .B1(reset), .ZN(N265) );
  INR2D0 U192 ( .A1(run_q_len[4]), .B1(reset), .ZN(N264) );
  INR2D0 U193 ( .A1(run_q_len[3]), .B1(reset), .ZN(N263) );
  INR2D0 U194 ( .A1(run_q_len[2]), .B1(reset), .ZN(N262) );
  INR2D0 U195 ( .A1(run_q_len[1]), .B1(reset), .ZN(N261) );
  INR2D0 U196 ( .A1(n163), .B1(n162), .ZN(N283) );
  CKAN2D0 U197 ( .A1(active_run_q_len[1]), .A2(N290), .Z(N361) );
  CKAN2D0 U198 ( .A1(active_run_q_len[2]), .A2(N290), .Z(N362) );
  CKAN2D0 U199 ( .A1(active_run_q_len[3]), .A2(N290), .Z(N363) );
  CKAN2D0 U200 ( .A1(active_run_q_len[6]), .A2(N290), .Z(N366) );
  MAOI222D0 U201 ( .A(n160), .B(n134), .C(n133), .ZN(n136) );
  CKAN2D0 U202 ( .A1(active_run_q_len[7]), .A2(N290), .Z(N367) );
  CKAN2D0 U203 ( .A1(active_run_q_len[4]), .A2(N290), .Z(N364) );
  CKAN2D0 U204 ( .A1(active_run_q_len[0]), .A2(N290), .Z(N360) );
  CKAN2D0 U205 ( .A1(active_run_q_len[5]), .A2(N290), .Z(N365) );
  INR2D0 U206 ( .A1(n160), .B1(n162), .ZN(N279) );
  OAI21D1 U207 ( .A1(n159), .A2(n171), .B(n158), .ZN(N276) );
  CKND2D0 U208 ( .A1(state[0]), .A2(n174), .ZN(n124) );
  CKND2D0 U209 ( .A1(n122), .A2(n121), .ZN(n167) );
  AOI22D0 U210 ( .A1(active_cmd_mask[3]), .A2(core_agent_busy[3]), .B1(
        active_cmd_mask[2]), .B2(core_agent_busy[2]), .ZN(n122) );
  AOI22D0 U211 ( .A1(active_cmd_mask[1]), .A2(core_agent_busy[1]), .B1(
        active_cmd_mask[0]), .B2(core_agent_busy[0]), .ZN(n121) );
  IND3D0 U212 ( .A1(n124), .B1(state[1]), .B2(cmd_ready), .ZN(n170) );
  MAOI222D0 U213 ( .A(n132), .B(active_load_len[1]), .C(n131), .ZN(n134) );
  INVD0 U214 ( .I(n111), .ZN(n112) );
  NR2D0 U215 ( .A1(n129), .A2(n130), .ZN(n101) );
  CKND2D0 U216 ( .A1(n101), .A2(idx_q[3]), .ZN(n107) );
  CKND2D0 U217 ( .A1(n112), .A2(idx_q[5]), .ZN(n126) );
  INVD0 U218 ( .I(idx_q[6]), .ZN(n127) );
  INVD0 U219 ( .I(n107), .ZN(n108) );
  CKND2D0 U220 ( .A1(n108), .A2(idx_q[4]), .ZN(n111) );
  MAOI222D0 U221 ( .A(n105), .B(n104), .C(n103), .ZN(n113) );
  INVD0 U222 ( .I(idx_q[1]), .ZN(n105) );
  CKND2D0 U223 ( .A1(idx_q[0]), .A2(active_load_base[0]), .ZN(n104) );
  OR2D0 U224 ( .A1(n118), .A2(busy), .Z(n156) );
  NR2D0 U225 ( .A1(state[1]), .A2(n124), .ZN(n168) );
  CKND2D0 U226 ( .A1(spad_rd_rsp_valid), .A2(spad_rd_rsp_ready), .ZN(n171) );
  ND4D0 U227 ( .A1(n149), .A2(n148), .A3(n147), .A4(n146), .ZN(n164) );
  OAI21D0 U228 ( .A1(n161), .A2(n164), .B(n155), .ZN(N239) );
  AOI211D0 U229 ( .A1(n154), .A2(n159), .B(N287), .C(n153), .ZN(n155) );
  AOI211D0 U230 ( .A1(n165), .A2(n167), .B(reset), .C(n123), .ZN(n125) );
  INVD0 U231 ( .I(busy), .ZN(n123) );
  INVD0 U232 ( .I(idx_q[2]), .ZN(n130) );
  MAOI222D0 U233 ( .A(n139), .B(n138), .C(n137), .ZN(n141) );
  INVD0 U234 ( .I(n128), .ZN(n139) );
  MAOI222D0 U235 ( .A(active_load_len[3]), .B(n136), .C(n135), .ZN(n138) );
  CKND2D0 U236 ( .A1(active_op[0]), .A2(N290), .ZN(n102) );
  INVD0 U237 ( .I(n162), .ZN(n154) );
  AOI21D0 U238 ( .A1(active_op[0]), .A2(n109), .B(n161), .ZN(n153) );
  INVD0 U239 ( .I(N290), .ZN(n161) );
  INVD0 U240 ( .I(active_cmd_mask[3]), .ZN(n149) );
  INVD0 U241 ( .I(active_cmd_mask[2]), .ZN(n148) );
  INVD0 U242 ( .I(active_cmd_mask[1]), .ZN(n147) );
  INVD0 U243 ( .I(active_cmd_mask[0]), .ZN(n146) );
  OR2D0 U244 ( .A1(n126), .A2(n127), .Z(n120) );
  OAI21D0 U245 ( .A1(n112), .A2(idx_q[5]), .B(n126), .ZN(n140) );
  OAI21D0 U246 ( .A1(n101), .A2(idx_q[3]), .B(n107), .ZN(n135) );
  OAI21D0 U247 ( .A1(idx_q[0]), .A2(idx_q[1]), .B(n129), .ZN(n131) );
  OAI21D0 U248 ( .A1(n108), .A2(idx_q[4]), .B(n111), .ZN(n128) );
  INVD0 U249 ( .I(state[2]), .ZN(n174) );
  ND4D0 U250 ( .A1(n94), .A2(n93), .A3(n96), .A4(n92), .ZN(n89) );
  ND4D0 U251 ( .A1(n95), .A2(n98), .A3(n97), .A4(n91), .ZN(n88) );
  INVD0 U252 ( .I(load_len[0]), .ZN(n94) );
  INVD0 U253 ( .I(load_len[1]), .ZN(n93) );
  INVD0 U254 ( .I(load_len[2]), .ZN(n96) );
  INVD0 U255 ( .I(load_len[3]), .ZN(n92) );
  INVD0 U256 ( .I(load_len[4]), .ZN(n95) );
  INVD0 U257 ( .I(load_len[5]), .ZN(n98) );
  INVD0 U258 ( .I(load_len[6]), .ZN(n97) );
  INVD0 U259 ( .I(load_len[7]), .ZN(n91) );
  NR2D0 U260 ( .A1(active_op[1]), .A2(n102), .ZN(n150) );
  INVD0 U261 ( .I(reset), .ZN(n157) );
  MAOI222D0 U262 ( .A(active_load_len[7]), .B(n145), .C(n144), .ZN(n159) );
  MAOI222D0 U263 ( .A(n163), .B(n143), .C(n142), .ZN(n145) );
  INVD0 U264 ( .I(active_load_len[6]), .ZN(n142) );
  MAOI222D0 U265 ( .A(active_load_len[5]), .B(n141), .C(n140), .ZN(n143) );
  ND4D0 U266 ( .A1(state[1]), .A2(n157), .A3(n174), .A4(n173), .ZN(n162) );
  OR2D1 U267 ( .A1(n83), .A2(state[2]), .Z(busy) );
  INVD0 U268 ( .I(n165), .ZN(n83) );
  NR2D0 U269 ( .A1(n161), .A2(n148), .ZN(N293) );
  NR2D0 U270 ( .A1(n161), .A2(n149), .ZN(N294) );
  INVD0 U271 ( .I(n102), .ZN(N369) );
  NR2D0 U272 ( .A1(n109), .A2(n161), .ZN(N370) );
  NR2D0 U273 ( .A1(n161), .A2(n146), .ZN(N291) );
  NR2D0 U274 ( .A1(reset), .A2(active_load_is_q), .ZN(N382) );
  AOI211D0 U275 ( .A1(active_load_base[3]), .A2(n117), .B(reset), .C(n116), 
        .ZN(N381) );
  NR2D0 U276 ( .A1(active_load_base[3]), .A2(n117), .ZN(n116) );
  AOI211D0 U277 ( .A1(n104), .A2(n100), .B(reset), .C(n99), .ZN(N379) );
  NR2D0 U278 ( .A1(n104), .A2(n100), .ZN(n99) );
  OR2D0 U279 ( .A1(n168), .A2(reset), .Z(N377) );
  INVD0 U280 ( .I(n110), .ZN(N371) );
  NR2D0 U281 ( .A1(n149), .A2(n110), .ZN(N375) );
  NR2D0 U282 ( .A1(n148), .A2(n110), .ZN(N374) );
  NR2D0 U283 ( .A1(n147), .A2(n110), .ZN(N373) );
  NR2D0 U284 ( .A1(n146), .A2(n110), .ZN(N372) );
  NR2D0 U285 ( .A1(n144), .A2(n162), .ZN(N284) );
  NR2D0 U286 ( .A1(n140), .A2(n162), .ZN(N282) );
  NR2D0 U287 ( .A1(n135), .A2(n162), .ZN(N280) );
  NR2D0 U288 ( .A1(n131), .A2(n162), .ZN(N278) );
  NR2D0 U289 ( .A1(n128), .A2(n162), .ZN(N281) );
  NR2D0 U290 ( .A1(n174), .A2(n152), .ZN(N287) );
  CKND2D0 U291 ( .A1(n165), .A2(n157), .ZN(n152) );
  AO32D0 U292 ( .A1(N285), .A2(cfg_core_enable_mask[1]), .A3(load_core_mask[1]), .B1(N286), .B2(cfg_core_enable_mask[1]), .Z(N244) );
  AO32D0 U293 ( .A1(N285), .A2(cfg_core_enable_mask[2]), .A3(load_core_mask[2]), .B1(N286), .B2(cfg_core_enable_mask[2]), .Z(N245) );
  AO32D0 U294 ( .A1(N285), .A2(cfg_core_enable_mask[3]), .A3(load_core_mask[3]), .B1(N286), .B2(cfg_core_enable_mask[3]), .Z(N246) );
  NR2D0 U295 ( .A1(reset), .A2(n118), .ZN(N285) );
  NR2D0 U296 ( .A1(reset), .A2(n119), .ZN(N286) );
  AO32D0 U297 ( .A1(N285), .A2(cfg_core_enable_mask[0]), .A3(load_core_mask[0]), .B1(N286), .B2(cfg_core_enable_mask[0]), .Z(N243) );
  NR2D0 U298 ( .A1(reset), .A2(n94), .ZN(N247) );
  NR2D0 U299 ( .A1(reset), .A2(n93), .ZN(N248) );
  NR2D0 U300 ( .A1(reset), .A2(n96), .ZN(N249) );
  NR2D0 U301 ( .A1(reset), .A2(n92), .ZN(N250) );
  NR2D0 U302 ( .A1(reset), .A2(n98), .ZN(N252) );
  NR2D0 U303 ( .A1(reset), .A2(n97), .ZN(N253) );
  NR2D0 U304 ( .A1(reset), .A2(n91), .ZN(N254) );
  CKND2D0 U305 ( .A1(n157), .A2(n156), .ZN(N240) );
  INVD0 U306 ( .I(N240), .ZN(n158) );
  NR2D0 U307 ( .A1(idx_q[0]), .A2(n162), .ZN(N277) );
  IND4D0 U308 ( .A1(N242), .B1(n172), .B2(n171), .B3(n170), .ZN(N236) );
  AOI22D0 U309 ( .A1(state[2]), .A2(n169), .B1(n168), .B2(spad_rd_req_ready), 
        .ZN(n172) );
  OAI211D0 U310 ( .A1(n167), .A2(n166), .B(n165), .C(n164), .ZN(n169) );
  OAI21D0 U311 ( .A1(n159), .A2(n162), .B(n151), .ZN(N237) );
  AOI22D0 U312 ( .A1(n150), .A2(n164), .B1(n165), .B2(n157), .ZN(n151) );
  INVD0 U313 ( .I(active_load_len[2]), .ZN(n133) );
  INVD0 U314 ( .I(active_load_len[4]), .ZN(n137) );
  INVD0 U315 ( .I(active_load_base[1]), .ZN(n103) );
  INVD0 U316 ( .I(idx_q[3]), .ZN(n115) );
  AOI22D0 U317 ( .A1(n87), .A2(n86), .B1(n85), .B2(n84), .ZN(n90) );
  NR2D0 U318 ( .A1(state[1]), .A2(state[0]), .ZN(n165) );
  INVD0 U319 ( .I(active_op[1]), .ZN(n109) );
  ND3D0 U320 ( .A1(spad_rd_rsp_valid), .A2(load_row_ready), .A3(n154), .ZN(
        n110) );
  OAI21D0 U321 ( .A1(n89), .A2(n88), .B(load_start), .ZN(n118) );
  ND3D0 U322 ( .A1(run_start), .A2(n90), .A3(n118), .ZN(n119) );
  INVD0 U323 ( .I(state[0]), .ZN(n173) );
  NR2D0 U324 ( .A1(n161), .A2(n147), .ZN(N292) );
  OA211D0 U325 ( .A1(idx_q[0]), .A2(active_load_base[0]), .B(n157), .C(n104), 
        .Z(N378) );
  CKND2D0 U326 ( .A1(n125), .A2(n170), .ZN(N288) );
  NR2D0 U327 ( .A1(reset), .A2(n95), .ZN(N251) );
  AN4D1 U328 ( .A1(load_row_ready), .A2(n174), .A3(n173), .A4(state[1]), .Z(
        spad_rd_rsp_ready) );
  TIEL U329 ( .ZN(n3) );
  INR3D0 U330 ( .A1(state[1]), .B1(n124), .B2(reset), .ZN(N290) );
  AO22D0 U331 ( .A1(active_load_len[6]), .A2(n150), .B1(active_run_k_len[6]), 
        .B2(n153), .Z(N358) );
  AO22D0 U332 ( .A1(active_load_len[4]), .A2(n150), .B1(active_run_k_len[4]), 
        .B2(n153), .Z(N356) );
  AO22D0 U333 ( .A1(active_load_len[3]), .A2(n150), .B1(active_run_k_len[3]), 
        .B2(n153), .Z(N355) );
  AO22D0 U334 ( .A1(active_load_len[7]), .A2(n150), .B1(active_run_k_len[7]), 
        .B2(n153), .Z(N359) );
  AO22D0 U335 ( .A1(active_load_len[1]), .A2(n150), .B1(active_run_k_len[1]), 
        .B2(n153), .Z(N353) );
  AO22D0 U336 ( .A1(active_load_len[2]), .A2(n150), .B1(active_run_k_len[2]), 
        .B2(n153), .Z(N354) );
  AO22D0 U337 ( .A1(active_load_len[0]), .A2(n150), .B1(active_run_k_len[0]), 
        .B2(n153), .Z(N352) );
  AO22D0 U338 ( .A1(active_load_len[5]), .A2(n150), .B1(active_run_k_len[5]), 
        .B2(n153), .Z(N357) );
  NR4D0 U339 ( .A1(run_k_len[3]), .A2(run_k_len[2]), .A3(run_k_len[1]), .A4(
        run_k_len[0]), .ZN(n87) );
  NR4D0 U340 ( .A1(run_k_len[7]), .A2(run_k_len[6]), .A3(run_k_len[5]), .A4(
        run_k_len[4]), .ZN(n86) );
  NR4D0 U341 ( .A1(run_q_len[3]), .A2(run_q_len[2]), .A3(run_q_len[1]), .A4(
        run_q_len[0]), .ZN(n85) );
  NR4D0 U342 ( .A1(run_q_len[7]), .A2(run_q_len[6]), .A3(run_q_len[5]), .A4(
        run_q_len[4]), .ZN(n84) );
  OAI21D1 U343 ( .A1(busy), .A2(n119), .B(n157), .ZN(N259) );
  IND2D1 U344 ( .A1(N259), .B1(n156), .ZN(N242) );
  NR3D0 U345 ( .A1(reset), .A2(state[2]), .A3(state[1]), .ZN(N238) );
  CKAN2D0 U346 ( .A1(N238), .A2(state[0]), .Z(N376) );
  CKAN2D0 U347 ( .A1(load_base[2]), .A2(n157), .Z(N257) );
  CKAN2D0 U348 ( .A1(load_is_q), .A2(n157), .Z(N241) );
  CKAN2D0 U349 ( .A1(load_base[3]), .A2(n157), .Z(N258) );
  CKAN2D0 U350 ( .A1(load_base[0]), .A2(n157), .Z(N255) );
  CKAN2D0 U351 ( .A1(load_base[1]), .A2(n157), .Z(N256) );
  MUX2ND0 U352 ( .I0(idx_q[1]), .I1(n105), .S(active_load_base[1]), .ZN(n100)
         );
  FA1D0 U353 ( .A(active_load_base[2]), .B(idx_q[2]), .CI(n113), .CO(n114), 
        .S(n106) );
  MUX2ND0 U354 ( .I0(n115), .I1(idx_q[3]), .S(n114), .ZN(n117) );
  MUX2ND0 U355 ( .I0(idx_q[6]), .I1(n127), .S(n126), .ZN(n163) );
  MUX2ND0 U356 ( .I0(idx_q[2]), .I1(n130), .S(n129), .ZN(n160) );
  INVD0 U357 ( .I(busy_seen_any), .ZN(n166) );
  NR4D0 U358 ( .A1(reset), .A2(state[1]), .A3(n174), .A4(n173), .ZN(N289) );
endmodule

