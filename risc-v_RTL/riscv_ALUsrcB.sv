module riscv_ALUsrcB #(
parameter INSTRUCT_WIDTH = 32, 
parameter REG_DATAWIDTH = 32
)(
input logic [REG_DATAWIDTH-1:0] i_rs2_data, 
input logic [INSTRUCT_WIDTH-1:0] i_immext, 
input logic i_ALUsrcB_ctrl,

output logic [INSTRUCT_WIDTH-1:0] o_ALUsrcB
);

localparam SELECT_RS2 = 1'b0;  
localparam SELECT_IMMEXT = 1'b1; 

always_comb 
begin
    case (i_ALUsrcB_ctrl)
    SELECT_RS2: o_ALUsrcB = i_rs2_data;  
    SELECT_IMMEXT: o_ALUsrcB = i_immext;
    default o_ALUsrcB = 'x;
    endcase
end 
endmodule