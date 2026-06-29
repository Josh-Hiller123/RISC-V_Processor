module riscv_regfile #(
parameter REG_DATAWIDTH = 32; //DO NOT OVERRIDE
parameter DATA_WIDTH = 8; //DO NOT OVERRIDE
parameter INSTRUCT_WIDTH = 32; // DO NOT OVERRIDE
)(
input logic i_clk,
input logic i_nrst,
input logic [INSTRUCT_WIDTH-1:0] i_instruct,
input logic [DATA_WIDTH-1:0] i_din,
input logic i_wenable, 

output logic [REG_DATAWIDTH-1:0] o_rs1_data, 
output logic [REG_DATAWIDTH-1:0] o_rs2_data
);

localparam REG_WIDTH = 5; 
localparam REG_ADDRWIDTH = 32; 

logic [REG_DATAWIDTH-1:0] reg_mem [REG_ADDRWIDTH-1:0]; 
logic [REG_WIDTH-1:0] rs1; 
logic [REG_WIDTH-1:0] rs2;
logic [REG_WIDTH-1:0] rd;

assign rs1 = i_instruct[19:15]; 
assign rs2 = i_instruct[24:20];
assign rd = i_instruct[11:7];

assign o_rs1_data = reg_mem[rs1];
assign o_rs2_data = reg_mem[rs2];

endmodule