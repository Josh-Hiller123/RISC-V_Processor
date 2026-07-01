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
                default: o_ALUop = 'x;
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