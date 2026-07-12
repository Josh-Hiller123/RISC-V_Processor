module riscv_jump_target #(
parameter PC_WIDTH = 32, 
parameter IMM_WIDTH = 32
)(
input logic [PC_WIDTH-1:0] i_pc, 
input logic [IMM_WIDTH-1:0] i_immext, 
input logic i_lui,

output logic [PC_WIDTH-1:0] o_jump_target
); 

localparam LUI = 1'b1;

logic [PC_WIDTH-1:0] w_adder_src1; 

always_comb 
begin 
    case(i_lui)
    LUI: w_adder_src1 = 0; 
    default: w_adder_src1 = i_pc;
    endcase
end

assign o_jump_target = i_immext + w_adder_src1; 

endmodule
