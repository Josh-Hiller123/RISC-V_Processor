package mem_wb_struct;

localparam REG_WIDTH = 5;
localparam REG_DATAWIDTH = 32;

typedef struct packed {

logic wenable; 
logic [REG_WIDTH-1:0] rd; 

logic [REG_DATAWIDTH-1:0] rd_data;

} mem_wb_t;
endpackage
