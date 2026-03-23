
set clock_cycle 1.0 
set io_delay 0.2 

set clock_port clk

create_clock -name clk -period $clock_cycle [get_ports $clock_port]

set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {reset}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {acc}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {div}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {multi_core}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {ext_sum_wr}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {threshold_sum_wr}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {threshold_sum_in[*]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {sum_in[*]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {sfp_in[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {sfp_out[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {sum_out[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {sum_valid}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {ext_sum_empty}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {div_done}]



