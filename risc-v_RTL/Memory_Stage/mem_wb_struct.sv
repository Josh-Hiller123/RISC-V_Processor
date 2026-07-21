package mem_wb_struct;

localparam REG_WIDTH = 5;
localparam REG_DATAWIDTH = 32;

typedef struct packed {

logic wenable; 
logic [REG_WIDTH-1:0] rd; 
logic [REG_DATAWIDTH-1:0] mem_forward;
logic [REG_DATAWIDTH-1:0] dmem_clean;
logic mem_read;

} mem_wb_t;
endpackage
