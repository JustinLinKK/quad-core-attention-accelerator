
set clock_cycle 1.0 
set io_delay 0.2 

set clock_port clk

create_clock -name clk -period $clock_cycle [get_ports $clock_port]
set norm_src_regs [get_cells -hierarchical *div_hold*_q_reg*]
set norm_dst_regs [get_cells -hierarchical *sfp_out_sign*_reg*]

set_multicycle_path 2 -setup -from $norm_src_regs -to $norm_dst_regs
set_multicycle_path 1 -hold  -from $norm_src_regs -to $norm_dst_regs


set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {reset}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {wr[*]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {rd}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {in[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {out[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {o_full}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {0_valid}]




