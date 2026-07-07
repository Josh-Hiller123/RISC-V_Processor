module ALU_ctrl_unit #(
parameter ALU_CU_CTRL = 2, 
parameter FUNC3 = 3, 
parameter FUNC7 = 7, 
parameter ALU_OP = 4)(

input logic [ALU_CU_CTRL-1:0] i_ALUcu_ctrl, 
input logic [FUNC3-1:0] i_func3, 
input logic [FUNC7-1:0] i_func7,

output logic [ALU_OP-1:0] o_ALUop
);

//ALU_CU_CTRL PARAMETERS
localparam FORCE_ADD = 2'b00;
localparam BRANCH = 2'b10;
localparam FUNC3_CHECK_R = 2'b01;
localparam FUNC3_CHECK_I = 2'b11;

// o_ALUop PARAMETERS
localparam ADD = 4'b0000;
localparam SUB = 4'b0001;
localparam XOR = 4'b0010;
localparam OR = 4'b0011;
localparam AND = 4'b0100;
localparam SLL = 4'b0101;
localparam SRL = 4'b0110;
localparam SRA = 4'b0111;
localparam SLT = 4'b1000;
localparam SLTU = 4'b1001;


always_comb
begin
    o_ALUop = 'x;
    if(i_ALUcu_ctrl == FORCE_ADD)
    o_ALUop = ADD;
    else if(i_ALUcu_ctrl == BRANCH)
    begin
    case(i_func3)
        3'b000: o_ALUop = SUB;  
        3'b001: o_ALUop = SUB;  
        3'b100: o_ALUop = SLT;  
        3'b101: o_ALUop = SLT;  
        3'b110: o_ALUop = SLTU; 
        3'b111: o_ALUop = SLTU;
    endcase
    end
    else if(i_ALUcu_ctrl == FUNC3_CHECK_R || i_ALUcu_ctrl == FUNC3_CHECK_I)
    begin
    case (i_func3)
    3'b000: 
    begin 
        if(i_ALUcu_ctrl == FUNC3_CHECK_I)
            o_ALUop = ADD; 
                
        else if(i_ALUcu_ctrl == FUNC3_CHECK_R)
            begin
            case(i_func7)
                7'h00: o_ALUop = ADD;
                7'h20: o_ALUop = SUB; 
            endcase
            end
        end

    3'b100: o_ALUop = XOR; 
    3'b110: o_ALUop = OR;
    3'b111: o_ALUop = AND;
    3'b001: o_ALUop = SLL;
    
    3'b101:
    begin
        case(i_func7)
            7'h00: o_ALUop = SRL; 
            7'h20: o_ALUop = SRA;
        endcase
    end

    3'b010: o_ALUop = SLT; 
    3'b011: o_ALUop = SLTU;
    endcase
    end
end
endmodule

module riscv_ALU #(
parameter ALU_SRC_WIDTH = 32,
parameter ALU_OUT = 32, 
parameter ALU_OP = 4
)(
input logic [ALU_SRC_WIDTH-1:0] i_ALUsrcA, 
input logic [ALU_SRC_WIDTH-1:0] i_ALUsrcB, 
input logic [ALU_OP-1:0] i_ALUop, 

output logic [ALU_OUT-1:0] o_ALU, 
output logic o_zero
);

logic [4:0] shamt;

assign shamt = i_ALUsrcB[4:0];
assign o_zero = (o_ALU == 0); 

always_comb
begin
case(i_ALUop)
4'b0000: o_ALU = i_ALUsrcA + i_ALUsrcB; 
4'b0001: o_ALU = i_ALUsrcA - i_ALUsrcB;
4'b0010: o_ALU = i_ALUsrcA ^ i_ALUsrcB; 
4'b0011: o_ALU = i_ALUsrcA | i_ALUsrcB;
4'b0100: o_ALU = i_ALUsrcA & i_ALUsrcB; 
4'b0101: o_ALU = i_ALUsrcA << shamt; 
4'b0110: o_ALU = i_ALUsrcA >> shamt; 
4'b0111: o_ALU = $signed(i_ALUsrcA) >>> shamt; 
4'b1000: o_ALU = {{(ALU_SRC_WIDTH-1){1'b0}}, ($signed(i_ALUsrcA) < $signed(i_ALUsrcB))};
4'b1001: o_ALU = {{(ALU_SRC_WIDTH-1){1'b0}}, (i_ALUsrcA < i_ALUsrcB)};
default: o_ALU = 'x;
endcase
end
endmodule

