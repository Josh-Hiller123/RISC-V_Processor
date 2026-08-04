module riscv_dcache #(
parameter ALU = 32,
parameter REG_DATAWIDTH = 32,
parameter FUNC3 = 3,
parameter MAIN_MEM_WIDTH = 16,

parameter WAYS_AMT = 3,


parameter INDEX_BITS = 5,
parameter WORD_BITS = 2,
parameter TAG_BITS = MAIN_MEM_WIDTH-INDEX_BITS-WORD_BITS-2,
parameter DCACHE_ENTRIES = TAG_BITS+((1 << WORD_BITS) * REG_DATAWIDTH),
parameter EVICT_BINARY = $clog2(WAYS_AMT)

)(
input logic i_clk,
input logic i_nrst,
input logic i_handshake,
input logic i_fence,
input logic [WAYS_AMT-1:0] i_wb_in_progress,

input logic [ALU-1:0] i_ALU,
input logic [REG_DATAWIDTH-1:0] i_rs2_data,
input logic[FUNC3-1:0] i_func3,
input logic i_memwrite,
input logic i_memread,
input logic [DCACHE_ENTRIES-TAG_BITS-1:0] i_index_fetched,

output logic o_dcache_miss,
output logic [TAG_BITS+INDEX_BITS-1:0] o_index_request,
output logic o_wb_flag,
output logic [TAG_BITS+INDEX_BITS-1:0] o_wb_addr,
output logic [DCACHE_ENTRIES-TAG_BITS-1:0] o_wb_data,
output logic [REG_DATAWIDTH-1:0] o_load_data,

output logic o_dcache_fence,
output logic [WAYS_AMT-1:0] o_fence_wb_way
);

// FUNC3 PARAMS
localparam CHOOSE_SB = 3'b000;
localparam CHOOSE_SH = 3'b001;
localparam CHOOSE_SW = 3'b010;

//SB PARAMS
localparam CHOOSE_BYTE0 = 2'b00;
localparam CHOOSE_BYTE1 = 2'b01;
localparam CHOOSE_BYTE2 = 2'b10;
localparam CHOOSE_BYTE3 = 2'b11;

//SH PARAMS
localparam CHOOSE_HALF0 = 1'b0;
localparam CHOOSE_HALF1 = 1'b1;


logic [TAG_BITS-1:0] w_tag;
logic [INDEX_BITS-1:0] w_index;
logic [WORD_BITS-1:0] w_word;

logic [REG_DATAWIDTH-1:0] w_load_next;
logic [REG_DATAWIDTH-1:0] w_load_critical;

logic [DCACHE_ENTRIES-1:0] w_dcache_line [WAYS_AMT-1:0];
logic [INDEX_BITS-1:0] w_dcache_line_addr;
logic [(1 << INDEX_BITS)-1:0] valid_bits [WAYS_AMT-1:0];
logic [(1 << INDEX_BITS)-1:0] dirty_bits [WAYS_AMT-1:0];

logic [WAYS_AMT-1:0] w_hit_way;

logic [WAYS_AMT-1:0] lru_matrix [(1 << INDEX_BITS)-1:0][WAYS_AMT-1:0];
logic [WAYS_AMT-1:0] w_evict_valid;
logic [WAYS_AMT-1:0] w_evict_invalid;
logic [WAYS_AMT-1:0] w_evict_candidates;
logic [WAYS_AMT-1:0] w_evict_one_hot;
logic [EVICT_BINARY-1:0] w_evict_binary;
logic [WAYS_AMT-1:0] w_way_promote;

logic [WAYS_AMT-1:0] w_way_wenable;                
logic [DCACHE_ENTRIES-1:0] w_write_line [WAYS_AMT-1:0]; 

logic [INDEX_BITS-1:0] fence_pointer;
logic [WAYS_AMT-1:0] w_fence_dirty_ways;
logic [WAYS_AMT-1:0] w_fence_wb_one_hot;
logic [EVICT_BINARY-1:0] w_fence_wb_binary;
logic w_fence_delayed;
logic [WAYS_AMT-1:0] w_wb_prev;
logic w_check_dirty;
logic w_check_dirty_next;
logic w_fence_doflush;
logic w_fence_wb_delay;



