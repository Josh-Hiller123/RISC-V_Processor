import mem_wb_struct::*;
module riscv_mem_wb_reg 
#()(
input logic i_clk,
input logic i_nrst,
input logic i_stall_mem_wb,

input mem_wb_t i_mem_wb_next,
output mem_wb_t o_mem_wb
);

always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst)
        o_mem_wb <= '0; 
    
    else if(i_stall_mem_wb)
        o_mem_wb <= o_mem_wb;
    else
        o_mem_wb <= i_mem_wb_next;
end


endmodule

