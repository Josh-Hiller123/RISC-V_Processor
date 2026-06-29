module riscv_imem #(
parameter PC_WIDTH = 32,
parameter IMEM_ADDR_WIDTH = 16
parameter INSTRUCT_WIDTH = 32)(

input logic [PC_WIDTH-1:0] i_pc,
output logic [INSTRUCT_WIDTH-1:0] o_instruct
); 

logic [INSTRUCT_WIDTH-1:] i_mem [(1 << IMEM_ADDR_WIDTH)-1:0];

assign o_instruct = i_mem[i_pc[IMEM_ADDR_WIDTH-1:2]];
endmodule