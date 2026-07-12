module riscv_dmem #(
parameter DMEM_ADDR_WIDTH = 16, // SAME AS PC FOR IMPLEMENTING SIMULATION FLAGS, if ALU bits write to out of range address 
parameter DATA_WIDTH = 32, 
parameter FUNC3 = 3
)(
input logic i_clk,
input logic i_mem_write, 
input logic i_mem_read, 
input logic [DATA_WIDTH-1:0] i_ALU, 
input logic [DATA_WIDTH-1:0] i_rs2_data,
input logic [FUNC3-1:0] i_func3,

output logic [DATA_WIDTH-1:0] o_dmem_data
);

//MEM PARAMS
localparam CHOOSE_WRITE = 2'b01; 
localparam CHOOSE_READ = 2'b10;

// FUNC3 PARAMS
localparam CHOOSE_SB = 3'b000;
localparam CHOOSE_SH = 3'b001;
localparam CHOOSE_SW = 3'b010;

//SB PARAMS
localparam CHOOSE_BYTE0 = 2'b00; 
localparam CHOOSE_BYTE1 = 2'b01; 
localparam CHOOSE_BYTE2 = 2'b10; 
localparam CHOOSE_BYTE3 = 2'b11; 

//SH PARAMS 
localparam CHOOSE_HALF0 = 1'b0;
localparam CHOOSE_HALF1 = 1'b1;

logic [DATA_WIDTH-1:0] d_mem [(1 << DMEM_ADDR_WIDTH-2)-1:0];

always_ff @(posedge i_clk) 
begin
case({i_mem_read, i_mem_write})
CHOOSE_WRITE:
    case(i_func3)
    CHOOSE_SB: 
        case(i_ALU[1:0])
        CHOOSE_BYTE0: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][7:0] <= i_rs2_data[7:0]; 
        CHOOSE_BYTE1: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][15:8] <= i_rs2_data[7:0]; 
        CHOOSE_BYTE2: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][23:16] <= i_rs2_data[7:0]; 
        CHOOSE_BYTE3: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][31:24] <= i_rs2_data[7:0];
        default: ;
        endcase
    CHOOSE_SH:
        case(i_ALU[1])
        CHOOSE_HALF0: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][15:0] <= i_rs2_data[15:0]; 
        CHOOSE_HALF1: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][31:16] <= i_rs2_data[15:0];
        default: ;
        endcase
    CHOOSE_SW: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]] <= i_rs2_data;
    default: ;
    endcase
CHOOSE_READ: o_dmem_data <= d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]];
default: ;
endcase
end 
endmodule
