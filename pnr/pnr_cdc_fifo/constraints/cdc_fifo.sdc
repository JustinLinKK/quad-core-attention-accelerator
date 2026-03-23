set src_clock_cycle 1
set dst_clock_cycle 1
set io_delay 0.2

create_clock -name src_clk -period $src_clock_cycle [get_ports src_clk]
create_clock -name dst_clk -period $dst_clock_cycle [get_ports dst_clk]


set_clock_groups -asynchronous \
  -group [get_clocks src_clk] \
  -group [get_clocks dst_clk]

set_false_path -from [get_ports reset]

set_input_delay -clock [get_clocks src_clk] -add_delay -max $io_delay [get_ports {src_data[*]}]
set_input_delay -clock [get_clocks src_clk] -add_delay -max $io_delay [get_ports {src_valid}]
set_input_delay -clock [get_clocks dst_clk] -add_delay -max $io_delay [get_ports {dst_ready}]

set_output_delay -clock [get_clocks src_clk] -add_delay -max $io_delay [get_ports {src_ready}]
set_output_delay -clock [get_clocks dst_clk] -add_delay -max $io_delay [get_ports {dst_data[*]}]
set_output_delay -clock [get_clocks dst_clk] -add_delay -max $io_delay [get_ports {dst_valid}]
