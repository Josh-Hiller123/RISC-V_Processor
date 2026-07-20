import ex_mem_struct::*; 
import id_ex_struct::*;
module riscv_execute_stage #(
parameter ALU_OUT = 32
)(
input id_ex_t i_id_ex, 
output ex_mem_t o_ex_mem_next, 
output logic o_dobranch, 
output logic [ALU_OUT-1:0] o_ALU,
output logic o_jalr_ctrl
);

localparam REG_DATAWIDTH = 32;
localparam IMM_WIDTH = 32;
localparam ALU_OP = 4;
localparam FUNC3 = 3;

logic [REG_DATAWIDTH-1:0] w_rs2_data;
logic [IMM_WIDTH-1:0] w_immext;
logic w_ALUsrc_ctrl;
logic [REG_DATAWIDTH-1:0] w_ALUsrcB;

logic [REG_DATAWIDTH-1:0] w_rs1_data;
logic [ALU_OP-1:0] w_ALUop;
logic [ALU_OUT-1:0] w_ALU;
logic w_zero;

logic [FUNC3-1:0] w_func3; 
logic w_branch_ctrl; 


 
//jalr_ctrl wiring connection 
assign o_jalr_ctrl = i_id_ex.jalr_ctrl;

//i_id_ex wiring connections (from previous reg carrying on to mem)
assign o_ex_mem_next.pc_add_four = i_id_ex.pc_add_four;
assign o_ex_mem_next.mem_write = i_id_ex.mem_write;
assign o_ex_mem_next.mem_read = i_id_ex.mem_read; 
assign o_ex_mem_next.wenable = i_id_ex.wenable; 
assign o_ex_mem_next.mem_forward_ctrl = i_id_ex.mem_forward_ctrl;
assign o_ex_mem_next.rs2_data = w_rs2_data;
assign o_ex_mem_next.rd = i_id_ex.rd;
assign o_ex_mem_next.func3 = w_func3;
assign o_ex_mem_next.jump_target = i_id_ex.jump_target; 
assign o_ex_mem_next.fencei = i_id_ex.fencei;

// ALUsrc wiring connections
assign w_rs2_data = i_id_ex.rs2_data;
assign w_immext = i_id_ex.immext;
assign w_ALUsrc_ctrl = i_id_ex.ALUsrc_ctrl;

//ALU wiring connections
assign w_rs1_data = i_id_ex.rs1_data;
assign w_ALUop = i_id_ex.ALUop; 
assign o_ex_mem_next.alu = w_ALU;
assign o_ALU = w_ALU;

//brancheval wiring connections 
assign w_func3 = i_id_ex.func3;
assign w_branch_ctrl = i_id_ex.branch_ctrl;


riscv_ALUsrc ALUsrc_wiring (
.i_rs2_data(w_rs2_data), 
.i_immext(w_immext), 
.i_ALUsrc_ctrl(w_ALUsrc_ctrl), 
.o_ALUsrcB(w_ALUsrcB)
);

riscv_ALU ALU_wiring (
.i_ALUsrcA(w_rs1_data), 
.i_ALUsrcB(w_ALUsrcB), 
.i_ALUop(w_ALUop), 
.o_ALU(w_ALU),
.o_zero(w_zero)
);

riscv_brancheval brancheval_wiring (
.i_func3(w_func3), 
.i_zero(w_zero), 
.i_branch_ctrl(w_branch_ctrl), 
.o_dobranch(o_dobranch)
);



endmodule

