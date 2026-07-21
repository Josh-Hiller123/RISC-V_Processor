module riscv_ALU_rs2 #(
parameter REG_DATAWIDTH = 32
)
(
input logic [REG_DATAWIDTH-1:0] i_rs2_data, 

input logic [REG_DATAWIDTH-1:0] i_mem_forward_data, 
input logic i_ex_rs2_ctrl, 

input logic [REG_DATAWIDTH-1:0] i_wb_forward_data, 
input logic i_mem_rs2_ctrl, 

output logic [REG_DATAWIDTH-1:0] o_ALU_rs2
);

localparam CHOOSE_RS2_DATA = 2'b00; 
localparam CHOOSE_MEM = 2'b10; 
localparam CHOOSE_WB = 2'b01;

always_comb 
begin
    case({i_ex_rs2_ctrl, i_mem_rs2_ctrl})
    CHOOSE_RS2_DATA: o_ALU_rs2 = i_rs2_data;
    CHOOSE_MEM: o_ALU_rs2 = i_mem_forward_data; 
    CHOOSE_WB: o_ALU_rs2 = i_wb_forward_data;
    default: o_ALU_rs2 = 'x;
    endcase
end

endmodule