import if_id_struct::*;
import id_ex_struct::*;
module riscv_decode_stage(
input if_id_t i_if_id, 

output id_ex_t o_id_ex_next,
output logic [JUMPS_CTRL-1:0] o_jumps_ctrl,
output logic [PC_WIDTH-1:0] o_jump_target
);

localparam INSTRUCT_WIDTH = 32; 
localparam PC_WIDTH = 32; 
localparam REG_DATAWIDTH = 32;
localparam IMM_WIDTH = 32;

localparam ALU_CU_CTRL = 2;
localparam IMMEXT_CTRL = 3;
localparam JUMPS_CTRL = 2;
localparam REGWRITE_MUX_CTRL = 3;

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
logic [JUMPS_CTRL-1:0] w_jumps_ctrl;
logic w_wenable;
logic [REGWRITE_MUX_CTRL-1:0] w_regwrite_mux_ctrl; 
logic w_lui_jump_target;

logic [REG_DATAWIDTH-1:0] w_rs1_data; 
logic [REG_DATAWIDTH-1:0] w_rs2_data;

logic [IMM_WIDTH-1:0] w_immext;

logic [PC_WIDTH-1:0] w_jump_target;

logic [FUNC3-1:0] w_func3; 
logic [FUNC7-1:0] w_func7; 

logic [ALU_OP-1:0] w_ALUop;

//jumps output ports, connect via top module
assign o_jumps_ctrl = w_jumps_ctrl; 
assign o_jump_target = w_jump_target;

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
assign o_id_ex_next.regwrite_mux_ctrl = w_regwrite_mux_ctrl;

//regfile_wiring connection wires
assign o_id_ex_next.rs1_data = w_rs1_data; 
assign o_id_ex_next.rs2_data = w_rs2_data; 

//immext_wiring connection wire 
assign o_id_ex_next.immext = w_immext;

//jump_target_wiring connection wire
assign o_id_ex_next.jump_target = w_jump_target;


riscv_decoder decoder_wiring (
.i_instruct(w_instruct),
.o_ALUcu_ctrl(w_ALUcu_ctrl), 
.o_ALUsrc_ctrl(w_ALUsrc_ctrl), 
.o_branch_ctrl(w_branch_ctrl), 
.o_immext_ctrl(w_immext_ctrl),
.o_jumps_ctrl(w_jumps_ctrl),
.o_mem_write(w_mem_write), 
.o_mem_read(w_mem_read), 
.o_wenable(w_wenable), 
.o_regwrite_mux_ctrl(w_regwrite_mux_ctrl), 
.o_lui_jump_target(w_lui_jump_target)
); 

riscv_regfile regfile_wiring (
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
.i_rs1_data(w_rs1_data), 
.i_jumps_ctrl(w_jumps_ctrl), 
.i_lui_jump_target(w_lui_jump_target),
.o_jump_target(w_jump_target)
);

riscv_ALU_cu ALU_cu_wiring (
.i_ALUcu_ctrl(w_ALUcu_ctrl), 
.i_func3(w_func3),
.i_func7(w_func7), 
.o_ALUop(w_ALUop)
);

endmodule

