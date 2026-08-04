interface tb_tasks #(
parameter MAIN_MEM_WIDTH = 14, //PARAMETER MUST MATCH TOP, questa throws error if they don't
parameter WORD_BITS = 2, 
parameter PC_INITIAL = 32'h8000_0000, // start for spike so lockstep matches up
parameter REG_DATAWIDTH = 32,

parameter BLOCK_WIDTH = (1 << WORD_BITS) * REG_DATAWIDTH,            
parameter MAIN_MEM_ENTRIES   = (1 << (MAIN_MEM_WIDTH-WORD_BITS-2))
)(
ref logic [BLOCK_WIDTH-1:0] main_mem_tb [MAIN_MEM_ENTRIES-1:0]
); 

logic [REG_DATAWIDTH-1:0] instruct_init_addr_tb; 
logic [WORD_BITS-1:0] instruct_init_word_tb;
logic [REG_DATAWIDTH-1:0] instruct_init_tb; 

task clear_mem();
int i; 
for(i = 0; i <= MAIN_MEM_ENTRIES-1; i++)
main_mem_tb[i] = '0; 
$display("Memory was cleared");
endtask 

task check_pc_initial();
instruct_init_addr_tb = PC_INITIAL[MAIN_MEM_WIDTH-1:WORD_BITS+2]; 
instruct_init_word_tb = PC_INITIAL[WORD_BITS+1:2]; 
instruct_init_tb = main_mem_tb[instruct_init_addr_tb][instruct_init_word_tb*REG_DATAWIDTH+:REG_DATAWIDTH];
$display("The first instruction was read as 0x%h", instruct_init_tb); 
endtask

task load_instructions(input string program_path);
clear_mem(); 
$readmemh(program_path, main_mem_tb, PC_INITIAL[MAIN_MEM_WIDTH-1:WORD_BITS+2], MAIN_MEM_ENTRIES-1); 
endtask
endinterface