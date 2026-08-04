import ex_mem_struct::*; 
import id_ex_struct::*;
module riscv_execute_stage #(
parameter ALU_OUT = 32, 
parameter REG_DATAWIDTH = 32, 
parameter REG_WIDTH = 5, 
parameter PC_WIDTH = 32
)(
input id_ex_t i_id_ex, 

//ALU_srcA/B inputs
input logic [REG_DATAWIDTH-1:0] i_mem_forward_data, 
input logic [REG_DATAWIDTH-1:0] i_wb_forward_data, 

output ex_mem_t o_ex_mem_next, 

output logic [REG_WIDTH-1:0] o_ex_rd, 
output logic o_ex_wenable, 
output logic o_ex_memread 

);

localparam IMM_WIDTH = 32;
localparam ALU_OP = 4;
localparam FUNC3 = 3;

logic [REG_DATAWIDTH-1:0] w_rs2_data;
logic [IMM_WIDTH-1:0] w_immext;
logic w_ALUsrc_ctrl;
logic [REG_DATAWIDTH-1:0] w_ALUsrc;

logic [REG_DATAWIDTH-1:0] w_rs1_data;
logic [ALU_OP-1:0] w_ALUop;
logic [ALU_OUT-1:0] w_ALU;
logic w_zero;

logic [FUNC3-1:0] w_func3; 
logic w_branch_ctrl; 

logic w_ex_rs1_ctrl;
logic w_ex_rs2_ctrl;
logic w_mem_rs1_ctrl;
logic w_mem_rs2_ctrl;

logic [REG_DATAWIDTH-1:0] w_ALU_rs1;
logic [REG_DATAWIDTH-1:0] w_ALU_rs2;

logic w_jalr_ctrl; 
logic w_dobranch;
 
//jalr_ctrl/jump_target/branch wiring connection 
assign w_jalr_ctrl = i_id_ex.jalr_ctrl;

assign o_ex_mem_next.jalr_ctrl = w_jalr_ctrl; 
assign o_ex_mem_next.dobranch = w_dobranch; 

//i_id_ex wiring connections (from previous reg carrying on to mem)
assign o_ex_mem_next.pc_add_four = i_id_ex.pc_add_four;
assign o_ex_mem_next.mem_write = i_id_ex.mem_write;
assign o_ex_mem_next.mem_read = i_id_ex.mem_read; 
assign o_ex_mem_next.wenable = i_id_ex.wenable; 
assign o_ex_mem_next.mem_forward_ctrl = i_id_ex.mem_forward_ctrl;
assign o_ex_mem_next.rs2_data = w_ALU_rs2;
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

//brancheval wiring connections 
assign w_func3 = i_id_ex.func3;
assign w_branch_ctrl = i_id_ex.branch_ctrl;

//ALU_srcA/B ctrl signal wiring
assign w_ex_rs1_ctrl = i_id_ex.ex_rs1_ctrl;
assign w_ex_rs2_ctrl = i_id_ex.ex_rs2_ctrl;
assign w_mem_rs1_ctrl = i_id_ex.mem_rs1_ctrl;
assign w_mem_rs2_ctrl = i_id_ex.mem_rs2_ctrl;

//outputs to decode for forwarding
assign o_ex_rd = i_id_ex.rd;
assign o_ex_wenable = i_id_ex.wenable; 
assign o_ex_memread = i_id_ex.mem_read;

riscv_ALUsrc ALUsrc_wiring (
.i_ALU_rs2(w_ALU_rs2), 
.i_immext(w_immext), 
.i_ALUsrc_ctrl(w_ALUsrc_ctrl), 
.o_ALUsrc(w_ALUsrc)
);

riscv_ALU ALU_wiring (
.i_ALU_rs1(w_ALU_rs1), 
.i_ALUsrc(w_ALUsrc), 
.i_ALUop(w_ALUop), 
.o_ALU(w_ALU),
.o_zero(w_zero)
);

riscv_brancheval brancheval_wiring (
.i_func3(w_func3), 
.i_zero(w_zero), 
.i_branch_ctrl(w_branch_ctrl), 
.o_dobranch(w_dobranch)
);

riscv_ALU_rs1 ALU_rs1_wiring (
.i_rs1_data(w_rs1_data), 
.i_mem_forward_data(i_mem_forward_data), 
.i_wb_forward_data(i_wb_forward_data), 
.i_ex_rs1_ctrl(w_ex_rs1_ctrl), 
.i_mem_rs1_ctrl(w_mem_rs1_ctrl), 
.o_ALU_rs1(w_ALU_rs1)
);

riscv_ALU_rs2 ALU_rs2_wiring (
.i_rs2_data(w_rs2_data), 
.i_mem_forward_data(i_mem_forward_data), 
.i_wb_forward_data(i_wb_forward_data), 
.i_ex_rs2_ctrl(w_ex_rs2_ctrl), 
.i_mem_rs2_ctrl(w_mem_rs2_ctrl), 
.o_ALU_rs2(w_ALU_rs2)
);

`ifdef RVFI 
assign o_ex_mem_next.valid_instruct = i_id_ex.valid_instruct;
assign o_ex_mem_next.pc = i_id_ex.pc;
assign o_ex_mem_next.instruct = i_id_ex.instruct;
`endif

endmodule

