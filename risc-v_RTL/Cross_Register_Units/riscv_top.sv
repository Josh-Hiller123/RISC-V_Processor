import if_id_struct::*;
import id_ex_struct::*;
import ex_mem_struct::*;
import mem_wb_struct::*;
module riscv_top #(
//Main Memory Size and Uniform WORD_BITS for I/D cache
parameter MAIN_MEM_WIDTH = 14, 
parameter WORD_BITS = 2,

//Main Memory Access Latency (clk cycles)
parameter LATENCY = 10,

//Icache Parameters
parameter IC_INDEX_BITS = 5,
parameter IC_WAYS_AMT = 3, 

//Dcache Parameters
parameter DC_INDEX_BITS = 5,
parameter DC_WAYS_AMT = 3, 

//PC starting value 
parameter PC_INITIAL = 32'b0

)(

`ifdef RVFI 
output logic o_valid, 
output logic [31:0] o_pc, 
output logic [31:0] o_instruct, 
output logic [31:0] o_alu, // use for mem address
output logic [2:0] o_func3, //use for store-byte/store-half, tells tb what bits to check against rs2_data
output logic [31:0] o_rs2_data, // mem write data
output logic o_mem_write, //for stores
output logic [31:0] o_dmem_clean, // for loads
`endif

output logic o_wenable, // synthesis
output logic [31:0] o_rd_data,
output logic [4:0] o_rd, 

input logic i_clk, 
input logic i_nrst
);

//Non-parameterizable (don't change)
localparam PC_WIDTH = 32;
localparam INSTRUCT_WIDTH = 32; 
localparam REG_DATAWIDTH = 32;
localparam REG_WIDTH = 5;

localparam IC_TAG_BITS = MAIN_MEM_WIDTH-IC_INDEX_BITS-WORD_BITS-2;
localparam ICACHE_ENTRIES = IC_TAG_BITS+((1 << WORD_BITS) * INSTRUCT_WIDTH);
localparam DC_TAG_BITS = MAIN_MEM_WIDTH-DC_INDEX_BITS-WORD_BITS-2;
localparam DCACHE_ENTRIES = DC_TAG_BITS+((1 << WORD_BITS) * REG_DATAWIDTH);


//fetch_stage inputs 
logic w_ic_handshake; 
logic w_fence; 
logic [ICACHE_ENTRIES-IC_TAG_BITS-1:0] w_ic_index_fetched; 
logic w_jalr_ctrl_id; 
logic [PC_WIDTH-1:0] w_id_jump_target; 
logic [PC_WIDTH-1:0] w_mem_jump_target;
logic [PC_WIDTH-1:0] w_ALU;
logic [PC_WIDTH-1:0] w_dcache_pc_add_four;
logic w_dobranch;
logic w_jal_ctrl; 
logic w_jalr_ctrl_mem;
logic w_forward_load;
logic w_dcache_miss;
logic w_dcache_fence;

//if_id reg 
if_id_t w_if_id_next; 
if_id_t w_if_id; 

//decode_stage inputs 
logic [REG_DATAWIDTH-1:0] w_wb_rd_data;
logic w_wb_wenable;
logic [REG_WIDTH-1:0] w_wb_rd;
logic [REG_WIDTH-1:0] w_ex_rd;
logic w_ex_wenable;
logic [REG_WIDTH-1:0] w_mem_rd;
logic w_mem_wenable;
logic w_ex_memread;

//id_ex reg
id_ex_t w_id_ex_next; 
id_ex_t w_id_ex; 

//execute_stage inputs
logic [REG_DATAWIDTH-1:0] w_mem_forward_data;
logic [REG_DATAWIDTH-1:0] w_wb_forward_data;

//ex_mem reg
ex_mem_t w_ex_mem_next;
ex_mem_t w_ex_mem;

//memory_stage inputs
logic w_dc_handshake;
logic [DC_WAYS_AMT-1:0] w_dc_wb_in_progress;
logic [DCACHE_ENTRIES-DC_TAG_BITS-1:0] w_dc_index_fetched;

//mem_wb reg
mem_wb_t w_mem_wb_next;
mem_wb_t w_mem_wb;

//main_memory inputs
logic w_icache_miss; 
logic [IC_TAG_BITS+IC_INDEX_BITS-1:0] w_ic_index_request; 
logic [DC_TAG_BITS+DC_INDEX_BITS-1:0] w_dc_index_request;
logic w_dc_wb_flag;
logic [DC_TAG_BITS+DC_INDEX_BITS-1:0] w_dc_wb_addr;
logic [DCACHE_ENTRIES-DC_TAG_BITS-1:0] w_dc_wb_data;
logic [DC_WAYS_AMT-1:0] w_dc_fence_wb_way;

