module riscv_flush #(
)(
input logic i_jal_ctrl,
input logic i_jalr_ctrl,
input logic i_dobranch, 
input logic i_icache_miss,
input logic i_dcache_miss, 
input logic i_dcache_fence,
input logic i_forward_load,

output logic o_flush_if_id, 
output logic o_flush_id_ex, 
output logic o_flush_ex_mem
);

assign o_flush_if_id  = i_jal_ctrl | i_jalr_ctrl | i_dobranch | i_icache_miss | i_dcache_fence;
assign o_flush_id_ex  = i_dobranch | i_jalr_ctrl | i_forward_load | i_dcache_fence;
assign o_flush_ex_mem = i_jalr_ctrl | i_dobranch; 

endmodule
