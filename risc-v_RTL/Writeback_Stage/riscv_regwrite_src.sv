module riscv_regwrite_src #(
parameter REG_DATAWIDTH = 32
)(
input logic i_memread,
input logic [REG_DATAWIDTH-1:0] i_mem_forward, 
input logic [REG_DATAWIDTH-1:0] i_dmem_clean, 

output logic [REG_DATAWIDTH-1:0] o_rd_data
);

localparam CHOOSE_MEM_FORWARD = 1'b0; 
localparam CHOOSE_DMEM = 1'b1; 

always_comb
begin 
case(i_memread)
CHOOSE_MEM_FORWARD: o_rd_data = i_mem_forward;
CHOOSE_DMEM: o_rd_data = i_dmem_clean;
default: o_rd_data = 'x;
endcase
end

endmodule
