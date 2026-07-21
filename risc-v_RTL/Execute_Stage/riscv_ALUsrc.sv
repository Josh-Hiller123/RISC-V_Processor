module riscv_ALUsrc #(
parameter IMM_WIDTH = 32, 
parameter REG_DATAWIDTH = 32
)(
input logic [REG_DATAWIDTH-1:0] i_ALU_rs2, 
input logic [IMM_WIDTH-1:0] i_immext, 
input logic i_ALUsrc_ctrl,

output logic [REG_DATAWIDTH-1:0] o_ALUsrc
);

localparam SELECT_RS2 = 1'b0;  
localparam SELECT_IMMEXT = 1'b1; 

always_comb 
begin
    case (i_ALUsrc_ctrl)
    SELECT_RS2: o_ALUsrc = i_ALU_rs2;  
    SELECT_IMMEXT: o_ALUsrc = i_immext;
    default o_ALUsrc = 'x;
    endcase
end 
endmodule