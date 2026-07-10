import id_ex_struct::*;
module riscv_id_ex_reg #()(
input logic i_clk,
input logic i_nrst,
input logic i_flush,

input id_ex_t i_id_ex_next,
output id_ex_t o_id_ex
);

always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst)
        o_id_ex <= '0; 
    else if (i_flush)
        o_id_ex <= '0; 
    else
        o_id_ex <= i_id_ex_next;
end
endmodule
