
set clock_cycle 0.7
set io_delay 0.2 

set clock_port clk


create_clock -name clk -period $clock_cycle [get_ports $clock_port]
set_clock_uncertainty 0.1 [get_clocks clk]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {reset}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {q_in[*]}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {q_zero_in}]
set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {i_inst[*]}]

set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {q_out[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {q_zero_out[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {o_inst[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {out[*]}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {fifo_wr}]



