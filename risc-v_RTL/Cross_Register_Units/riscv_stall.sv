module riscv_stall #()(
input logic i_dcache_miss, 
input logic i_dcache_fence, 
input logic i_forward_load,
input logic i_dobranch, 
input logic i_jalr_ctrl,

output logic o_stall_if_id, 
output logic o_stall_id_ex, 
output logic o_stall_ex_mem, 
output logic o_stall_mem_wb
);

assign o_stall_if_id  = i_dcache_miss | (i_forward_load && !i_dobranch && !i_jalr_ctrl);
assign o_stall_id_ex  = i_dcache_miss;
assign o_stall_ex_mem = i_dcache_miss | i_dcache_fence;
assign o_stall_mem_wb = i_dcache_miss | i_dcache_fence;
endmodule