//flush outputs
logic w_flush_if_id; 
logic w_flush_id_ex;
logic w_flush_ex_mem;

//stall outputs
logic w_stall_if_id;
logic w_stall_id_ex; 
logic w_stall_ex_mem;
logic w_stall_mem_wb;

assign w_wb_forward_data = w_wb_rd_data; // less confusing for naming convention

riscv_fetch_stage #(
.MAIN_MEM_WIDTH(MAIN_MEM_WIDTH),
.WORD_BITS(WORD_BITS), 
.IC_INDEX_BITS(IC_INDEX_BITS), 
.IC_WAYS_AMT(IC_WAYS_AMT), 
.PC_INITIAL(PC_INITIAL)
) fetch_stage_wiring (
.i_clk(i_clk), 
.i_nrst(i_nrst),  

.i_ic_handshake(w_ic_handshake), 
.i_fence(w_fence), 
.i_ic_index_fetched(w_ic_index_fetched),
.i_jalr_ctrl_id(w_jalr_ctrl_id), 
.i_id_jump_target(w_id_jump_target), 
.i_mem_jump_target(w_mem_jump_target), // change pc namings
.i_ALU(w_ALU), 
.i_dcache_pc_add_four(w_dcache_pc_add_four), 
.i_dobranch(w_dobranch), 
.i_jal_ctrl(w_jal_ctrl), 
.i_jalr_ctrl(w_jalr_ctrl_mem), 
.i_forward_load(w_forward_load), 
.i_dcache_miss(w_dcache_miss), 
.i_dcache_fence(w_dcache_fence), 

.o_icache_miss(w_icache_miss), 
.o_ic_index_request(w_ic_index_request), 
.o_if_id_next(w_if_id_next)
);

riscv_if_id_reg if_id_wiring (
.i_clk(i_clk), 
.i_nrst(i_nrst), 

.i_flush_if_id(w_flush_if_id), 
.i_stall_if_id(w_stall_if_id), 
.i_if_id_next(w_if_id_next), 

.o_if_id(w_if_id)
);

riscv_decode_stage decode_stage_wiring (
.i_clk(i_clk),
.i_if_id(w_if_id),

.i_wb_rd_data(w_wb_rd_data), 
.i_wb_wenable(w_wb_wenable), 
.i_wb_rd(w_wb_rd), 
.i_ex_rd(w_ex_rd), 
.i_ex_wenable(w_ex_wenable), 
.i_mem_rd(w_mem_rd), 
.i_mem_wenable(w_mem_wenable), 
.i_ex_memread(w_ex_memread),

.o_id_ex_next(w_id_ex_next), 
.o_jal_ctrl(w_jal_ctrl), 
.o_jalr_ctrl(w_jalr_ctrl_id),
.o_jump_target(w_id_jump_target),
.o_forward_load(w_forward_load) 
);

riscv_id_ex_reg id_mem_wiring (
.i_clk(i_clk), 
.i_nrst(i_nrst), 
.i_id_ex_next(w_id_ex_next),

.i_flush_id_ex(w_flush_id_ex), 
.i_stall_id_ex(w_stall_id_ex),

.o_id_ex(w_id_ex)
); 

riscv_execute_stage execute_stage_wiring (
.i_id_ex(w_id_ex), 
.i_mem_forward_data(w_mem_forward_data), 
.i_wb_forward_data(w_wb_forward_data),

.o_ex_mem_next(w_ex_mem_next), 
.o_ex_rd(w_ex_rd),
.o_ex_wenable(w_ex_wenable),
.o_ex_memread(w_ex_memread)
);

riscv_ex_mem_reg ex_mem_wiring (
.i_clk(i_clk), 
.i_nrst(i_nrst),

.i_stall_ex_mem(w_stall_ex_mem),
.i_flush_ex_mem(w_flush_ex_mem),
.i_ex_mem_next(w_ex_mem_next), 

.o_ex_mem(w_ex_mem)
);

