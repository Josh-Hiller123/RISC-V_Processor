import if_id_struct::*;
module fetch_stage #(
parameter IC_WORD_BITS = 2,
parameter IC_INDEX_BITS = 5,
parameter IC_WAYS_AMT = 3, 
parameter MAIN_MEM_WIDTH = 16
)(
input
output if_id_t o_if_id_next
);

localparam PC_WIDTH = 32; 
localparam INSTRUCT_WIDTH = 32;

logic [PC_WIDTH-1:0] w_pc; 
logic [PC_WIDTH-1:0] w_pc_add_four; 
logic [INSTRUCT_WIDTH-1:0] w_instruct;

assign o_if_id_next.pc = w_pc;
assign o_if_id_next.pc_add_four = w_pc_add_four;
assign o_if_id_next.instruct = w_instruct;

riscv_pc pc_wiring (
.o_pc(w_pc), 
.o_pc_add_four(w_pc_add_four)
);

riscv_icache #(
.WORD_BITS(IC_WORD_BITS), 
.INDEX_BITS(IC_INDEX_BITS), 
.WAYS_AMT(IC_WAYS_AMT), 
.MAIN_MEM_WIDTH(MAIN_MEM_WIDTH)
) imem_wiring (
.i_pc(w_pc), 
.o_instruct(w_instruct)
);
endmodule



