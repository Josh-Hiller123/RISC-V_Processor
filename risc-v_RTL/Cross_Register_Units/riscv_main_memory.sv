module riscv_main_memory #(
parameter MAIN_MEM_WIDTH = 16,
parameter WORD_BITS = 2,
parameter INSTRUCT_WIDTH = 32,
parameter REG_DATAWIDTH = 32,

parameter IC_INDEX_BITS = 5,
parameter IC_TAG_BITS = MAIN_MEM_WIDTH-IC_INDEX_BITS-WORD_BITS-2,
parameter ICACHE_ENTRIES = IC_TAG_BITS+((1 << WORD_BITS) * INSTRUCT_WIDTH),

parameter DC_WAYS_AMT = 3,
parameter DC_INDEX_BITS = 5,
parameter DC_TAG_BITS = MAIN_MEM_WIDTH-DC_INDEX_BITS-WORD_BITS-2,
parameter DCACHE_ENTRIES = DC_TAG_BITS+((1 << WORD_BITS) * REG_DATAWIDTH),

parameter LATENCY = 10
)(

input logic i_clk,
input logic i_nrst,

input logic i_icache_miss,
input logic [IC_TAG_BITS+IC_INDEX_BITS-1:0] i_ic_index_request,

input logic i_dcache_miss,
input logic [DC_TAG_BITS+DC_INDEX_BITS-1:0] i_dc_index_request,
input logic i_dc_wb_flag,
input logic [DC_TAG_BITS+DC_INDEX_BITS-1:0] i_dc_wb_addr,
input logic [DCACHE_ENTRIES-DC_TAG_BITS-1:0] i_dc_wb_data,
input logic i_dcache_fence,
input logic [DC_WAYS_AMT-1:0] i_dc_fence_wb_way,

output logic o_ic_handshake,
output logic [ICACHE_ENTRIES-IC_TAG_BITS-1:0] o_ic_index_fetched,

output logic o_dc_handshake,
output logic [DC_WAYS_AMT-1:0] o_dc_wb_in_progress,
output logic [DCACHE_ENTRIES-DC_TAG_BITS-1:0] o_dc_index_fetched

);

localparam BLOCK_WIDTH = (1 << WORD_BITS) * REG_DATAWIDTH;            
localparam MAIN_MEM_ENTRIES   = (1 << (MAIN_MEM_WIDTH-WORD_BITS-2));  

//forces Vivado to infer BRAM
(* ram_style = "block" *) 
logic [BLOCK_WIDTH-1:0] main_mem [MAIN_MEM_ENTRIES-1:0];

logic w_mem_access;
logic [$clog2(LATENCY+1)-1:0] latency_counter;
logic [$clog2(LATENCY+1)-1:0] latency_counter_next;
logic latency_finished;
logic dc_wb_finished;

logic r_icache_miss;
logic [IC_TAG_BITS+IC_INDEX_BITS-1:0] r_ic_index_request;
logic r_dcache_miss;
logic [DC_TAG_BITS+DC_INDEX_BITS-1:0] r_dc_index_request;
logic r_dc_wb_flag;
logic [DC_TAG_BITS+DC_INDEX_BITS-1:0] r_dc_wb_addr;
logic [DCACHE_ENTRIES-DC_TAG_BITS-1:0] r_dc_wb_data;

assign w_mem_access = r_dcache_miss || r_dc_wb_flag || (|i_dc_fence_wb_way) || r_icache_miss;
assign latency_finished = (latency_counter == LATENCY);

logic w_dc_mem_access;   
logic w_dc_write;  
logic w_dc_read;  
logic w_ic_read;  

// Assign statements for each scenario, logic ensures priority by nature
assign w_dc_mem_access = r_dcache_miss | r_dc_wb_flag | i_dcache_fence; 
assign w_dc_write = w_dc_mem_access && latency_finished && ((r_dc_wb_flag && !dc_wb_finished) || (i_dcache_fence && (|i_dc_fence_wb_way)));
assign w_dc_read  = w_dc_mem_access && latency_finished && !((r_dc_wb_flag && !dc_wb_finished) || i_dcache_fence);
assign w_ic_read  = !w_dc_mem_access && r_icache_miss && latency_finished;

//registered flags to attack critical path
always_ff @(posedge i_clk)
begin
    if(!i_nrst)
    begin
        r_icache_miss <= '0;
        r_ic_index_request <= '0;
        r_dcache_miss <= '0;
        r_dc_index_request <= '0;
        r_dc_wb_flag <= '0;
        r_dc_wb_addr <= '0;
        r_dc_wb_data <= '0;
    end
    else
    begin
        r_icache_miss <= i_icache_miss;
        r_ic_index_request <= i_ic_index_request;
        r_dcache_miss <= i_dcache_miss;
        r_dc_index_request <= i_dc_index_request;
        r_dc_wb_flag <= i_dc_wb_flag;
        r_dc_wb_addr <= i_dc_wb_addr;
        r_dc_wb_data <= i_dc_wb_data;
    end
end

//Memory write/reads, no priority needed since combinational logic above ensures mutual exclusivity
always_ff @(posedge i_clk)
begin
    if(w_dc_write) main_mem[r_dc_wb_addr] <= r_dc_wb_data;            
    
    if(w_dc_read)  o_dc_index_fetched <= main_mem[r_dc_index_request]; 
    if(w_ic_read)  o_ic_index_fetched <= main_mem[r_ic_index_request]; 
end

//seperate block for communication with the caches, again no priority needed here for the same reason
always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst)
    begin
        dc_wb_finished <= '0;
        o_dc_handshake <= '0;
        o_ic_handshake <= '0;
        o_dc_wb_in_progress <= '0;
    end
    else
    begin
        o_dc_handshake <= '0;
        o_ic_handshake <= '0;
        o_dc_wb_in_progress <= '0;

        if(!latency_finished && i_dcache_fence)
        o_dc_wb_in_progress <= i_dc_fence_wb_way;

        if(w_dc_write && r_dc_wb_flag)
        dc_wb_finished <= 1;

        if(w_dc_read)
        begin
            dc_wb_finished <= 0;
            o_dc_handshake <= 1;
        end

        if(w_ic_read)
        o_ic_handshake <= 1;
    end
end

//latency model for memory accesses, parameterizable by changing LATENCY 
always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst || latency_finished)
        latency_counter <= '0;
    else
        latency_counter <= latency_counter_next;
end

always_comb
begin
    case(w_mem_access)
    1'b1: latency_counter_next = latency_counter + 1;
    default: latency_counter_next = '0;
    endcase
end
endmodule
