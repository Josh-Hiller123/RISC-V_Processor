module riscv_mem_forward #(
parameter REG_DATAWIDTH = 32,
parameter MEM_FORWARD_CTRL = 2
)(
input logic [REG_DATAWIDTH-1:0] i_ALU, 
input logic [REG_DATAWIDTH-1:0] i_pc_add_four,
input logic [REG_DATAWIDTH-1:0] i_jump_target,
input logic [MEM_FORWARD_CTRL-1:0] i_mem_forward_ctrl, 

output logic [REG_DATAWIDTH-1:0] o_mem_forward
);

localparam CHOOSE_ALU = 2'b00;  
localparam CHOOSE_PC = 2'b01;
localparam CHOOSE_PC_ADD_IMMEXT_OR_IMMEXT = 2'b10;

always_comb
begin 
case(i_mem_forward_ctrl)
CHOOSE_ALU: o_mem_forward = i_ALU;
CHOOSE_PC: o_mem_forward = i_pc_add_four;
CHOOSE_PC_ADD_IMMEXT_OR_IMMEXT: o_mem_forward = i_jump_target;
default: o_mem_forward = 'x;
endcase
end

endmodule
