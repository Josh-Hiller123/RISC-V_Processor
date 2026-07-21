module riscv_ALU_rs1 #(
parameter REG_DATAWIDTH = 32
)
(
input logic [REG_DATAWIDTH-1:0] i_rs1_data, 

input logic [REG_DATAWIDTH-1:0] i_mem_forward_data, 
input logic i_ex_rs1_ctrl, 

input logic [REG_DATAWIDTH-1:0] i_wb_forward_data, 
input logic i_mem_rs1_ctrl, 

output logic [REG_DATAWIDTH-1:0] o_ALU_rs1
);

localparam CHOOSE_RS1_DATA = 2'b00; 
localparam CHOOSE_MEM = 2'b10; 
localparam CHOOSE_WB = 2'b01;

always_comb 
begin
    case({i_ex_rs1_ctrl, i_mem_rs1_ctrl})
    CHOOSE_RS1_DATA: o_ALU_rs1 = i_rs1_data;
    CHOOSE_MEM: o_ALU_rs1 = i_mem_forward_data; 
    CHOOSE_WB: o_ALU_rs1 = i_wb_forward_data;
    default: o_ALU_rs1 = 'x;
    endcase
end

endmodule