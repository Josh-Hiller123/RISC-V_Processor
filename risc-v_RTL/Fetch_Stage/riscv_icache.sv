module riscv_icache #(
parameter PC_WIDTH = 32, 
parameter INSTRUCT_WIDTH = 32, 
parameter MAIN_MEM_WIDTH = 16,
parameter WAYS_AMT = 3, 


parameter INDEX_BITS = 5,
parameter WORD_BITS = 2, 
parameter TAG_BITS = MAIN_MEM_WIDTH-INDEX_BITS-WORD_BITS-2, 
parameter ICACHE_ENTRIES = TAG_BITS+((1 << WORD_BITS) * INSTRUCT_WIDTH)

)(
input logic i_clk,
input logic i_nrst,
input logic i_handshake,
input logic i_fence,
input logic [PC_WIDTH-1:0] i_pc,
input logic [ICACHE_ENTRIES-TAG_BITS-1:0] i_index_fetched,
input logic i_jalr_ctrl,

output logic o_icache_miss,
output logic [TAG_BITS+INDEX_BITS-1:0] o_index_request,
output logic [INSTRUCT_WIDTH-1:0] o_instruct
);

localparam NO_OP = 32'h00000013;
localparam EVICT_BINARY = $clog2(WAYS_AMT);

logic [TAG_BITS-1:0] w_tag;
logic [INDEX_BITS-1:0] w_index; 
logic [WORD_BITS-1:0] w_word;

logic [INSTRUCT_WIDTH-1:0] w_instruct_next;
logic [INSTRUCT_WIDTH-1:0] w_instruct_critical;

logic [ICACHE_ENTRIES-1:0] icache_mem [WAYS_AMT-1:0][(1 << INDEX_BITS)-1:0];
logic [(1 << INDEX_BITS)-1:0] valid_bits [WAYS_AMT-1:0];
logic [WAYS_AMT-1:0] w_hit_way;

logic [WAYS_AMT-1:0] lru_matrix [(1 << INDEX_BITS)-1:0][WAYS_AMT-1:0];
logic [WAYS_AMT-1:0] w_evict_valid;
logic [WAYS_AMT-1:0] w_evict_invalid;
logic [WAYS_AMT-1:0] w_evict_candidates;
logic [WAYS_AMT-1:0] w_evict_one_hot;
logic[EVICT_BINARY-1:0] w_evict_binary;
logic [WAYS_AMT-1:0] w_way_promote;

assign w_tag = i_pc[MAIN_MEM_WIDTH-1:INDEX_BITS+WORD_BITS+2];
assign w_index = i_pc[INDEX_BITS+WORD_BITS+1:WORD_BITS+2];
assign w_word = i_pc[WORD_BITS+1:2];
assign w_instruct_critical = i_index_fetched[(w_word*INSTRUCT_WIDTH)+:INSTRUCT_WIDTH];

assign o_icache_miss = ~(|w_hit_way | i_handshake | i_jalr_ctrl);
assign o_index_request = o_icache_miss ? i_pc[MAIN_MEM_WIDTH-1-:TAG_BITS+INDEX_BITS] : '0;


//determines hit_way 
genvar i; 
generate
    for(i = 0; i <= WAYS_AMT-1; i++) begin: hit_wires
    assign w_hit_way[i] = (valid_bits[i][w_index] && w_tag == icache_mem[i][w_index][ICACHE_ENTRIES-1:ICACHE_ENTRIES-TAG_BITS]);
    end
endgenerate

//lru matrix and invalid bit logic
int p;
int v;
always_ff @(posedge i_clk)
begin
    for(p = 0; p <= WAYS_AMT-1; p++)
    begin
        if(w_way_promote[p])
        begin
            lru_matrix[w_index][p] <= '1; 
            for(v = 0; v <= WAYS_AMT-1; v++)
            lru_matrix[w_index][v][p] <= 0; 
        end
    end
end

int way;
int way2;
always_comb 
begin
    for(way = 0; way <= WAYS_AMT-1; way++)
    begin
        if(!valid_bits[way][w_index])
        begin
            w_evict_invalid[way] = 1; 
            w_evict_valid[way] = 0;
        end
            else if(lru_matrix[w_index][way] == 0)
            begin
                w_evict_valid[way] = 1;
                w_evict_invalid[way] = 0;
            end
                else
                begin
                    w_evict_valid[way] = 0;
                    w_evict_invalid[way] = 0;
                end
    end

    if(w_evict_invalid != 0)
    w_evict_candidates = w_evict_invalid;
        else 
        w_evict_candidates = w_evict_valid;

    w_evict_one_hot = w_evict_candidates & (~w_evict_candidates + 1'b1);

    w_evict_binary = '0;
    for(way2 = 0; way2 <= WAYS_AMT-1; way2++)
    if(w_evict_one_hot[way2])
    w_evict_binary = EVICT_BINARY'(way2);

    w_way_promote = i_handshake ? w_evict_one_hot : w_hit_way;
end

//synchronous writes to the icache from main memory
int ii;
always_ff @(posedge i_clk or negedge i_nrst)
begin
if(!i_nrst | i_fence)
    for(ii = 0; ii <= WAYS_AMT-1; ii++)
    valid_bits[ii] <= '0;
else if(i_handshake)
begin
    icache_mem[w_evict_binary][w_index][ICACHE_ENTRIES-TAG_BITS-1:0] <= i_index_fetched;
    icache_mem[w_evict_binary][w_index][ICACHE_ENTRIES-1-:TAG_BITS] <= w_tag;
    valid_bits[w_evict_binary][w_index] <= 1;
    
end
end

// if-hit logic and instruct_next vs instruct_crticial mux
int x;
always_comb
begin
    case(i_jalr_ctrl)
    1'b1: w_instruct_next = NO_OP;
    1'b0: 
    begin
        w_instruct_next = 'x;
        for(x = 0; x <= WAYS_AMT-1; x++)
            if(w_hit_way[x])    
                w_instruct_next = icache_mem[x][w_index][(w_word*INSTRUCT_WIDTH)+:INSTRUCT_WIDTH];
    end
    endcase

    case(i_handshake)
    1'b0: o_instruct = w_instruct_next;
    1'b1: o_instruct = w_instruct_critical;
    default: o_instruct = 'x;
    endcase
end
endmodule
