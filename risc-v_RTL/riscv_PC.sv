module riscv_PC #(
parameter IMEM_ADDR_WIDTH = 14
)(
input logic i_clk,
input logic i_nrst,
input logic [IMEM_ADDR_WIDTH-1:0] i_pcsource,
input logic i_pcmux, 
output logic [IMEM_ADDR_WIDTH-1:0] o_pc
);
wire w_pc_next;
always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst)
    begin
        o_pc <= 0; 
    end
    else 
    begin
        o_pc <= w_pc_next; 
    end
end

always_comb 
begin
    case (i_pcmux) 
    1'b0: assign w_pc_next = o_pc + 4;
    1'b1: assign w_pc_next = i_pcsource;
    endcase
end
endmodule