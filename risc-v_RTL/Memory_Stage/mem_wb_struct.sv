package mem_wb_struct;

localparam REG_WIDTH = 5;
localparam REG_DATAWIDTH = 32;

typedef struct packed {

logic wenable; 
logic [REG_WIDTH-1:0] rd; 
logic [REG_DATAWIDTH-1:0] mem_forward;
logic [REG_DATAWIDTH-1:0] dmem_clean;
logic mem_read;

`ifdef RVFI 
    logic valid_instruct;
    logic [REG_DATAWIDTH-1:0] pc; 
    logic [REG_DATAWIDTH-1:0] instruct; 

    logic [31:0] alu; 
    logic [2:0] func3; 
    logic [REG_DATAWIDTH-1:0] rs2_data; 
    logic mem_write; 
`endif

} mem_wb_t;
endpackage
