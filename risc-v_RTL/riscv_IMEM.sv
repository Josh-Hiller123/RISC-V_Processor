module riscv_imem #(
parameter PC_WIDTH = 32,
parameter IMEM_ADDR_WIDTH = 16
parameter INSTRUCT_WIDTH = 32)(

input logic [PC_WIDTH-1:0] i_pc,
output logic [INSTRUCT_WIDTH-1:0] o_instruct
); 

logic [INSTRUCT_WIDTH-1:] i_mem [(1 << IMEM_ADDR_WIDTH)-1:0];

assign o_instruct = i_mem[i_pc[IMEM_ADDR_WIDTH-1:2]];  
// I-MEM always discards the bottom two bits of PC, so if PC is ever misaligned by 
// a faulty jump or branch, PC will round the incorrect value value down to the nearest 
// valid PC. However, the incorrect value of PC remains incorrect everywhere else,
// including if it was stored in a register or in memory. All subsequent values of 
// PC also remain incorrect, but are rounded down. This error will be flagged in 
// simulation if it occurs. Similar method for if func7 doesn't match expected value for 
// slli, srli, and  srai. 
endmodule