module riscv_forwarding #(
parameter REG_WIDTH = 5, 
parameter INSTRUCT_WIDTH = 32
)(
input logic [REG_WIDTH-1:0] i_ex_rd,
input logic i_ex_wenable,

input logic [REG_WIDTH-1:0] i_mem_rd, 
input logic i_mem_wenable, 

input logic [INSTRUCT_WIDTH-1:0] i_id_instruct,

input logic i_ex_memread,

output logic o_ex_rs1_ctrl, 
output logic o_ex_rs2_ctrl,
output logic o_mem_rs1_ctrl, 
output logic o_mem_rs2_ctrl, 
output logic o_forward_load 
); 

localparam FORWARD_NORMAL = 1'b0;
localparam FORWARD_LOAD = 1'b1;

logic [REG_WIDTH-1:0] w_id_rs1;
logic [REG_WIDTH-1:0] w_id_rs2;

assign w_id_rs1 = i_id_instruct[19:15];
assign w_id_rs2 = i_id_instruct[24:20];


always_comb 
begin
    o_ex_rs1_ctrl = 0; 
    o_ex_rs2_ctrl = 0;
    o_mem_rs1_ctrl = 0; 
    o_mem_rs2_ctrl = 0;
    o_forward_load = 0;

    if(i_ex_wenable && i_ex_rd != 0 && i_ex_rd == w_id_rs1)
    begin
        case({i_ex_memread})
        FORWARD_NORMAL: o_ex_rs1_ctrl = 1;
        FORWARD_LOAD: o_forward_load = 1;
        default: o_ex_rs1_ctrl = 'x;
        endcase
    end
        else if (i_mem_wenable && i_mem_rd != 0 && i_mem_rd == w_id_rs1)
        o_mem_rs1_ctrl = 1;

    if(i_ex_wenable && i_ex_rd != 0 && i_ex_rd == w_id_rs2)
    begin
        case({i_ex_memread})
        FORWARD_NORMAL: o_ex_rs2_ctrl = 1;
        FORWARD_LOAD: o_forward_load = 1;
        default: o_ex_rs2_ctrl = 'x;
        endcase
    end
        else if (i_mem_wenable && i_mem_rd != 0 && i_mem_rd == w_id_rs2)
        o_mem_rs2_ctrl = 1;
end
endmodule

