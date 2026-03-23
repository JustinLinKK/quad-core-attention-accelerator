
set clock_cycle 1.0
set io_delay 0.2 

set clock_port clk

create_clock -name clk -period $clock_cycle [get_ports $clock_port]

set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {reset}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {wr[*]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {rd}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {in[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {out[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {o_full}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {0_valid}]




