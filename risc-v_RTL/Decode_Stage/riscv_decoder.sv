module riscv_decoder #(
parameter INSTRUCT_WIDTH = 32, 
parameter OPCODE_WIDTH = 7,
parameter ALU_CU_CTRL = 2,
parameter IMMEXT_CTRL = 3, 
parameter JUMPS_CTRL = 2, 
parameter REGWRITE_MUX_CTRL = 3

) (
input logic [INSTRUCT_WIDTH-1:0] i_instruct, 

output logic [ALU_CU_CTRL-1:0] o_ALUcu_ctrl,               // to ALU_cu
output logic o_ALUsrc_ctrl,                                // to ALUsrc
output logic o_branch_ctrl,                                // to brancheval
output logic o_mem_write,                                  // to dmem
output logic o_mem_read,                                   // to dmem
output logic [IMMEXT_CTRL-1:0] o_immext_ctrl,              // to immext
output logic [JUMPS_CTRL-1:0] o_jumps_ctrl,                // to pc
output logic o_wenable,                                    // to regfile
output logic [REGWRITE_MUX_CTRL-1:0] o_regwrite_mux_ctrl,  // to regwrite_src
output logic o_lui_jump_target                             // to jump_target, special signal
);

//OPCODE PARAMS
localparam CHOOSE_RTYPE = 7'b0110011; 
localparam CHOOSE_ITYPE_ALU = 7'b0010011; 
localparam CHOOSE_LOAD = 7'b0000011; 
localparam CHOOSE_STORE = 7'b0100011; 
localparam CHOOSE_BRANCH = 7'b1100011; 
localparam CHOOSE_JAL = 7'b1101111; 
localparam CHOOSE_JALR = 7'b1100111; 
localparam CHOOSE_LUI = 7'b0110111; 
localparam CHOOSE_AUIPC = 7'b0010111;

logic [OPCODE_WIDTH-1:0] w_opcode;
assign w_opcode = i_instruct[OPCODE_WIDTH-1:0]; 

always_comb
begin
o_ALUcu_ctrl = 'x;
o_ALUsrc_ctrl = 'x;
o_branch_ctrl = '0;
o_mem_write = '0;
o_mem_read = '0;
o_immext_ctrl = 'x;
o_jumps_ctrl = '0;
o_wenable = '0;
o_regwrite_mux_ctrl = 'x;
o_lui_jump_target = 0;

case (w_opcode)
CHOOSE_RTYPE: 
begin
    o_ALUcu_ctrl = 2'b01;
    o_ALUsrc_ctrl = 1'b0; 
    o_branch_ctrl = 1'b0; // changed jalr alu ctrl signals, make sure theres no bugs after removing designated rs1 + immext adder
    o_mem_write = 1'b0;
    o_mem_read = 1'b0;
    o_immext_ctrl = 'x;
    o_jumps_ctrl = 2'b00;
    o_wenable = 1'b1;
    o_regwrite_mux_ctrl = 3'b000; 
end
CHOOSE_ITYPE_ALU: 
begin
    o_ALUcu_ctrl = 2'b11;
    o_ALUsrc_ctrl = 1'b1; 
    o_branch_ctrl = 1'b0;
    o_mem_write = 1'b0;
    o_mem_read = 1'b0;
    o_immext_ctrl = 3'b000;
    o_jumps_ctrl = 2'b00;
    o_wenable = 1'b1;
    o_regwrite_mux_ctrl = 3'b000; 
end
CHOOSE_LOAD: 
begin
    o_ALUcu_ctrl = 2'b00;
    o_ALUsrc_ctrl = 1'b1;
    o_branch_ctrl = 1'b0;
    o_mem_write = 1'b0;
    o_mem_read = 1'b1;
    o_immext_ctrl = 3'b000;
    o_jumps_ctrl = 2'b00;
    o_wenable = 1'b1;
    o_regwrite_mux_ctrl = 3'b001;
end
CHOOSE_STORE: 
begin
    o_ALUcu_ctrl = 2'b00;
    o_ALUsrc_ctrl = 1'b1;
    o_branch_ctrl = 1'b0;
    o_mem_write = 1'b1;
    o_mem_read = 1'b0;
    o_immext_ctrl = 3'b001;
    o_jumps_ctrl = 2'b00;
    o_wenable = 1'b0;
    o_regwrite_mux_ctrl = 'x;
end
CHOOSE_BRANCH: 
begin
    o_ALUcu_ctrl = 2'b10;
    o_ALUsrc_ctrl = 1'b0; 
    o_branch_ctrl = 1'b1;
    o_mem_write = 1'b0;
    o_mem_read = 1'b0;
    o_immext_ctrl = 3'b010;
    o_jumps_ctrl = 2'b00;
    o_wenable = 1'b0;
    o_regwrite_mux_ctrl = 'x;
end
CHOOSE_JAL: 
begin
    o_ALUcu_ctrl = 'x;
    o_ALUsrc_ctrl = 'x;
    o_branch_ctrl = 1'b0;
    o_mem_write = 1'b0;
    o_mem_read = 1'b0;
    o_immext_ctrl = 3'b100;
    o_jumps_ctrl = 2'b01;
    o_wenable = 1'b1;
    o_regwrite_mux_ctrl = 3'b100;
end
CHOOSE_JALR: 
begin
    o_ALUcu_ctrl = 'x;
    o_ALUsrc_ctrl = 'x;
    o_branch_ctrl = 1'b0;
    o_mem_write = 1'b0;
    o_mem_read = 1'b0;
    o_immext_ctrl = 3'b000;
    o_jumps_ctrl = 2'b10;
    o_wenable = 1'b1;
    o_regwrite_mux_ctrl = 3'b100;
end
CHOOSE_LUI: 
begin
    o_ALUcu_ctrl = 'x;
    o_ALUsrc_ctrl = 'x;
    o_branch_ctrl = 1'b0;
    o_mem_write = 1'b0;
    o_mem_read = 1'b0;
    o_immext_ctrl = 3'b011;
    o_jumps_ctrl = 2'b00;
    o_wenable = 1'b1;
    o_regwrite_mux_ctrl = 3'b010;
    o_lui_jump_target = 1;
end
CHOOSE_AUIPC: 
begin
    o_ALUcu_ctrl = 'x;
    o_ALUsrc_ctrl = 'x;
    o_branch_ctrl = 1'b0;
    o_mem_write = 1'b0;
    o_mem_read = 1'b0;
    o_immext_ctrl = 3'b011;
    o_jumps_ctrl = 2'b00;
    o_wenable = 1'b1;
    o_regwrite_mux_ctrl = 3'b010;
end
endcase
end
endmodule
