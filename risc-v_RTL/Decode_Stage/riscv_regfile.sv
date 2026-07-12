module riscv_regfile #(
parameter REG_DATAWIDTH = 32, 
parameter DATA_WIDTH = 32,
parameter INSTRUCT_WIDTH = 32, 
parameter REG_WIDTH = 5
)(
input logic i_clk, 
input logic [INSTRUCT_WIDTH-1:0] i_instruct,
input logic [DATA_WIDTH-1:0] i_din,
input logic i_wenable, 
input logic [REG_WIDTH-1:0] i_rd,

output logic [REG_DATAWIDTH-1:0] o_rs1_data, 
output logic [REG_DATAWIDTH-1:0] o_rs2_data
);

localparam REG_ENTRIES = 32; 

logic [REG_DATAWIDTH-1:0] reg_mem [REG_ENTRIES-1:0]; 
logic [REG_WIDTH-1:0] rs1; 
logic [REG_WIDTH-1:0] rs2;

assign rs1 = i_instruct[19:15]; 
assign rs2 = i_instruct[24:20];

always_comb 
begin
    o_rs1_data = (rs1 == 0) ? '0 : reg_mem[rs1];
    o_rs2_data = (rs2 == 0) ? '0 : reg_mem[rs2];
end

always_ff @(negedge i_clk)
begin
if(i_wenable == 1 & i_rd != '0)
reg_mem[i_rd] <= i_din; 
end

endmodule
