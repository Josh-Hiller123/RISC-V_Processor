module riscv_load_ext #(
parameter DATA_WIDTH = 32, 
parameter FUNC3 = 3
)(
input logic [DATA_WIDTH-1:0] i_dmem_raw, 
input logic [FUNC3-1:0] i_func3, 
input logic [DATA_WIDTH-1:0] i_ALU, 

output logic [DATA_WIDTH-1:0] o_dmem_clean
);

// FUNC3 PARAMS
localparam CHOOSE_LB = 2'b00;
localparam CHOOSE_LH = 2'b01;
localparam CHOOSE_LW = 2'b10; 

//LB PARAMS
localparam CHOOSE_BYTE0 = 2'b00; 
localparam CHOOSE_BYTE1 = 2'b01; 
localparam CHOOSE_BYTE2 = 2'b10; 
localparam CHOOSE_BYTE3 = 2'b11; 

//LH PARAMS 
localparam CHOOSE_HALF0 = 1'b0;
localparam CHOOSE_HALF1 = 1'b1;

//SIGN PARAMS
localparam CHOOSE_SIGNED = 1'b0;
localparam CHOOSE_UNSIGNED = 1'b1;

logic [7:0] byte_loaded;
logic [15:0] half_loaded;

logic zero_extend;

assign zero_extend = i_func3[FUNC3-1];

always_comb 
begin
    byte_loaded = 'x; 
    half_loaded = 'x; 
    o_dmem_clean = 'x;
case(i_func3[FUNC3-2:0])
    CHOOSE_LB:
    begin
        case(i_ALU[1:0])
        CHOOSE_BYTE0: byte_loaded[7:0] = i_dmem_raw[7:0];
        CHOOSE_BYTE1: byte_loaded[7:0] = i_dmem_raw[15:8]; 
        CHOOSE_BYTE2: byte_loaded[7:0] = i_dmem_raw[23:16]; 
        CHOOSE_BYTE3: byte_loaded[7:0] = i_dmem_raw[31:24];
        endcase
        case(zero_extend)
        CHOOSE_SIGNED: o_dmem_clean = {{24{byte_loaded[7]}}, byte_loaded[7:0]}; 
        CHOOSE_UNSIGNED: o_dmem_clean = {{24{1'b0}}, byte_loaded[7:0]};
        endcase
    end
    CHOOSE_LH:
    begin
        case(i_ALU[1])
        CHOOSE_HALF0: half_loaded[15:0] = i_dmem_raw[15:0]; 
        CHOOSE_HALF1: half_loaded[15:0] = i_dmem_raw[31:16];
        endcase
        case(zero_extend)
        CHOOSE_SIGNED: o_dmem_clean = {{16{half_loaded[15]}}, half_loaded[15:0]}; 
        CHOOSE_UNSIGNED: o_dmem_clean = {{16{1'b0}}, half_loaded[15:0]};
        endcase
    end
    CHOOSE_LW: o_dmem_clean = i_dmem_raw;
    default: ;
    endcase
end
endmodule