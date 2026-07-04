module riscv_regwrite_src #(
parameter REG_DATAWIDTH = 32,
parameter REGWRITE_MUX_CTRL = 2
)(
input logic [REG_DATAWIDTH-1:0] i_ALU, 
input logic [REG_DATAWIDTH-1:0] i_pc,
input logic [REG_DATAWIDTH-1:0] i_dmem, 
input logic [REG_DATAWIDTH-1:0] i_immext, 
input logic [REGWRITE_MUX_CTRL-1:0] regwrite_mux_ctrl, 

output logic [REG_DATAWIDTH-1:0] o_rd_data
);

localparam CHOOSE_ALU = 2'b00; 
localparam CHOOSE_DMEM = 2'b01; 
localparam CHOOSE_IMMEXT = 2'b10; 
localparam CHOOSE_PC = 2'b11;

always_comb
begin 
case(regwrite_mux_ctrl)
CHOOSE_ALU: o_rd_data = i_ALU;
CHOOSE_DMEM: o_rd_data = i_dmem;
CHOOSE_IMMEXT: o_rd_data = i_immext;
CHOOSE_PC: o_rd_data = i_pc;
default: o_rd_data = 'x;
endcase
end

endmodule