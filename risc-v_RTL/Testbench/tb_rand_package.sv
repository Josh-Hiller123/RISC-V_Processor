package tb_rand_package; 

localparam JUMP_MAX = 8; 
localparam DATA_RANGE = 2048; 

typedef enum{ALU_R, ALU_I, SHIFT_I, LOAD, STORE, BRANCH, UPPER, JAL} instruct_type_e; 

//random instruct generator
class instruct_generate; 
localparam DATA_BASE_REG = 6;

rand instruct_type_e instruct_type; 
rand int unsigned op; 
rand logic [4:0] rd; 
rand logic [4:0] rs1; 
rand logic [4:0] rs2; 
rand int imm; 
rand int unsigned jump_offset; 

constraint instruct_weights {
    instruct_type dist {ALU_R := 18, ALU_I := 18, SHIFT_I := 8, LOAD := 12, STORE := 12, BRANCH := 18, UPPER := 7, JAL := 7};
}

constraint op_constraints {
    solve instruct_type before op; 
    if (instruct_type == ALU_R) op inside {[0:9]};
    if (instruct_type == ALU_I) op inside {[0:5]};
    if (instruct_type == SHIFT_I) op inside {[0:2]};
    if (instruct_type == LOAD) op inside {[0:4]};
    if (instruct_type == STORE) op inside {[0:2]};
    if (instruct_type == BRANCH) op inside {[0:5]};
    if(instruct_type == UPPER) op inside {[0:1]};
    if(instruct_type == JAL) op == 0; // no jalr, unpredictable
}

constraint reg_constraints {
    solve instruct_type before rs1; //rd and rs2 are the same for everything, rs1 differs on mem access
    rd inside {[1:5]}; 
    rs2 inside {[0:5]}; 
    if (instruct_type == LOAD || instruct_type == STORE) rs1 == DATA_BASE_REG; 
        else rs1 inside {[0:5]}; 
}

constraint imm_constraints {
    solve instruct_type before imm; 
    solve op before imm; 
    if (instruct_type == ALU_I) imm inside {[-2048:2047]}; 
    if (instruct_type == SHIFT_I) imm inside {[0:31]};          
    if (instruct_type == UPPER) imm inside {[0:1048575]}; 
    if (instruct_type == LOAD || instruct_type == STORE) {
        imm inside {[0:DATA_RANGE-4]}; 
        if ((instruct_type == LOAD) && (op == 2)) (imm % 4) == 0; // lw
        if ((instruct_type == LOAD) && ((op == 1) || (op == 4))) (imm % 2) == 0; // lh/lhu
        if ((instruct_type == STORE) && (op == 2)) (imm % 4) == 0; // sw
        if ((instruct_type == STORE) && (op == 1)) (imm % 2) == 0; // sh
    }    
}

constraint jump_distance_constraints {jump_offset inside {[1:JUMP_MAX]};}

function string generate_to_assembly(string jump_target = "");
string alu_r [0:9] = '{"add", "sub", "xor", "or", "and", "sll", "srl", "sra", "slt", "sltu"};
string alu_i [0:5] = '{"addi", "xori", "ori", "andi", "slti", "sltiu"}; 
string shift_i [0:2] = '{"slli", "srli", "srai"}; 
string load [0:4] = '{"lb", "lh", "lw", "lbu", "lhu"}; 
string store [0:2] = '{"sb", "sh", "sw"}; 
string branch [0:5] = '{"beq", "bne", "blt", "bge", "bltu", "bgeu"}; 
string upper [0:1] = '{"lui", "auipc"}; 

case(instruct_type)
ALU_R: return $sformatf("%s x%0d, x%0d, x%0d", alu_r[op], rd, rs1, rs2); 
ALU_I: return $sformatf("%s x%0d, x%0d, %0d", alu_i[op], rd, rs1, imm); 
SHIFT_I: return $sformatf("%s x%0d, x%0d, %0d", shift_i[op], rd, rs1, imm); 
LOAD: return $sformatf("%s x%0d, %0d(x%0d)", load[op], rd, imm, rs1);
STORE: return $sformatf("%s x%0d, %0d(x%0d)", store[op], rs2, imm, rs1);
BRANCH: return $sformatf("%s x%0d, x%0d, %s", branch[op], rs1, rs2, jump_target); 
UPPER: return $sformatf("%s x%0d, %0d", upper[op], rd, imm);
JAL: return $sformatf("jal x%0d, %s", rd, jump_target); 
endcase
endfunction
endclass 

class program_generate; 
localparam INSTRUCT_AMT = 1000;
int seed; 

instruct_generate program_body[$]; 
logic [31:0] reg_initialized [6:0]; //6 through 0, matches registers used in instruct_generate class

function new(int seed); // QUESTION: whats the point of this function? in uvm we use function new so that the class can be called on by other classes right? if thats the case, why do we have it here? why doesnt class instruct_generate need it? clear up my confusion on this topic
this.seed = seed;
endfunction

function void program_write(); 
process::self().srandom(seed); //QUESTION: what is this doing? Walk me through exactly why we use the seed and how it functions in this program

for(int r = 1; r <= 5; r++) reg_initialized[r] = $urandom(); //QUESTION: shouldnt we initialize registers to 0? doesnt spike automatically set registers to 0, so we should set them to 0 here as well no? 

for(int i = 0; i < INSTRUCT_AMT; i++)
begin
    instruct_generate instruct = new(); 
    instruct.randomize();
    program_body.push_back(instruct);
end
endfunction

function void file_write(string path);
int file = $fopen(path, "w"); 

if (file == 0) 
    $fatal(1, "file %s wasn't received", path); 

$fdisplay(file, "# This is a random program. seed = %0d | Instructions = %0d", seed, INSTRUCT_AMT); 
$fdisplay(file, ".section .text"); 
$fdisplay(file, ".globl _start");
$fdisplay(file, "_start:"); 

for(int w = 1; w <= 5; w++)
    $fdisplay(file, "li x%0d, 0x%0x", w, reg_initialized[w]); 

$fdisplay(file, "la x6, data_range"); 

for (int n = 0; n <= INSTRUCT_AMT-1; n++) 
begin
    string line; 
    string jump_target_string; 

    if((program_body[n].instruct_type == BRANCH) || (program_body[n].instruct_type == JAL))
    begin
        int jump_target = n + 32'(program_body[n].jump_offset); 
        jump_target_string = (jump_target >= INSTRUCT_AMT) ? "END" : $sformatf("L%0d", jump_target);
        line = program_body[n].generate_to_assembly(jump_target_string);
    end
    else line = program_body[n].generate_to_assembly(); 
    
    $fdisplay(file, "L%0d: %s", n, line);
end

//write 1 tohost, simulation environment set-up
$fdisplay(file, "END:"); //QUESTION: I dont understand what any of this is doing from here to the end of the package, explain line by line.
$fdisplay(file, "li a0, 1");
$fdisplay(file, "la a1, tohost");
$fdisplay(file, "sw a0, 0(a1)");
$fdisplay(file, "1: j 1b");

$fdisplay(file, ".section .data");
$fdisplay(file, ".balign 16");
$fdisplay(file, "data_range: .zero %0d", DATA_RANGE);
$fdisplay(file, ".section .tohost, \"aw\", @progbits");
$fdisplay(file, ".align 3");
$fdisplay(file, ".globl tohost");
$fdisplay(file, "tohost: .dword 0");
$fdisplay(file, ".globl fromhost");
$fdisplay(file, "fromhost: .dword 0");
$fclose(file);
endfunction

endclass
endpackage