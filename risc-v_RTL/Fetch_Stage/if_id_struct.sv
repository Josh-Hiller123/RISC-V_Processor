package if_id_struct;

localparam PC_WIDTH = 32;
localparam INSTRUCT_WIDTH = 32;

typedef struct packed {

logic [PC_WIDTH-1:0] pc_add_four;
logic [PC_WIDTH-1:0] pc;
logic [INSTRUCT_WIDTH-1:0] instruct;

`ifdef RVFI 
    logic valid_instruct;
`endif

} if_id_t;
endpackage
