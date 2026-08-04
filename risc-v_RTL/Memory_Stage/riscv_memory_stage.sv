import ex_mem_struct::*;
import mem_wb_struct::*;
module riscv_memory_stage #(
parameter REG_DATAWIDTH = 32, 
parameter REG_WIDTH = 5,
parameter PC_WIDTH = 32,

//Parameterizable, need overriding by top 
parameter MAIN_MEM_WIDTH = 16, 
parameter WORD_BITS = 2,
parameter DC_WAYS_AMT = 3,
parameter DC_INDEX_BITS = 5,

////Top doesn't need access
parameter DC_TAG_BITS = MAIN_MEM_WIDTH-DC_INDEX_BITS-WORD_BITS-2,
parameter DCACHE_ENTRIES = DC_TAG_BITS+((1 << WORD_BITS) * REG_DATAWIDTH), 
parameter ALU_OUT = 32
)(
input ex_mem_t i_ex_mem, 
input logic i_clk,
input logic i_nrst,
input logic i_dc_handshake,
input logic [DC_WAYS_AMT-1:0] i_dc_wb_in_progress, 
input logic [DCACHE_ENTRIES-DC_TAG_BITS-1:0] i_dc_index_fetched,

output logic o_dcache_miss, 
output logic [DC_TAG_BITS+DC_INDEX_BITS-1:0] o_dc_index_request,
output logic o_dc_wb_flag, 
output logic [DC_TAG_BITS+DC_INDEX_BITS-1:0] o_dc_wb_addr, 
output logic [DCACHE_ENTRIES-DC_TAG_BITS-1:0] o_dc_wb_data,
output logic o_dcache_fence, 
output logic [DC_WAYS_AMT-1:0] o_dc_fence_wb_way, 

output mem_wb_t o_mem_wb_next,
output logic [REG_DATAWIDTH-1:0] o_mem_forward, 
output logic [REG_WIDTH-1:0] o_mem_rd, 
output logic o_mem_wenable, 

output logic [PC_WIDTH-1:0] o_dcache_pc_add_four, 
output logic o_fence, 

output logic o_jalr_ctrl, 
output logic o_dobranch, 
output logic [PC_WIDTH-1:0] o_mem_jump_target,
output logic [ALU_OUT-1:0] o_ALU
); 

localparam MEM_FORWARD_CTRL = 2;
localparam FUNC3 = 3;

logic [REG_DATAWIDTH-1:0] w_ALU;
logic [REG_DATAWIDTH-1:0] w_pc_add_four;
logic [REG_DATAWIDTH-1:0] w_jump_target;
logic[MEM_FORWARD_CTRL-1:0] w_mem_forward_ctrl;
logic [REG_DATAWIDTH-1:0] w_mem_forward;
logic w_fencei;

logic [REG_DATAWIDTH-1:0] w_rs2_data;
logic [FUNC3-1:0] w_func3;
logic w_memwrite;
logic w_memread;
logic [REG_DATAWIDTH-1:0] w_load_data;
logic [REG_DATAWIDTH-1:0] w_dmem_clean;

//jalr and branch outputs
assign o_jalr_ctrl = i_ex_mem.jalr_ctrl;
assign o_dobranch = i_ex_mem.dobranch;

assign o_mem_jump_target = i_ex_mem.jump_target;
assign o_ALU = i_ex_mem.alu;

//i_ex_mem wiring connections (from previous reg carrying on to mem)
assign o_mem_wb_next.wenable = i_ex_mem.wenable;
assign o_mem_wb_next.rd = i_ex_mem.rd;
assign o_mem_wb_next.mem_read = w_memread;

//mem_forward wiring connections
assign w_ALU = i_ex_mem.alu; 
assign w_pc_add_four = i_ex_mem.pc_add_four;
assign w_jump_target = i_ex_mem.jump_target;
assign w_mem_forward_ctrl = i_ex_mem.mem_forward_ctrl;
assign o_mem_wb_next.mem_forward = w_mem_forward;

//fencei wiring connection
assign w_fencei = i_ex_mem.fencei;

//forwarding outputs' wiring
assign o_mem_forward = w_mem_forward;
assign o_mem_rd = i_ex_mem.rd;
assign o_mem_wenable = i_ex_mem.wenable;

//dcache wiring connections
assign w_rs2_data = i_ex_mem.rs2_data;
assign w_func3 = i_ex_mem.func3;
assign w_memwrite = i_ex_mem.mem_write;
assign w_memread = i_ex_mem.mem_read;

//load-ext 
assign o_mem_wb_next.dmem_clean = w_dmem_clean;

//outputs pc add four and fence
assign o_dcache_pc_add_four = i_ex_mem.pc_add_four;
assign o_fence = i_ex_mem.fencei;

riscv_mem_forward mem_forward_wiring (
.i_ALU(w_ALU), 
.i_pc_add_four(w_pc_add_four), 
.i_jump_target(w_jump_target), 
.i_mem_forward_ctrl(w_mem_forward_ctrl), 
.o_mem_forward(w_mem_forward)
);

riscv_dcache #(
.WORD_BITS(WORD_BITS), 
.INDEX_BITS(DC_INDEX_BITS), 
.WAYS_AMT(DC_WAYS_AMT), 
.MAIN_MEM_WIDTH(MAIN_MEM_WIDTH)
) dcache_wiring (
.i_clk(i_clk), 
.i_nrst(i_nrst), 
.i_handshake(i_dc_handshake), 
.i_fence(w_fencei), 
.i_wb_in_progress(i_dc_wb_in_progress),
.i_ALU(w_ALU), 
.i_rs2_data(w_rs2_data), 
.i_func3(w_func3), 
.i_memwrite(w_memwrite), 
.i_memread(w_memread), 
.i_index_fetched(i_dc_index_fetched),

.o_dcache_miss(o_dcache_miss), 
.o_index_request(o_dc_index_request),
.o_wb_flag(o_dc_wb_flag), 
.o_wb_addr(o_dc_wb_addr), 
.o_wb_data(o_dc_wb_data), 
.o_load_data(w_load_data), 
.o_dcache_fence(o_dcache_fence), 
.o_fence_wb_way(o_dc_fence_wb_way)
);

riscv_load_ext load_ext_wiring (
.i_dmem_raw(w_load_data), 
.i_func3(w_func3), 
.i_ALU(w_ALU), 
.o_dmem_clean(w_dmem_clean)
); 

`ifdef RVFI 
assign o_mem_wb_next.valid_instruct = i_ex_mem.valid_instruct;
assign o_mem_wb_next.pc = i_ex_mem.pc;
assign o_mem_wb_next.instruct = i_ex_mem.instruct;
assign o_mem_wb_next.alu = w_ALU;
assign o_mem_wb_next.func3 = w_func3; 
assign o_mem_wb_next.rs2_data = w_rs2_data;
assign o_mem_wb_next.mem_write = w_memwrite;
    
`endif

endmodule