assign w_tag = i_ALU[MAIN_MEM_WIDTH-1:INDEX_BITS+WORD_BITS+2];
assign w_index = i_ALU[INDEX_BITS+WORD_BITS+1:WORD_BITS+2];
assign w_word = i_ALU[WORD_BITS+1:2];
assign w_load_critical = i_index_fetched[(w_word*REG_DATAWIDTH)+:REG_DATAWIDTH];

assign o_dcache_miss = (i_memwrite | i_memread) && ~(|w_hit_way | i_handshake);
assign o_index_request = o_dcache_miss ? i_ALU[MAIN_MEM_WIDTH-1-:TAG_BITS+INDEX_BITS] : '0;

assign o_wb_flag = (o_dcache_miss && (dirty_bits[w_evict_binary][w_index] == 1));
assign o_wb_addr = o_dcache_fence ? {w_dcache_line[w_fence_wb_binary][DCACHE_ENTRIES-1-:TAG_BITS], fence_pointer}
                                : {w_dcache_line[w_evict_binary][DCACHE_ENTRIES-1-:TAG_BITS], w_index};
assign o_wb_data = o_dcache_fence ? w_dcache_line[w_fence_wb_binary][DCACHE_ENTRIES-TAG_BITS-1:0]
                                : w_dcache_line[w_evict_binary][DCACHE_ENTRIES-TAG_BITS-1:0];
assign w_dcache_line_addr = o_dcache_fence ? fence_pointer : w_index;

assign o_dcache_fence  = (i_fence && w_fence_doflush) || (i_fence && !w_fence_delayed);
assign w_fence_doflush = w_check_dirty;

assign o_fence_wb_way  = (o_dcache_fence && !w_fence_wb_delay) ? w_fence_wb_one_hot : '0;
assign w_fence_wb_delay = (|w_wb_prev && !(|i_wb_in_progress));


//determines hit_way
genvar i;
generate
    for(i = 0; i <= WAYS_AMT-1; i++) begin: hit_wires
    assign w_hit_way[i] = (i_memwrite | i_memread) && (!o_dcache_fence && valid_bits[i][w_index] && w_tag == w_dcache_line[i][DCACHE_ENTRIES-1:DCACHE_ENTRIES-TAG_BITS]);
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

//Combinational store logic
int wc;
always_comb
begin
    for(wc = 0; wc <= WAYS_AMT-1; wc++)
    begin
        w_way_wenable[wc]   = 1'b0;
        w_write_line[wc] = w_dcache_line[wc];

        if(i_handshake && (wc == w_evict_binary)) 
        begin
            w_way_wenable[wc]   = 1'b1;
            w_write_line[wc] = {w_tag, i_index_fetched};
        end
        if(i_memwrite && w_way_promote[wc])
        begin
            w_way_wenable[wc] = 1'b1;
            case(i_func3)
            CHOOSE_SB:
                case(i_ALU[1:0])
                    CHOOSE_BYTE0: w_write_line[wc][w_word*REG_DATAWIDTH+:8] = i_rs2_data[7:0];
                    CHOOSE_BYTE1: w_write_line[wc][8+(w_word*REG_DATAWIDTH)+:8] = i_rs2_data[7:0];
                    CHOOSE_BYTE2: w_write_line[wc][16+(w_word*REG_DATAWIDTH)+:8] = i_rs2_data[7:0];
                    CHOOSE_BYTE3: w_write_line[wc][24+(w_word*REG_DATAWIDTH)+:8] = i_rs2_data[7:0];
                    default: ;
                endcase
            CHOOSE_SH:
                case(i_ALU[1])
                    CHOOSE_HALF0: w_write_line[wc][w_word*REG_DATAWIDTH+:16] = i_rs2_data[15:0];
                    CHOOSE_HALF1: w_write_line[wc][16+(w_word*REG_DATAWIDTH)+:16] = i_rs2_data[15:0];
                    default: ;
                endcase
            CHOOSE_SW:
                w_write_line[wc][w_word*REG_DATAWIDTH+:32] = i_rs2_data;
                default: ;
            endcase
        end
    end
