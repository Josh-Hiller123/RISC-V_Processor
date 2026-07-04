module riscv_pc #(
parameter PC_WIDTH = 32,
parameter JUMPS_CTRL = 2,
parameter PC_INITIAL = 0
)(
input logic i_clk,
input logic i_nrst,
input logic [PC_WIDTH-1:0] i_pc_add_immext, 
input logic [PC_WIDTH-1:0] i_rs1_add_immext,
input logic i_dobranch, 
input logic [JUMPS_CTRL-1:0] i_jumps_ctrl,

output logic [PC_WIDTH-1:0] o_pc
);

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

always_comb 
begin
    case ({i_jumps_ctrl, i_dobranch}) 
    3'b000: w_pc_next = o_pc + 4;
    3'b001: w_pc_next = i_pc_add_immext;
    3'b010: w_pc_next = i_pc_add_immext;
    3'b100: w_pc_next = i_rs1_add_immext; 
    default: w_pc_next = 'x;
    endcase
end
endmodule