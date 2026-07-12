module riscv_flush #(
)(
input logic i_jal_ctrl,
input logic i_jalr_ctrl,
input logic i_dobranch, 

output logic o_flush_if_id, 
output logic o_flush_id_ex
);

always_comb 
begin
    if(i_jal_ctrl || i_jalr_ctrl || i_dobranch)
        o_flush_if_id = 1'b1;
    else 
        o_flush_if_id = 1'b0; 

    if(i_dobranch || i_jalr_ctrl)
        o_flush_id_ex = 1'b1; 
    else 
        o_flush_id_ex = 1'b0;
end
endmodule
