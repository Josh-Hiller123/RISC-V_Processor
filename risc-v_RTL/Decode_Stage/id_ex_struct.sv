package id_ex_struct;

localparam PC_WIDTH = 32;
localparam MEM_FORWARD_CTRL = 2;
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
logic [MEM_FORWARD_CTRL-1:0] mem_forward_ctrl; 

logic [REG_DATAWIDTH-1:0] rs1_data; 
logic [REG_DATAWIDTH-1:0] rs2_data; 

logic [IMM_WIDTH-1:0] immext;

logic [PC_WIDTH-1:0] jump_target;
logic jalr_ctrl;

logic [REG_WIDTH-1:0] rd; 
logic [FUNC3-1:0] func3; 

logic [ALU_OP-1:0] ALUop;

logic fencei;

logic ex_rs1_ctrl;
logic ex_rs2_ctrl;
logic mem_rs1_ctrl;
logic mem_rs2_ctrl;

`ifdef RVFI 
    logic valid_instruct;
    logic [PC_WIDTH-1:0] pc; 
    logic [REG_DATAWIDTH-1:0] instruct; 
`endif

} id_ex_t; 
endpackage
