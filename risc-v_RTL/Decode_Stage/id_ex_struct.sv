package id_ex_struct;

localparam PC_WIDTH = 32;
localparam JUMPS_CTRL = 2;
localparam REGWRITE_MUX_CTRL = 3;
localparam REG_DATAWIDTH = 32;
localparam IMM_WIDTH = 32;
localparam FUNC3 = 3; 
localparam REG_WIDTH = 5;
localparam ALU_OP = 4;


typedef struct packed {

logic [PC_WIDTH-1:0] pc_add_four; 

logic ALUsrc_ctrl;
logic branch_ctrl;
logic mem_write;
logic mem_read; 
logic wenable;
logic [REGWRITE_MUX_CTRL-1:0] regwrite_mux_ctrl; 

logic [REG_DATAWIDTH-1:0] rs1_data; 
logic [REG_DATAWIDTH-1:0] rs2_data; 

logic [IMM_WIDTH-1:0] immext;

logic [PC_WIDTH-1:0] jump_target;

logic [REG_WIDTH-1:0] rd; 
logic [FUNC3-1:0] func3; 

logic [ALU_OP-1:0] ALUop;

} id_ex_t; 
endpackage
