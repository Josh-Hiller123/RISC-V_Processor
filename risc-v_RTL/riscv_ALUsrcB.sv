module riscv_ALUsrcB #(
parameter INSTRUCT_WIDTH = 32, 
parameter REG_DATAWIDTH = 32, 
parameter ALUSRCB_CTRL = 2
)(
input logic [REG_DATAWIDTH-1:0] i_rs2_data, 
input logic [INSTRUCT_WIDTH-1:0] i_immext, 
input logic [ALUSRCB_CTRL-1:0] i_ALUsrcB_ctrl,

output logic [INSTRUCT_WIDTH-1:0] o_ALUsrcB
);

localparam FOUR = 32'b00000000000000000000000000000100
localparam SELECT_RS2 = 2'b00; 
localparam SELECT_FOUR = 2'b01; 
localparam SELECT_IMMEXT = 2'b11; 

always_comb 
begin
    case (i_ALUsrcB_ctrl)
    SELECT_RS2: o_ALUsrcB = i_rs2_data; 
    SELECT_FOUR: o_ALUsrcB = FOUR; 
    SELECT_IMMEXT: o_ALUsrcB = i_immext;
    default o_ALUsrcB = 'x
    endcase
end 
endmodule