module risc_ALUsrcA #(
parameter PC_WIDTH = 32,
parameter REG_DATAWIDTH = 32)
(
input logic [PC_WIDTH-1:0] i_pc,
input logic [REG_DATAWIDTH-1:0] i_rs1_data,
input logic i_ALUsrcA_ctrl,
output logic [PC_WIDTH-1:0] o_ALUsrcA
);

localparam SELECT_PC = 1'b0; 
localparam SELECT_RS1 = 1'b1;

always_comb
begin
    case (i_ALUsrcA_ctrl)
    SELECT_PC: o_ALUsrcA = i_pc; 
    SELECT_RS1: o_ALUsrcA = i_rs1_data;
    default: o_ALUsrcA = 'x;
    endcase
end
endmodule