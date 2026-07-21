module riscv_ALU #(
parameter ALU_SRC_WIDTH = 32,
parameter ALU_OUT = 32, 
parameter ALU_OP = 4
)(
input logic [ALU_SRC_WIDTH-1:0] i_ALU_rs1, 
input logic [ALU_SRC_WIDTH-1:0] i_ALUsrc, 
input logic [ALU_OP-1:0] i_ALUop, 

output logic [ALU_OUT-1:0] o_ALU, 
output logic o_zero
);

logic [4:0] shift_amt;

assign shift_amt = i_ALUsrc[4:0];
assign o_zero = (o_ALU == 0); 

always_comb
begin
case(i_ALUop)
4'b0000: o_ALU = i_ALU_rs1 + i_ALUsrc; 
4'b0001: o_ALU = i_ALU_rs1 - i_ALUsrc;
4'b0010: o_ALU = i_ALU_rs1 ^ i_ALUsrc; 
4'b0011: o_ALU = i_ALU_rs1 | i_ALUsrc;
4'b0100: o_ALU = i_ALU_rs1 & i_ALUsrc; 
4'b0101: o_ALU = i_ALU_rs1 << shift_amt; 
4'b0110: o_ALU = i_ALU_rs1 >> shift_amt; 
4'b0111: o_ALU = $signed(i_ALU_rs1) >>> shift_amt; 
4'b1000: o_ALU = {{(ALU_SRC_WIDTH-1){1'b0}}, ($signed(i_ALU_rs1) < $signed(i_ALUsrc))};
4'b1001: o_ALU = {{(ALU_SRC_WIDTH-1){1'b0}}, (i_ALU_rs1 < i_ALUsrc)};
default: o_ALU = 'x;
endcase
end
endmodule