module riscv_ALUsrc #(
parameter INSTRUCT_WIDTH = 32, 
parameter REG_DATAWIDTH = 32
)(
input logic [REG_DATAWIDTH-1:0] i_rs2_data, 
input logic [INSTRUCT_WIDTH-1:0] i_immext, 
input logic i_ALUsrcB_ctrl,

output logic [INSTRUCT_WIDTH-1:0] o_ALUsrcB
);

localparam SELECT_RS2 = 1'b0;  
localparam SELECT_IMMEXT = 1'b1; 

always_comb 
begin
    case (i_ALUsrcB_ctrl)
    SELECT_RS2: o_ALUsrcB = i_rs2_data;  
    SELECT_IMMEXT: o_ALUsrcB = i_immext;
    default o_ALUsrcB = 'x;
    endcase
end 
endmodule

module rscv_brancheval #(
parameter FUNC3 = 3
)(
input logic [FUNC3-1:0] i_func3,
input logic i_zero, 
input logic i_branch_ctrl, 

output logic o_dobranch
);
assign o_dobranch = i_zero ^ (i_func3[0] ^ i_func3[2]) & i_branch_ctrl;
endmodule

module riscv_dmem #(
parameter DMEM_ADDR_WIDTH = 16, // SAME AS PC FOR IMPLEMENTING SIMULATION FLAGS, if ALU bits write to out of range address 
parameter DATA_WIDTH = 32, 
parameter FUNC3 = 3
)(
input logic i_clk,
input logic i_mem_write, 
input logic i_mem_read, 
input logic [DATA_WIDTH-1:0] i_ALU, 
input logic [DATA_WIDTH-1:0] i_sr2,
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
        CHOOSE_BYTE0: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][7:0] <= i_sr2[7:0]; 
        CHOOSE_BYTE1: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][15:8] <= i_sr2[7:0]; 
        CHOOSE_BYTE2: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][23:16] <= i_sr2[7:0]; 
        CHOOSE_BYTE3: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][31:24] <= i_sr2[7:0];
        endcase
    CHOOSE_SH:
        case(i_ALU[1])
        CHOOSE_HALF0: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][15:0] <= i_sr2[15:0]; 
        CHOOSE_HALF1: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]][31:16] <= i_sr2[15:0];
        endcase
    CHOOSE_SW: d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]] <= i_sr2;
    default: ;
    endcase
CHOOSE_READ: o_dmem_data <= d_mem[i_ALU[DMEM_ADDR_WIDTH-1:2]];
default: ;
endcase
end 
endmodule

module riscv_imem #(
parameter PC_WIDTH = 32,
parameter IMEM_ADDR_WIDTH = 16
parameter INSTRUCT_WIDTH = 32)(

input logic [PC_WIDTH-1:0] i_pc,
output logic [INSTRUCT_WIDTH-1:0] o_instruct
); 

logic [INSTRUCT_WIDTH-1:] i_mem [(1 << IMEM_ADDR_WIDTH)-1:0];

assign o_instruct = i_mem[i_pc[IMEM_ADDR_WIDTH-1:2]];  
endmodule

module riscv_immext #(
parameter INSTRUCT_WIDTH = 32,
parameter IMM_WIDTH = 32,
parameter IMMEXT_CTRL = 3
)(
input logic [INSTRUCT_WIDTH-1:0] i_instruct, 
input logic [IMMEXT_CTRL-1:0] i_immext_ctrl,
output logic [IMM_WIDTH-1:0] o_immext
); 

localparam I_TYPE = 3'b000;
localparam S_TYPE = 3'b001;
localparam B_TYPE = 3'b010;
localparam U_TYPE = 3'b011;
localparam J_TYPE = 3'b100;

