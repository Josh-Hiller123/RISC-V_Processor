import mem_wb_struct::*; 
module riscv_wb_stage #(
parameter REG_DATAWIDTH = 32,
parameter REG_WIDTH = 5
)(

`ifdef RVFI 
output logic o_valid_instruct, 
output logic [REG_DATAWIDTH-1:0] o_pc, 
output logic [REG_DATAWIDTH-1:0] o_instruct, 
output logic [REG_DATAWIDTH-1:0] o_alu,
output logic [2:0] o_func3, 
output logic [REG_DATAWIDTH-1:0] o_rs2_data, 
output logic o_mem_write, 
output logic [REG_DATAWIDTH-1:0] o_dmem_clean,
`endif

input mem_wb_t i_mem_wb, 

output logic [REG_DATAWIDTH-1:0] o_wb_rd_data, // to decode
output logic o_wb_wenable, // to decode 
output logic [REG_WIDTH-1:0] o_wb_rd // to decode

); 

logic w_memread; 
logic [REG_DATAWIDTH-1:0] w_mem_forward;
logic [REG_DATAWIDTH-1:0] w_dmem_clean;
logic [REG_DATAWIDTH-1:0] w_rd_data; 

//outputs to decode 
assign o_wb_rd_data = w_rd_data;
assign o_wb_wenable = i_mem_wb.wenable; 
assign o_wb_rd = i_mem_wb.rd; 

//regwrite_mux wiring connections 
assign w_memread = i_mem_wb.mem_read;
assign w_mem_forward = i_mem_wb.mem_forward; 
assign w_dmem_clean = i_mem_wb.dmem_clean;

riscv_regwrite_src regwrite_src_wiring (
.i_memread(w_memread), 
.i_mem_forward(w_mem_forward), 
.i_dmem_clean(w_dmem_clean), 
.o_rd_data(w_rd_data)
);

`ifdef RVFI 
assign o_valid_instruct = i_mem_wb.valid_instruct;
assign o_pc = i_mem_wb.pc;
assign o_instruct = i_mem_wb.instruct;
assign o_alu = i_mem_wb.alu;
assign o_func3 = i_mem_wb.func3;
assign o_rs2_data = i_mem_wb.rs2_data;
assign o_mem_write = i_mem_wb.mem_write;
assign o_dmem_clean = w_dmem_clean;

`endif



endmodule