riscv_memory_stage #(
.MAIN_MEM_WIDTH(MAIN_MEM_WIDTH),
.WORD_BITS(WORD_BITS), 
.DC_INDEX_BITS(DC_INDEX_BITS), 
.DC_WAYS_AMT(DC_WAYS_AMT) 
) memory_stage_wiring (
.i_clk(i_clk),
.i_nrst(i_nrst), 
.i_ex_mem(w_ex_mem), 

.i_dc_handshake(w_dc_handshake), 
.i_dc_wb_in_progress(w_dc_wb_in_progress), 
.i_dc_index_fetched(w_dc_index_fetched), 

.o_dcache_miss(w_dcache_miss), 
.o_dc_index_request(w_dc_index_request), 
.o_dc_wb_flag(w_dc_wb_flag), 
.o_dc_wb_addr(w_dc_wb_addr),
.o_dc_wb_data(w_dc_wb_data),
.o_dcache_fence(w_dcache_fence), 
.o_dc_fence_wb_way(w_dc_fence_wb_way), 

.o_mem_wb_next(w_mem_wb_next), 
.o_mem_forward(w_mem_forward_data), 
.o_mem_rd(w_mem_rd),
.o_mem_wenable(w_mem_wenable),
.o_dcache_pc_add_four(w_dcache_pc_add_four),
.o_fence(w_fence), 

.o_jalr_ctrl(w_jalr_ctrl_mem), 
.o_dobranch(w_dobranch), 
.o_mem_jump_target(w_mem_jump_target),
.o_ALU(w_ALU)
);

riscv_mem_wb_reg mem_wb_wiring (
.i_clk(i_clk), 
.i_nrst(i_nrst), 
.i_stall_mem_wb(w_stall_mem_wb), 
.i_mem_wb_next(w_mem_wb_next), 

.o_mem_wb(w_mem_wb)
);

`ifdef RVFI 
logic w_valid_instruct;
assign o_valid = w_valid_instruct && !w_stall_mem_wb;
`endif

assign o_wenable = w_wb_wenable; // synthesis
assign o_rd_data = w_wb_rd_data;
assign o_rd = w_wb_rd;

riscv_wb_stage wb_stage_wiring (
`ifdef RVFI 
.o_valid_instruct(w_valid_instruct), 
.o_pc(o_pc), 
.o_instruct(o_instruct), 
.o_alu(o_alu), 
.o_func3(o_func3), 
.o_rs2_data(o_rs2_data), 
.o_mem_write(o_mem_write), 
.o_dmem_clean(o_dmem_clean),
`endif

.i_mem_wb(w_mem_wb), 
.o_wb_rd_data(w_wb_rd_data), 
.o_wb_wenable(w_wb_wenable), 
.o_wb_rd(w_wb_rd)
);

riscv_main_memory #(
.MAIN_MEM_WIDTH(MAIN_MEM_WIDTH), 
.WORD_BITS(WORD_BITS), 
.LATENCY(LATENCY),
.IC_INDEX_BITS(IC_INDEX_BITS), 
.DC_INDEX_BITS(DC_INDEX_BITS), 
.DC_WAYS_AMT(DC_WAYS_AMT)
) main_memory_wiring (
.i_clk(i_clk), 
.i_nrst(i_nrst), 
.i_icache_miss(w_icache_miss), 
.i_ic_index_request(w_ic_index_request), 
.i_dcache_miss(w_dcache_miss),
.i_dc_index_request(w_dc_index_request), 
.i_dc_wb_flag(w_dc_wb_flag),
.i_dc_wb_addr(w_dc_wb_addr),
.i_dc_wb_data(w_dc_wb_data),
.i_dcache_fence(w_dcache_fence), 
.i_dc_fence_wb_way(w_dc_fence_wb_way), 
.o_ic_handshake(w_ic_handshake), 
.o_ic_index_fetched(w_ic_index_fetched),
.o_dc_handshake(w_dc_handshake), 
.o_dc_wb_in_progress(w_dc_wb_in_progress), 
.o_dc_index_fetched(w_dc_index_fetched)
);

riscv_flush flush_wiring (
.i_jal_ctrl(w_jal_ctrl), 
.i_jalr_ctrl(w_jalr_ctrl_mem),
.i_dobranch(w_dobranch), 
.i_icache_miss(w_icache_miss),
.i_dcache_miss(w_dcache_miss), 
.i_dcache_fence(w_dcache_fence), 
.i_forward_load(w_forward_load), 

.o_flush_if_id(w_flush_if_id), 
.o_flush_id_ex(w_flush_id_ex), 
.o_flush_ex_mem(w_flush_ex_mem)
);

riscv_stall stall_wiring (
.i_dcache_miss(w_dcache_miss), 
.i_dcache_fence(w_dcache_fence),
.i_forward_load(w_forward_load), 
.i_dobranch(w_dobranch), 
.i_jalr_ctrl(w_jalr_ctrl_mem),

.o_stall_if_id(w_stall_if_id), 
.o_stall_id_ex(w_stall_id_ex), 
.o_stall_ex_mem(w_stall_ex_mem), 
.o_stall_mem_wb(w_stall_mem_wb)

);

endmodule 