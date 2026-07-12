module riscv_flush #(
parameter JUMPS_CTRL = 2
)(
input logic [JUMPS_CTRL-1:0] i_jumps_ctrl, 
input logic i_dobranch, 

output logic o_flush_if_id, 
output logic o_flush_id_ex
);

localparam JAL = 2'b01; 
localparam JALR = 2'b10; 

always_comb 
begin
    if(i_jumps_ctrl == JAL || i_jumps_ctrl == JALR || i_dobranch == 1)
        o_flush_if_id = 1'b1;
    else 
        o_flush_if_id = 1'b0; 

    if(i_dobranch == 1)
        o_flush_id_ex = 1'b1; 
    else 
        o_flush_id_ex = 1'b0;
end
endmodule
