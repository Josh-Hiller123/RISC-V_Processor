import if_id_struct::*;
module fetch_stage (
output if_id_t o_if_id_next
);

localparam PC_WIDTH = 32; 
localparam INSTRUCT_WIDTH = 32;

logic [PC_WIDTH-1:0] w_pc; 
logic [PC_WIDTH-1:0] w_pc_add_four; 
logic [INSTRUCT_WIDTH-1:0] w_instruct;

assign o_if_id_next.pc = w_pc;
assign o_if_id_next.pc_add_four = w_pc_add_four;
assign o_if_id_next.instruct = w_instruct;

riscv_pc #(.PC_WIDTH(PC_WIDTH)) pc_wiring (
.o_pc(w_pc), 
.o_pc_add_four(w_pc_add_four)
);

riscv_imem #(.INSTRUCT_WIDTH(INSTRUCT_WIDTH)) imem_wiring (
.i_pc(w_pc), 
.o_instruct(w_instruct)
);
endmodule



