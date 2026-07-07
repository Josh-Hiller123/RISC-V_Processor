module riscv_pc_addrs #(
parameter PC_WIDTH = 32, 
parameter IMM_WIDTH = 32, 
parameter REG_DATAWIDTH = 32)(

input logic [PC_WIDTH-1:0] i_pc, 
input logic [IMM_WIDTH-1:0] i_immext,
input logic [REG_DATAWIDTH-1:0] i_rs1_add_immext,

output logic [PC_WIDTH-1:0] o_pc_add_immext,
output logic [PC_WIDTH-1:0] o_rs1_immext_mask
);

assign o_pc_add_immext = i_pc + i_immext;
assign o_rs1_immext_mask = i_rs1_add_immext & ~32'b1;
endmodule
