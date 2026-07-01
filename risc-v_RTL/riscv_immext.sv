module riscv_immext #(
parameter INSTRUCT_WIDTH = 32, 
parameter IMMEXT_CTRL = 3
)(
input logic [INSTRUCT_WIDTH-1:0] i_instruct, 
input logic [IMMEXT_CTRL-1:0] i_immext_ctrl,
output logic [INSTRUCT_WIDTH-1:0] o_immext
); 

localparam I_TYPE = 3'b000;
localparam S_TYPE = 3'b001;
localparam B_TYPE = 3'b010;
localparam U_TYPE = 3'b011;
localparam J_TYPE = 3'b100;

always_comb
begin
    case(i_immext_ctrl)
        I_TYPE: o_immext = {{20{i_instruct[31]}}, i_instruct[31:20]};
        S_TYPE: o_immext = {{20{i_instruct[31]}}, i_instruct[31:25], i_instruct[11:7]};
        B_TYPE: o_immext = {{19{i_instruct[31]}}, i_instruct[31], i_instruct[7], i_instruct[30:25], i_instruct[11:8], 1'b0};
        U_TYPE: o_immext = {i_instruct[31:12], 12'b000000000000};
        J_TYPE: o_immext = {{11{i_instruct[31]}}, i_instruct[31], i_instruct[19:12], i_instruct[20], i_instruct[30:21], 1'b0};
        default: o_immext = 'x; 
    endcase
end
endmodule