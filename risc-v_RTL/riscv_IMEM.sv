module riscv_IMEM #(parameter IMEM_ADDR_WIDTH = 16)(
input logic [IMEM_ADDR_WIDTH-1:0] i_pc,
output logic o_instruct
); 

localparam INSTRUCT_WIDTH = 32;
logic [INSTRUCT_WIDTH-1:] i_mem [(1 << IMEM_ADDR_WIDTH)-1:0];

assign o_instruct = i_mem[i_pc];
endmodule