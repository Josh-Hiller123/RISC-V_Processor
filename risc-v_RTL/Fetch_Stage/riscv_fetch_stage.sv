import if_id_struct::*;
module fetch_stage #(
//Parameterizable, need overriding by top 
parameter IC_WORD_BITS = 2,
parameter IC_INDEX_BITS = 5,
parameter IC_WAYS_AMT = 3, 
parameter MAIN_MEM_WIDTH = 16, 

//Top doesn't need access
parameter PC_WIDTH = 32,
parameter IC_TAG_BITS = MAIN_MEM_WIDTH-IC_INDEX_BITS-IC_WORD_BITS-2,
parameter ICACHE_ENTRIES = IC_TAG_BITS+((1 << IC_WORD_BITS) * INSTRUCT_WIDTH)
)(
input logic i_clk,
input logic i_nrst,
input logic i_ic_handshake, 
input logic i_fence, 
input logic [ICACHE_ENTRIES-IC_TAG_BITS-1:0] i_ic_index_fetched, 
input logic i_jalr_ctrl_id,

input logic [PC_WIDTH-1:0] i_id_jump_target, 
input logic [PC_WIDTH-1:0] i_ex_jump_target,
input logic [PC_WIDTH-1:0] i_ALU,
input logic [PC_WIDTH-1:0] i_dcache_pc_add_four,
input logic i_dobranch, 
input logic i_jal_ctrl, 
input logic i_jalr_ctrl,
input logic i_forward_load,
input logic i_dcache_miss,
input logic i_dcache_fence,

output logic o_icache_miss, 
output logic [IC_TAG_BITS+IC_INDEX_BITS-1:0] o_ic_index_request,
output if_id_t o_if_id_next
);

localparam PC_WIDTH = 32; 
localparam INSTRUCT_WIDTH = 32;

logic [PC_WIDTH-1:0] w_pc; 
logic [PC_WIDTH-1:0] w_pc_add_four; 
logic [INSTRUCT_WIDTH-1:0] w_instruct;

logic w_icache_miss;

assign o_if_id_next.pc = w_pc;
assign o_if_id_next.pc_add_four = w_pc_add_four;
assign o_if_id_next.instruct = w_instruct;

assign o_icache_miss = w_icache_miss;

riscv_pc pc_wiring (
.i_clk(i_clk), 
.i_nrst(i_nrst), 
.i_id_jump_target(i_id_jump_target), 
.i_ex_jump_target(i_ex_jump_target), 
.i_ALU(i_ALU), 
.i_dcache_pc_add_four(i_dcache_pc_add_four), 
.i_dobranch(i_dobranch), 
.i_jal_ctrl(i_jal_ctrl), 
.i_jalr_ctrl(i_jalr_ctrl), 
.i_forward_load(i_forward_load), 
.i_icache_miss(w_icache_miss), 
.i_dcache_miss(i_dcache_miss), 
.i_dcache_fence(i_dcache_fence), 
.o_pc(w_pc), 
.o_pc_add_four(w_pc_add_four)
);

riscv_icache #(
.WORD_BITS(IC_WORD_BITS), 
.INDEX_BITS(IC_INDEX_BITS), 
.WAYS_AMT(IC_WAYS_AMT), 
.MAIN_MEM_WIDTH(MAIN_MEM_WIDTH)
) imem_wiring (
.i_clk(i_clk), 
.i_nrst(i_nrst), 
.i_handshake(i_ic_handshake),
.i_pc(w_pc), 
.i_fence(i_fence), 
.i_index_fetched(i_ic_index_fetched),
.i_jalr_ctrl(i_jalr_ctrl_id),
.o_icache_miss(o_icache_miss),
.o_index_request(o_ic_index_request),
.o_instruct(w_instruct)
);
endmodule



