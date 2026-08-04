create_clock -name sys_clk -period 9.650 [get_ports i_clk]

set_false_path -from [get_ports i_nrst]


