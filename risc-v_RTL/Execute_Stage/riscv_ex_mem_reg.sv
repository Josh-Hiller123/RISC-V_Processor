import ex_mem_struct::*;
module riscv_ex_mem_reg #()(
input logic i_clk,
input logic i_nrst,

input ex_mem_t i_ex_mem_next,
output ex_mem_t o_ex_mem
);

always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst)
        o_ex_mem <= '0; 
    else
        o_ex_mem <= i_ex_mem_next;
end
endmodule
