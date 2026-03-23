# Clock tree synthesis 
set_ccopt_property -update_io_latency false
create_ccopt_clock_tree_spec -file /home/linux/ieng6/ECE260B_WI26_A00/tkt004/ECE260B-Project_Working/Step5/pnr/pnr_sram_64b_w16/constraints/$design.ccopt
ccopt_design

# Use actual clock network
set_propagated_clock [all_clocks]

# Post-CTS timing optimization
optDesign -postCTS -hold
saveDesign cts.enc
