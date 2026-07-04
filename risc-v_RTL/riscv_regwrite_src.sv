module riscv_regwrite_src #(
parameter REG_DATAWIDTH = 32,
parameter REGWRITE_MUX_CTRL = 3
)(
input logic [REG_DATAWIDTH-1:0] i_ALU, 
input logic [REG_DATAWIDTH-1:0] i_pc,
input logic [REG_DATAWIDTH-1:0] i_dmem, 
input logic [REG_DATAWIDTH-1:0] i_immext, 
input logic [REG_DATAWIDTH-1:0] i_pc_add_immext,
input logic [REGWRITE_MUX_CTRL-1:0] regwrite_mux_ctrl, 


output logic [REG_DATAWIDTH-1:0] o_rd_data
);

localparam CHOOSE_ALU = 3'b000; 
localparam CHOOSE_DMEM = 3'b001; 
localparam CHOOSE_IMMEXT = 3'b010; 
localparam CHOOSE_PC = 3'b100;
localparam CHOOSE_PC_ADD_IMMEXT = 3'b101;

always_comb
begin 
case(regwrite_mux_ctrl)
CHOOSE_ALU: o_rd_data = i_ALU;
CHOOSE_DMEM: o_rd_data = i_dmem;
CHOOSE_IMMEXT: o_rd_data = i_immext;
CHOOSE_PC: o_rd_data = i_pc;
CHOOSE_PC_ADD_IMMEXT: o_rd_data = i_pc_add_immext;
default: o_rd_data = 'x;
endcase
end

endmodule