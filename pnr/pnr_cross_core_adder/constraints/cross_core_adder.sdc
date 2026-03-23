
set clock_cycle 2.0
set io_delay 0.2

set clock_port clk


create_clock -name clk -period $clock_cycle [get_ports $clock_port]

set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {reset}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {multi_core_inst[*]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {core_enable_mask[*]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {group_link[*]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {ext_sum_wr_cmd}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {core_sum_in[*]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {sum_valid_in[*]}]

set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {core_sum_pop_ready[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {core_sum_to_cores[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {core_ext_sum_wr[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {sum_out[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {sum_valid_out[*]}]
