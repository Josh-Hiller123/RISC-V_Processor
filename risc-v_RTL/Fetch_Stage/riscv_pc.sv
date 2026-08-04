module riscv_pc #(
parameter PC_WIDTH = 32,
parameter PC_INITIAL = 32'b0
)(
input logic i_clk,
input logic i_nrst,
input logic [PC_WIDTH-1:0] i_id_jump_target,
input logic [PC_WIDTH-1:0] i_mem_jump_target,
input logic [PC_WIDTH-1:0] i_ALU,
input logic [PC_WIDTH-1:0] i_dcache_pc_add_four,
input logic i_dobranch, 

input logic i_jal_ctrl, 
input logic i_jalr_ctrl,

input logic i_forward_load,
input logic i_icache_miss, 
input logic i_dcache_miss, 
input logic i_dcache_fence,

output logic [PC_WIDTH-1:0] o_pc,
output logic [PC_WIDTH-1:0] o_pc_add_four
);


localparam JALR = 2'b01;
localparam BRANCH = 2'b10; 


logic [PC_WIDTH-1:0] w_pc_next;

always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst)
    begin
        o_pc <= PC_INITIAL; 
    end
    else 
    begin
        o_pc <= w_pc_next; 
    end
end

assign o_pc_add_four = o_pc + 4;

always_comb 
begin
    w_pc_next = o_pc_add_four;

    if(i_dcache_fence | i_dcache_miss)
    case({i_dcache_fence, i_dcache_miss})
    2'b10: w_pc_next = i_dcache_pc_add_four;
    2'b01: w_pc_next = o_pc;
    default: w_pc_next = 'x;
    endcase

    else if (i_dobranch || i_jalr_ctrl)
    case({i_dobranch, i_jalr_ctrl})
    JALR: w_pc_next = i_ALU & ~32'b1; 
    BRANCH: w_pc_next = i_mem_jump_target;
    default: w_pc_next = 'x;
    endcase

    else if(i_jal_ctrl | i_forward_load)
    case({i_jal_ctrl, i_forward_load})
    2'b10: w_pc_next = i_id_jump_target; 
    2'b01: w_pc_next = o_pc;
    default: w_pc_next = 'x;
    endcase

    else if(i_icache_miss)
    w_pc_next = o_pc;
end
endmodule
