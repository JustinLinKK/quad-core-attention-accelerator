set clock_cycle 1.0 
set io_delay 0.2 

set clock_port CLK

create_clock -name clk -period $clock_cycle [get_ports $clock_port]

set_input_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {D[*] A[*] CEN WEN}]
set_output_delay -clock [get_clocks clk] -add_delay -max $io_delay [get_ports {Q[*]}]


