create_clock -name sys_clk -period 7.5 [get_ports i_clk]

set_false_path -from [get_ports i_nrst]


