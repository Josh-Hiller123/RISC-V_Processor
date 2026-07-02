module riscv_pc_addrs #(
parameter PC_WIDTH = 32, 
parameter IMM_WIDTH = 32, 
parameter REG_DATAWIDTH = 32)(

input logic [PC_WIDTH-1:0] i_pc, 
input logic [IMM_WIDTH-1:0] i_immext,
input logic [REG_DATAWIDTH-1:0] i_rs1_data,

output logic o_pc_add_imm,
output logic o_rs1_add_immext
);

assign o_pc_add_imm = i_pc + i_immext;
assign o_rs1_add_immext = (i_rs1_data + i_immext) & 1'b0;
endmodule