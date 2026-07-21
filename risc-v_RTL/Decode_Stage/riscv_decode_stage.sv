import if_id_struct::*;
import id_ex_struct::*;
module riscv_decode_stage#(
parameter REG_DATAWIDTH = 32, 
parameter REG_WIDTH = 5, 
parameter PC_WIDTH = 32
)(
input logic i_clk,
input if_id_t i_if_id, 

//WB to regfile inputs
input logic [REG_DATAWIDTH-1:0] i_wb_rd_data,
input logic i_wb_wenable,
input logic [REG_WIDTH-1:0] i_wb_rd,

//External inputs for forwarding
input logic [REG_WIDTH-1:0] i_ex_rd,
input logic i_ex_wenable,
input logic [REG_WIDTH-1:0] i_mem_rd, 
input logic i_mem_wenable, 
input logic i_ex_memread,


output id_ex_t o_id_ex_next, 
output logic o_jal_ctrl, 
output logic o_jalr_ctrl,
output logic [PC_WIDTH-1:0] o_jump_target, 
output logic o_forward_load

);

localparam INSTRUCT_WIDTH = 32; 
localparam IMM_WIDTH = 32;

localparam ALU_CU_CTRL = 2;
localparam IMMEXT_CTRL = 3;
localparam MEM_FORWARD_CTRL = 2;

localparam FUNC3 = 3; 
localparam FUNC7 = 7; 
localparam ALU_OP = 4;

logic [PC_WIDTH-1:0] w_pc;

logic [INSTRUCT_WIDTH-1:0] w_instruct;
logic [ALU_CU_CTRL-1:0] w_ALUcu_ctrl; 
logic w_ALUsrc_ctrl;
logic w_branch_ctrl;
logic w_mem_write;
logic w_mem_read; 
logic [IMMEXT_CTRL-1:0] w_immext_ctrl;
logic w_jal_ctrl;
logic w_jalr_ctrl;
logic w_wenable;
logic [MEM_FORWARD_CTRL-1:0] w_mem_forward_ctrl; 
logic w_lui;

logic [REG_DATAWIDTH-1:0] w_rs1_data; 
logic [REG_DATAWIDTH-1:0] w_rs2_data;

logic [IMM_WIDTH-1:0] w_immext;

logic [PC_WIDTH-1:0] w_jump_target;

logic [FUNC3-1:0] w_func3; 
logic [FUNC7-1:0] w_func7; 

logic [ALU_OP-1:0] w_ALUop;

logic w_fencei;

logic w_ex_rs1_ctrl;
logic w_ex_rs2_ctrl;
logic w_mem_rs1_ctrl; 
logic w_mem_rs2_ctrl; 

//jumps output ports, connect via top module
assign o_jal_ctrl = w_jal_ctrl; 
assign o_jalr_ctrl = w_jalr_ctrl;
assign o_jump_target = w_jump_target;
assign o_id_ex_next.jalr_ctrl = w_jalr_ctrl;

//pc connection wires 
assign w_pc = i_if_id.pc; 

// func3 and func7 connection wires
assign w_func3 = i_if_id.instruct[14:12]; 
assign w_func7 = i_if_id.instruct[31:25];

// ALUcu connection wire
assign o_id_ex_next.ALUop = w_ALUop;

//instruct connection wires 
assign o_id_ex_next.rd = i_if_id.instruct[11:7]; 
assign o_id_ex_next.func3 = w_func3; 

//decoder_wiring connection wires
assign w_instruct = i_if_id.instruct;
assign o_id_ex_next.pc_add_four = i_if_id.pc_add_four;
assign o_id_ex_next.ALUsrc_ctrl = w_ALUsrc_ctrl;
assign o_id_ex_next.branch_ctrl = w_branch_ctrl;
assign o_id_ex_next.mem_write = w_mem_write; 
assign o_id_ex_next.mem_read = w_mem_read; 
assign o_id_ex_next.wenable = w_wenable;
assign o_id_ex_next.mem_forward_ctrl = w_mem_forward_ctrl;
assign o_id_ex_next.fencei = w_fencei;

//regfile_wiring connection wires
assign o_id_ex_next.rs1_data = w_rs1_data; 
assign o_id_ex_next.rs2_data = w_rs2_data; 

//immext_wiring connection wire 
assign o_id_ex_next.immext = w_immext;

//jump_target_wiring connection wire
assign o_id_ex_next.jump_target = w_jump_target;

//Forwarding --> ALUsrc wiring (ctrl signals for muxes)
assign o_id_ex_next.ex_rs1_ctrl = w_ex_rs1_ctrl;
assign o_id_ex_next.ex_rs2_ctrl = w_ex_rs2_ctrl;
assign o_id_ex_next.mem_rs1_ctrl = w_mem_rs1_ctrl;
assign o_id_ex_next.mem_rs2_ctrl = w_mem_rs2_ctrl;


riscv_decoder decoder_wiring (
.i_instruct(w_instruct),
.o_ALUcu_ctrl(w_ALUcu_ctrl), 
.o_ALUsrc_ctrl(w_ALUsrc_ctrl), 
.o_branch_ctrl(w_branch_ctrl), 
.o_immext_ctrl(w_immext_ctrl),
.o_jal_ctrl(w_jal_ctrl),
.o_jalr_ctrl(w_jalr_ctrl),
.o_mem_write(w_mem_write), 
.o_mem_read(w_mem_read), 
.o_wenable(w_wenable), 
.o_mem_forward_ctrl(w_mem_forward_ctrl), 
.o_fencei(w_fencei),
.o_lui(w_lui)
); 

riscv_regfile regfile_wiring (
.i_clk(i_clk),
.i_din(i_wb_rd_data),
.i_rd(i_wb_rd),
.i_wenable(i_wb_wenable),
.i_instruct(w_instruct), 
.o_rs1_data(w_rs1_data), 
.o_rs2_data(w_rs2_data)
);

riscv_immext immext_wiring (
.i_instruct(w_instruct), 
.i_immext_ctrl(w_immext_ctrl), 
.o_immext(w_immext)
);

riscv_jump_target jump_target_wiring (
.i_pc(w_pc), 
.i_immext(w_immext),  
.i_lui(w_lui),
.o_jump_target(w_jump_target)
);

riscv_ALU_cu ALU_cu_wiring (
.i_ALUcu_ctrl(w_ALUcu_ctrl), 
.i_func3(w_func3),
.i_func7(w_func7), 
.o_ALUop(w_ALUop)
);

riscv_forwarding forwarding_wiring (
.i_ex_rd(i_ex_rd), 
.i_ex_wenable(i_ex_wenable), 
.i_mem_rd(i_mem_rd), 
.i_mem_wenable(i_mem_wenable), 
.i_id_instruct(w_instruct),
.i_ex_memread(i_ex_memread), 
.o_ex_rs1_ctrl(w_ex_rs1_ctrl), 
.o_ex_rs2_ctrl(w_ex_rs2_ctrl), 
.o_mem_rs1_ctrl(w_mem_rs1_ctrl), 
.o_mem_rs2_ctrl(w_mem_rs2_ctrl), 
.o_forward_load(o_forward_load)

);


endmodule

