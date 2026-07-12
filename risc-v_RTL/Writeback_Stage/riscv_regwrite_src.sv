module riscv_regwrite_src #(
parameter REG_DATAWIDTH = 32,
parameter REGWRITE_MUX_CTRL = 3
)(
input logic [REG_DATAWIDTH-1:0] i_ALU, 
input logic [REG_DATAWIDTH-1:0] i_pc_add_four,
input logic [REG_DATAWIDTH-1:0] i_dmem_clean, 
input logic [REG_DATAWIDTH-1:0] i_jumps_target,
input logic [REGWRITE_MUX_CTRL-1:0] i_regwrite_mux_ctrl, 


output logic [REG_DATAWIDTH-1:0] o_rd_data
);

localparam CHOOSE_ALU = 3'b000; 
localparam CHOOSE_DMEM = 3'b001; 
localparam CHOOSE_PC_ADD_IMMEXT_OR_PC = 3'b010;
localparam CHOOSE_PC = 3'b100;

always_comb
begin 
case(i_regwrite_mux_ctrl)
CHOOSE_ALU: o_rd_data = i_ALU;
CHOOSE_DMEM: o_rd_data = i_dmem_clean;
CHOOSE_PC: o_rd_data = i_pc_add_four;
CHOOSE_PC_ADD_IMMEXT_OR_PC: o_rd_data = i_jumps_target;
default: o_rd_data = 'x;
endcase
end

endmodule
