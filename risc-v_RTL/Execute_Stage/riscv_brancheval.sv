module riscv_brancheval #(
parameter FUNC3 = 3
)(
input logic [FUNC3-1:0] i_func3,
input logic i_zero, 
input logic i_branch_ctrl, 

output logic o_dobranch
);
assign o_dobranch = (i_zero ^ (i_func3[0] ^ i_func3[2])) & i_branch_ctrl;
endmodule