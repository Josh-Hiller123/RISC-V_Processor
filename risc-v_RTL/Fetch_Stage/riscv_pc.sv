module riscv_pc #(
parameter PC_WIDTH = 32,
parameter JUMPS_CTRL = 2,
parameter PC_INITIAL = 0
)(
input logic i_clk,
input logic i_nrst,
input logic [PC_WIDTH-1:0] i_jump_target,
input logic [PC_WIDTH-1:0] i_branch_target,
input logic i_dobranch, 
input logic [JUMPS_CTRL-1:0] i_jumps_ctrl,

output logic [PC_WIDTH-1:0] o_pc,
output logic [PC_WIDTH-1:0] o_pc_add_four
);

localparam JAL = 2'b01;
localparam JALR = 2'b10;

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
    if (i_dobranch)
    w_pc_next = i_branch_target; 
    else if(i_jumps_ctrl > 0)
    case(i_jumps_ctrl)
    JAL: w_pc_next = i_jump_target; 
    JALR: w_pc_next = i_jump_target & ~32'b1; 
    default: w_pc_next = 'x;
    endcase
    else 
    w_pc_next = o_pc_add_four;
end
endmodule
