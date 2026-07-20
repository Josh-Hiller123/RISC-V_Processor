import ex_mem_struct::*;
import mem_wb_struct::*;
module riscv_memory_stage (
input ex_mem_t i_ex_mem, 
output mem_wb_t o_mem_wb_next
); 

localparam REG_DATAWIDTH = 32; 
localparam MEM_FORWARD_CTRL = 2;

logic [REG_DATAWIDTH-1:0] w_ALU;
logic [REG_DATAWIDTH-1:0] w_pc_add_four;
logic [REG_DATAWIDTH-1:0] w_jumps_target;
logic[MEM_FORWARD_CTRL-1:0] w_mem_forward_ctrl;
logic [REG_DATAWIDTH-1:0] w_rd_data;
logic w_fencei;

//i_ex_mem wiring connections (from previous reg carrying on to mem)
assign o_mem_wb_next.wenable = i_ex_mem.wenable;
assign o_mem_wb_next.rd = i_ex_mem.rd;

//mem_forward wiring connections
assign w_ALU = i_ex_mem.alu; 
assign w_pc_add_four = i_ex_mem.pc_add_four;
assign w_jumps_target = i_ex_mem.jumps_target;
assign w_mem_forward_ctrl = i_ex_mem.mem_forward_ctrl;
assign o_mem_wb_next.rd_data = w_rd_data;

//fencei wiring connection
assign w_fencei = i_ex_mem.fencei;


riscv_mem_forward mem_forward_wiring (
.i_ALU(w_ALU), 
.i_pc_add_four(w_pc_add_four), 
.i_jumps_target(w_jumps_target), 
.i_mem_forward_ctrl(w_mem_forward_ctrl), 
.o_rd_data(w_rd_data)
);

endmodule
