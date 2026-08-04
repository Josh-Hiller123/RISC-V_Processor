interface tb_interface (
input logic i_clk,
input logic i_nrst, 
input logic valid_tb,
input logic [31:0] pc_tb,
input logic [31:0] instruct_tb,
input logic [31:0] alu_tb,
input logic [2:0] func3_tb,
input logic [31:0] rs2_data_tb,
input logic mem_write_tb,
input logic [31:0] dmem_clean_tb,
input logic wenable_tb,
input logic [31:0] rd_data_tb,
input logic [4:0] rd_tb
);

clocking cb @(posedge i_clk);
input valid_tb;
input pc_tb;
input instruct_tb;
input alu_tb;
input func3_tb;
input rs2_data_tb;
input mem_write_tb;
input dmem_clean_tb;
input wenable_tb;
input rd_data_tb;
input rd_tb;
endclocking

endinterface