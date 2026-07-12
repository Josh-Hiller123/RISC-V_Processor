package ex_mem_struct;
localparam PC_WIDTH = 32;
localparam REGWRITE_MUX_CTRL = 3;
localparam REG_DATAWIDTH = 32;
localparam REG_WIDTH = 5;
localparam FUNC3 = 3; 
localparam ALU_OUT = 32;

typedef struct packed {

logic [PC_WIDTH-1:0] pc_add_four;
logic mem_write; 
logic mem_read; 
logic wenable; 
logic [REGWRITE_MUX_CTRL-1:0] regwrite_mux_ctrl; 
logic [REG_DATAWIDTH-1:0] rs2_data; 
logic [REG_WIDTH-1:0] rd; 
logic [FUNC3-1:0] func3; 
logic [PC_WIDTH-1:0] jump_target;

logic [ALU_OUT-1:0] ALU; 

} ex_mem_t;

endpackage