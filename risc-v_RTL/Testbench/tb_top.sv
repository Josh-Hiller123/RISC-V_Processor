`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_package::*; 
`timescale 1us/1ns
module tb_top #(
//Main Memory Size and Uniform WORD_BITS for I/D cache
parameter MAIN_MEM_WIDTH = 14, 
parameter WORD_BITS = 2,

//Main Memory Access Latency (clk cycles)
parameter LATENCY = 10,

//Icache Parameters
parameter IC_INDEX_BITS = 5,
parameter IC_WAYS_AMT = 3, 

//Dcache Parameters
parameter DC_INDEX_BITS = 5,
parameter DC_WAYS_AMT = 3, 

//PC starting value 
parameter PC_INITIAL = 32'h8000_0000 // start for spike so lockstep matches up
)();

logic clk_tb = 1'b0;
logic nrst_tb;

logic valid_tb;
logic [31:0] pc_tb; 
logic [31:0] instruct_tb; 
logic [31:0] alu_tb; // use for mem address
logic [2:0] func3_tb; //use for store-byte/store-half, tells tb what bits to check against rs2_data
logic [31:0] rs2_data_tb; // mem write data
logic mem_write_tb; //for stores
logic [31:0] dmem_clean_tb; // for loads

logic wenable_tb; //regfile writes
logic [31:0] rd_data_tb;
logic [4:0] rd_tb; 

always #5 clk_tb = ~clk_tb; 

riscv_top #(
.MAIN_MEM_WIDTH(MAIN_MEM_WIDTH), 
.WORD_BITS(WORD_BITS), 
.LATENCY(LATENCY), 
.IC_INDEX_BITS(IC_INDEX_BITS), 
.IC_WAYS_AMT(IC_WAYS_AMT), 
.DC_INDEX_BITS(DC_INDEX_BITS),
.DC_WAYS_AMT(DC_WAYS_AMT), 
.PC_INITIAL(PC_INITIAL)
) tb_to_top (
.i_clk(clk_tb), 
.i_nrst(nrst_tb),
.o_valid(valid_tb), 
.o_pc(pc_tb), 
.o_instruct(instruct_tb), 
.o_alu(alu_tb), 
.o_func3(func3_tb), 
.o_rs2_data(rs2_data_tb), 
.o_mem_write(mem_write_tb), 
.o_dmem_clean(dmem_clean_tb), 
.o_wenable(wenable_tb), 
.o_rd_data(rd_data_tb), 
.o_rd(rd_tb)
);

tb_interface top_to_interface (
.i_clk(clk_tb),
.i_nrst(nrst_tb), 
.valid_tb(valid_tb), 
.pc_tb(pc_tb), 
.instruct_tb(instruct_tb), 
.alu_tb(alu_tb), 
.func3_tb(func3_tb), 
.rs2_data_tb(rs2_data_tb), 
.mem_write_tb(mem_write_tb), 
.dmem_clean_tb(dmem_clean_tb), 
.wenable_tb(wenable_tb), 
.rd_data_tb(rd_data_tb), 
.rd_tb(rd_tb)

);

// bind needed to grab main_mem from rtl
bind riscv_main_memory tb_tasks main_mem_to_tasks 
(
.main_mem_tb(main_mem)
);


initial 
begin
    nrst_tb = 0;
    repeat(5) @(negedge clk_tb);
    nrst_tb = 1;
end


initial 
begin
    $dumpfile("riscv_waveform.vcd");
    $dumpvars(0, tb_top);
    
    //uvm_config sets for interface/tasks to tb_package classes
    uvm_config_db#(virtual tb_interface)::set(null, "*", "virtual_interface", top_to_interface);
    uvm_config_db#(virtual tb_tasks)::set(null, "*", "virtual_tasks", tb_to_top.main_memory_wiring.main_mem_to_tasks);
    
    run_test();
end
endmodule