always_comb
begin
    case(i_immext_ctrl)
        I_TYPE: o_immext = {{20{i_instruct[31]}}, i_instruct[31:20]};
        S_TYPE: o_immext = {{20{i_instruct[31]}}, i_instruct[31:25], i_instruct[11:7]};
        B_TYPE: o_immext = {{19{i_instruct[31]}}, i_instruct[31], i_instruct[7], i_instruct[30:25], i_instruct[11:8], 1'b0};
        U_TYPE: o_immext = {i_instruct[31:12], 12'b000000000000};
        J_TYPE: o_immext = {{11{i_instruct[31]}}, i_instruct[31], i_instruct[19:12], i_instruct[20], i_instruct[30:21], 1'b0};
        default: o_immext = 'x; 
    endcase
end
endmodule

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

assign sign_enable = i_func3[FUNC3-1];

always_comb 
begin
case(i_func3[FUNC3-2:0])
    byte_loaded = 'x; 
    half_loaded = 'x; 
    o_dmem_clean = 'x;
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

module riscv_pc_addrs #(
parameter PC_WIDTH = 32, 
parameter IMM_WIDTH = 32, 
parameter REG_DATAWIDTH = 32)(

input logic [PC_WIDTH-1:0] i_pc, 
input logic [IMM_WIDTH-1:0] i_immext,
input logic [REG_DATAWIDTH-1:0] i_rs1_data,

output logic o_pc_add_immext,
output logic o_rs1_add_immext
);

assign o_pc_add_immext = i_pc + i_immext;
assign o_rs1_add_immext = (i_rs1_data + i_immext) & 1'b0;
endmodule

module riscv_pc #(
parameter PC_WIDTH = 32,
parameter JUMPS_CTRL = 2,
parameter PC_INITIAL = 0
)(
input logic i_clk,
input logic i_nrst,
input logic [PC_WIDTH-1:0] i_pc_add_immext, 
input logic [PC_WIDTH-1:0] i_rs1_add_immext,
input logic i_dobranch, 
input logic [JUMPS_CTRL-1:0] i_jumps_ctrl,

output logic [PC_WIDTH-1:0] o_pc
);

logic [PC_WIDTH-1:0] w_pc_next;

always_ff @(posedge i_clk or negedge i_nrst)
begin
    if(!i_nrst)
    begin
        o_pc <= PC_INITIAL; 
    end
    else 
    begin
        o_pc <= w_pc_next; 
    end
end

always_comb 
begin
    case ({i_jumps_ctrl, i_dobranch}) 
    3'b000: w_pc_next = o_pc + 4;
    3'b001: w_pc_next = i_pc_add_immext;
    3'b010: w_pc_next = i_pc_add_immext;
    3'b100: w_pc_next = i_rs1_add_immext; 
    default: w_pc_next = 'x;
    endcase
end
endmodule

module riscv_regfile #(
parameter REG_DATAWIDTH = 32, //DO NOT OVERRIDE
parameter DATA_WIDTH = 8, //DO NOT OVERRIDE
parameter INSTRUCT_WIDTH = 32 // DO NOT OVERRIDE
)(
input logic i_clk,
input logic i_nrst,
input logic [INSTRUCT_WIDTH-1:0] i_instruct,
input logic [DATA_WIDTH-1:0] i_din,
input logic i_wenable, 

output logic [REG_DATAWIDTH-1:0] o_rs1_data, 
output logic [REG_DATAWIDTH-1:0] o_rs2_data
);

localparam REG_WIDTH = 5; 
localparam REG_ADDRWIDTH = 32; 

logic [REG_DATAWIDTH-1:0] reg_mem [REG_ADDRWIDTH-1:0]; 
logic [REG_WIDTH-1:0] rs1; 
logic [REG_WIDTH-1:0] rs2;
logic [REG_WIDTH-1:0] rd;

assign rs1 = i_instruct[19:15]; 
assign rs2 = i_instruct[24:20];
assign rd = i_instruct[11:7];

assign o_rs1_data = reg_mem[rs1];
assign o_rs2_data = reg_mem[rs2];

always_comb 
begin
    if(i_wenable == 1)
    reg_mem[rd] = i_din;
end

endmodule

module riscv_regwrite_src #(
parameter REG_DATAWIDTH = 32,
parameter REGWRITE_MUX_CTRL = 3
)(
input logic [REG_DATAWIDTH-1:0] i_ALU, 
input logic [REG_DATAWIDTH-1:0] i_pc,
input logic [REG_DATAWIDTH-1:0] i_dmem, 
input logic [REG_DATAWIDTH-1:0] i_immext, 
input logic [REG_DATAWIDTH-1:0] i_pc_add_immext,
input logic [REGWRITE_MUX_CTRL-1:0] regwrite_mux_ctrl, 


output logic [REG_DATAWIDTH-1:0] o_rd_data
);

localparam CHOOSE_ALU = 3'b000; 
localparam CHOOSE_DMEM = 3'b001; 
localparam CHOOSE_IMMEXT = 3'b010; 
localparam CHOOSE_PC = 3'b100;
localparam CHOOSE_PC_ADD_IMMEXT = 3'b101;

always_comb
begin 
case(regwrite_mux_ctrl)
CHOOSE_ALU: o_rd_data = i_ALU;
CHOOSE_DMEM: o_rd_data = i_dmem;
CHOOSE_IMMEXT: o_rd_data = i_immext;
CHOOSE_PC: o_rd_data = i_pc;
CHOOSE_PC_ADD_IMMEXT: o_rd_data = i_pc_add_immext;
default: o_rd_data = 'x;
endcase
end

endmodule