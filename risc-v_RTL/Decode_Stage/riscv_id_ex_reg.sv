import id_ex_struct::*;
module riscv_id_ex_reg #()(
input logic i_clk,
input logic i_nrst,
input logic i_flush_id_ex,
input logic i_stall_id_ex,

input id_ex_t i_id_ex_next,
output id_ex_t o_id_ex
);

always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst)
        o_id_ex <= '0; 
    
    else if(i_stall_id_ex)
        o_id_ex <= o_id_ex;

    else if (i_flush_id_ex)
        o_id_ex <= '0; 
        
    else
        o_id_ex <= i_id_ex_next;
end
endmodule
