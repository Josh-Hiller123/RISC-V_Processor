module riscv_jump_target #(
parameter PC_WIDTH = 32, 
parameter IMM_WIDTH = 32,
parameter REG_DATAWIDTH = 32, 
parameter JUMPS_CTRL = 2
)(
input logic [PC_WIDTH-1:0] i_pc, 
input logic [IMM_WIDTH-1:0] i_immext, 
input logic [REG_DATAWIDTH-1:0] i_rs1_data,
input logic [JUMPS_CTRL-1:0] i_jumps_ctrl,
input logic i_lui_jump_target,

output logic [PC_WIDTH-1:0] o_jump_target
); 
 
localparam JALR = 3'b100;
localparam LUI = 3'b001;

logic [PC_WIDTH-1:0] w_adder_src1; 

always_comb 
begin 
    case({i_jumps_ctrl, i_lui_jump_target})
    JALR: w_adder_src1 = i_rs1_data;
    LUI: w_adder_src1 = 0; 
    default: w_adder_src1 = i_pc;
    endcase
end

assign o_jump_target = i_immext + w_adder_src1; 

endmodule