end

//memory declared per-way, synchronous writes
genvar g;
generate
    for(g = 0; g <= WAYS_AMT-1; g++) begin: way_ram
        logic [DCACHE_ENTRIES-1:0] dcache_mem [(1 << INDEX_BITS)-1:0];

        always_ff @(posedge i_clk)
        begin
            if(w_way_wenable[g])
            dcache_mem[w_dcache_line_addr] <= w_write_line[g];
        end

        assign w_dcache_line[g] = dcache_mem[w_dcache_line_addr];
    end
endgenerate

//Valid + dirty bit logic
int ii;
int w;
int fc;
always_ff @(posedge i_clk or negedge i_nrst)
begin
if(!i_nrst)
    for(ii = 0; ii <= WAYS_AMT-1; ii++)
    begin
    valid_bits[ii] <= '0;
    dirty_bits[ii] <= '0;
    end
else
begin
    if(i_handshake)
    begin
        valid_bits[w_evict_binary][w_index] <= 1;
        dirty_bits[w_evict_binary][w_index] <= 0;
    end
    if(i_fence)
    for(fc = 0; fc <= WAYS_AMT-1; fc++)
        if(w_wb_prev[fc] && !i_wb_in_progress[fc])
        dirty_bits[fc][fence_pointer] <= 1'b0;

    if(i_memwrite && (w_hit_way | i_handshake))
    for(w = 0; w <= WAYS_AMT-1; w++)
        if(w_way_promote[w])
        dirty_bits[w][w_index] <= 1;
end
end

// if-hit logic *for loads* and data_next vs data_crticial mux
int x;
always_comb
begin
    w_load_next = 'x;
    for(x = 0; x <= WAYS_AMT-1; x++)
        if(w_hit_way[x])
            w_load_next = w_dcache_line[x][(w_word*REG_DATAWIDTH)+:REG_DATAWIDTH];

    case(i_handshake)
    1'b0: o_load_data = w_load_next;
    1'b1: o_load_data = w_load_critical;
    default: o_load_data = 'x;
    endcase
end

//fence calculates which way is dirty, used as index for wb addr/data and
//as a flag for main mem to know a wb is happening
int fd;
always_comb
begin
    for(fd = 0; fd <= WAYS_AMT-1; fd++)
    w_fence_dirty_ways[fd] = dirty_bits[fd][fence_pointer];

    w_fence_wb_one_hot = w_fence_dirty_ways & (~w_fence_dirty_ways + 1'b1);

    w_fence_wb_binary = '0;
    for(fd = 0; fd <= WAYS_AMT-1; fd++)
    if(w_fence_wb_one_hot[fd])
    w_fence_wb_binary = EVICT_BINARY'(fd);
end

//gated w_check_dirty to attack critical path from vivado
always_ff @(posedge i_clk or negedge i_nrst) 
begin
    if(!i_nrst)
    w_check_dirty <= '0;
    else
    w_check_dirty <= w_check_dirty_next;
end

//fence guarantees one cycle of latency regardless of dirty or not, consequence of gating w_check_dirty
always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst)
    w_fence_delayed <= '0;
    else
    w_fence_delayed <= i_fence;
end
//fence-pointer logic to check what needs to be wb to main mem
int d;
always_comb
begin
    w_check_dirty_next = '0;
    for(d = 0; d <= WAYS_AMT-1; d++)
    w_check_dirty_next = (w_check_dirty_next || (|dirty_bits[d]));
end

always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst)
    begin
        fence_pointer <= '0;
        w_wb_prev <= '0;
    end
    else
    begin
        w_wb_prev <= i_wb_in_progress;
        if(!i_fence)
        fence_pointer <= '0;
        else if(w_fence_doflush && !(|w_fence_dirty_ways))
        fence_pointer <= fence_pointer + 1'b1;
    end
end


endmodule
