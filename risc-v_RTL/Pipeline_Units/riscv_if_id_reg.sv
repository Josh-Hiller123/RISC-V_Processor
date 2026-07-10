import if_id_struct::*;
module riscv_if_id_reg (
input logic i_clk, 
input logic i_nrst,
input logic i_flush,

input if_id_t i_if_id_next,
output if_id_t o_if_id
);

always_ff @(posedge i_clk or negedge i_nrst)
begin
    if (!i_nrst)
        o_if_id <= '0; 
    else if (i_flush)
        o_if_id <= '0; 
    else
    o_if_id <= i_if_id_next;
end
endmodule
