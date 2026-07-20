module riscv_main_memory #(
parameter MAIN_MEM_WIDTH = 16, 
parameter INSTRUCT_WIDTH = 32, 
parameter REG_DATAWIDTH = 32,

parameter IC_INDEX_BITS = 5, 
parameter IC_WORD_BITS = 2, 
parameter IC_TAG_BITS = MAIN_MEM_WIDTH-IC_INDEX_BITS-IC_WORD_BITS-2,
parameter ICACHE_ENTRIES = IC_TAG_BITS+((1 << IC_WORD_BITS) * INSTRUCT_WIDTH),

parameter DC_WAYS_AMT = 3,
parameter DC_INDEX_BITS = 5, 
parameter DC_WORD_BITS = 2, 
parameter DC_TAG_BITS = MAIN_MEM_WIDTH-DC_INDEX_BITS-DC_WORD_BITS-2,
parameter DCACHE_ENTRIES = DC_TAG_BITS+((1 << DC_WORD_BITS) * REG_DATAWIDTH), 

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

logic [INSTRUCT_WIDTH-1:0] main_mem [(1 << (MAIN_MEM_WIDTH-2))-1:0];

logic w_mem_access;
logic [$clog2(LATENCY+1)-1:0] latency_counter;
logic [$clog2(LATENCY+1)-1:0] latency_counter_next;
logic latency_finished;
logic dc_wb_finished;

assign w_mem_access = i_dcache_miss || i_dc_wb_flag || (|i_dc_fence_wb_way) || i_icache_miss; 
assign latency_finished = (latency_counter == LATENCY);

assign o_dc_wb_in_progress = (!latency_finished && |(i_dcache_fence)) ? i_dc_fence_wb_way : '0;

int word; 
int word2;
int word3;
always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst)
    begin
        dc_wb_finished <= '0;
        o_dc_index_fetched <= '0;
        o_dc_handshake <= '0;
        o_ic_handshake <= '0; 
        o_ic_index_fetched <= '0; 
    end
    
    else begin
    o_dc_handshake <= '0; 
    o_ic_handshake <= '0;

    if(i_dcache_miss | i_dc_wb_flag | i_dcache_fence)
    begin
        if(latency_finished)
        begin
            if((i_dc_wb_flag && !dc_wb_finished) || i_dcache_fence)
            begin
                for(word = 0; word <= (1 << DC_WORD_BITS) - 1; word++)
                    main_mem[{i_dc_wb_addr, DC_WORD_BITS'(word)}] <= i_dc_wb_data[word*REG_DATAWIDTH+:REG_DATAWIDTH];

                if(i_dc_wb_flag)
                dc_wb_finished <= 1;
                else;
            end

            else 
            begin
                for(word2 = 0; word2 <= (1 << DC_WORD_BITS) - 1; word2++)
                    o_dc_index_fetched[word2*REG_DATAWIDTH+:REG_DATAWIDTH] <= main_mem[{i_dc_index_request, DC_WORD_BITS'(word2)}];

                dc_wb_finished <= 0;
                o_dc_handshake <= 1;
            end
        end
        else ; 
    end
    else if(i_icache_miss && latency_finished)
    begin
        for(word3 = 0; word3 <= (1 << IC_WORD_BITS) - 1; word3++)
            o_ic_index_fetched[word3*INSTRUCT_WIDTH+:INSTRUCT_WIDTH] <= main_mem[{i_ic_index_request, IC_WORD_BITS'(word3)}];
        
        o_ic_handshake <= 1; 
    end
    
    else ;
end


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
end
endmodule