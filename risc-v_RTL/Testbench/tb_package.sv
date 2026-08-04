`include "uvm_macros.svh" 
package tb_package;
import uvm_pkg::*;
import tb_commit_struct::*;  

class rvfi_item extends uvm_sequence_item;
logic [31:0] pc_rvfi; 
logic [31:0] instruct_rvfi;
logic [31:0] alu_rvfi;
logic [2:0] func3_rvfi;
logic [31:0] rs2_data_rvfi;
logic mem_write_rvfi;
logic [31:0] dmem_clean_rvfi;
logic wenable_rvfi;
logic [31:0] rd_data_rvfi;
logic [4:0] rd_rvfi;
int order_counter_rvfi;

`uvm_object_utils_begin(rvfi_item)
  `uvm_field_int(pc_rvfi, UVM_ALL_ON | UVM_HEX)
  `uvm_field_int(instruct_rvfi, UVM_ALL_ON | UVM_HEX)
  `uvm_field_int(alu_rvfi, UVM_ALL_ON | UVM_HEX)
  `uvm_field_int(func3_rvfi, UVM_ALL_ON | UVM_HEX)
  `uvm_field_int(rs2_data_rvfi, UVM_ALL_ON | UVM_HEX)
  `uvm_field_int(mem_write_rvfi, UVM_ALL_ON | UVM_HEX)
  `uvm_field_int(dmem_clean_rvfi, UVM_ALL_ON | UVM_HEX)
  `uvm_field_int(wenable_rvfi, UVM_ALL_ON | UVM_HEX)
  `uvm_field_int(rd_data_rvfi, UVM_ALL_ON | UVM_HEX)
  `uvm_field_int(rd_rvfi, UVM_ALL_ON | UVM_DEC)
  `uvm_field_int(order_counter_rvfi, UVM_ALL_ON | UVM_DEC)
`uvm_object_utils_end

function new(string name = "rvfi_item");
  super.new(name);
endfunction
endclass

//Builds nothing, calls parse_log; reads each spike line and commits rvfi values accordingly
class spike_ref_model extends uvm_component; 
`uvm_component_utils(spike_ref_model)
localparam PC_INITIAL = 32'h8000_0000; //MUST MATCH TOP
localparam HALT_ADDR = 32'h8000_3FF0;  //MUST MATCH ALL OTHER INSTANCES

spike_commit_t spike_commit_queue[$]; 

function new(string name, uvm_component parent);
super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
string program_path; 
super.build_phase(phase); 
if (!$value$plusargs("SPIKE_LOG=%s", program_path))
      `uvm_fatal("NO_SPIKE_LOG", "spike_ref_model did not get the spike log")
    parse_log(program_path);
endfunction

function void parse_log(string path);
    int file;
    string line;
    int core, privilege, rd;
    logic [31:0] pc, instruct, rd_data, mem_addr, mem_data;
    spike_commit_t spike_commit;

    file = $fopen(path, "r");
    if (file == 0) `uvm_fatal("SPIKE_LOG", $sformatf("could not open %s", path))

//covers stores
    while ($fgets(line, file)) begin
      if ($sscanf(line, "core %d: %d 0x%h (0x%h) mem 0x%h 0x%h",
                        core, privilege, pc, instruct, mem_addr, mem_data) == 6) begin
        if (pc < PC_INITIAL) continue;                
        spike_commit = '{pc, instruct, 1'b0, 5'd0, 32'd0, 1'b1, mem_addr, mem_data};
        spike_commit_queue.push_back(spike_commit);
        if (mem_addr == HALT_ADDR) break;               
      end

//covers loads/regfile writes (LOAD, R/I types, jumps, upper)
      else if ($sscanf(line, "core %d: %d 0x%h (0x%h) x%d 0x%h",
                             core, privilege, pc, instruct, rd, rd_data) == 6) begin
        if (pc < PC_INITIAL) continue;
        spike_commit = '{pc, instruct, (rd != 0), rd[4:0], rd_data, 1'b0, 32'd0, 32'd0};  
        spike_commit_queue.push_back(spike_commit);
      end
      
//covers branches, misc
      else if ($sscanf(line, "core %d: %d 0x%h (0x%h)",
                             core, privilege, pc, instruct) == 4) begin
        if (pc < PC_INITIAL) continue;
        spike_commit = '{pc, instruct, 1'b0, 5'd0, 32'd0, 1'b0, 32'd0, 32'd0};
        spike_commit_queue.push_back(spike_commit);
      end
    end
    $fclose(file);
    `uvm_info("SPIKE", $sformatf("finished parsing spike, performed %0d commits", spike_commit_queue.size()), UVM_LOW)
  endfunction

//DUT commits check 1, if commit comes but ref_queue is empty 
  function spike_commit_t get_next();
    if (spike_commit_queue.size() == 0)
      `uvm_fatal("SPIKE", "DUT committed more instructions than Spike (ref queue empty when DUT commit arrived)")
    return spike_commit_queue.pop_front();
  endfunction
endclass

//Builds virtual interface/item; transfers processor signals to item, trasmits item via analysis port
class rvfi_monitor extends uvm_monitor;
  `uvm_component_utils(rvfi_monitor)

  function new(string name = "rvfi_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual tb_interface virtual_interface; 
  uvm_analysis_port #(rvfi_item) analysis_port; 

   function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual tb_interface)::get(this, "", "virtual_interface", virtual_interface))
      `uvm_fatal("NO_VIRTUAL_INTERFACE", "rvfi_monitor did not get the virtual interface")
    analysis_port = new("analysis_port", this);
  endfunction

int order_counter_monitor; 
  task run_phase(uvm_phase phase);
    rvfi_item item;
    forever begin
      @(virtual_interface.cb);                       
      if (virtual_interface.i_nrst && virtual_interface.cb.valid_tb) begin
        item = rvfi_item::type_id::create("rvfi_item");
        item.pc_rvfi = virtual_interface.cb.pc_tb;
        item.instruct_rvfi = virtual_interface.cb.instruct_tb;
        item.alu_rvfi = virtual_interface.cb.alu_tb;
        item.func3_rvfi = virtual_interface.cb.func3_tb;
        item.rs2_data_rvfi = virtual_interface.cb.rs2_data_tb;
        item.mem_write_rvfi = virtual_interface.cb.mem_write_tb;
        item.dmem_clean_rvfi = virtual_interface.cb.dmem_clean_tb;
        item.wenable_rvfi = virtual_interface.cb.wenable_tb && (virtual_interface.cb.rd_tb != 0); // x0 suppression
        item.rd_data_rvfi = virtual_interface.cb.rd_data_tb;
        item.rd_rvfi = virtual_interface.cb.rd_tb;
        item.order_counter_rvfi = ++order_counter_monitor;
        analysis_port.write(item); // send to agent
      end
    end
  endtask
endclass

//builds moniter; recieves item via analysis port
class rvfi_agent extends uvm_agent;
`uvm_component_utils(rvfi_agent)
uvm_analysis_port #(rvfi_item) analysis_port;
rvfi_monitor monitor; 

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  monitor = rvfi_monitor::type_id::create("monitor", this);
  analysis_port = new("analysis_port", this); 
endfunction

function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  monitor.analysis_port.connect(analysis_port);      
endfunction
endclass

//builds spike_ref_model which it uses to derive spike_expected, recieves item via analysis implementation;
//compares item to expected 
class rvfi_scoreboard extends uvm_scoreboard;
`uvm_component_utils(rvfi_scoreboard)

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

localparam HALT_ADDR = 32'h8000_3FF0; // MUST MATCH ALL OTHER INSTANCES
localparam SB_MASK = 32'h0000_00FF; 
localparam SH_MASK = 32'h0000_FFFF; 
localparam SW_MASK = 32'hFFFF_FFFF;
localparam CHOOSE_SB = 3'b000;
localparam CHOOSE_SH = 3'b001;
localparam CHOOSE_SW = 3'b010; 

uvm_analysis_imp #(rvfi_item, rvfi_scoreboard) analysis_implementation;
spike_ref_model ref_model;
logic test_finished; 

function void write(rvfi_item item);
spike_commit_t spike_expected; 
logic [31:0] mem_data_mask;

if (test_finished) return;
spike_expected = ref_model.get_next(); 

if(item.pc_rvfi != spike_expected.pc_commit)
`uvm_error("SCOREBOARD_COMPARE", $sformatf("Spike and DUT mismatch on PC; order = %0d | DUT's pc = %0h | Spike's pc = %0h", 
                                          item.order_counter_rvfi, item.pc_rvfi, spike_expected.pc_commit))

if(item.instruct_rvfi != spike_expected.instruct_commit)
`uvm_error("SCOREBOARD_COMPARE", $sformatf("Spike and DUT mismatch on INSTRUCT; pc = %0h | DUT's instruct = %0h | Spike's instruct = %0h", 
                                          item.pc_rvfi, item.instruct_rvfi, spike_expected.instruct_commit))

if(item.wenable_rvfi != spike_expected.wenable_commit)
`uvm_error("SCOREBOARD_COMPARE", $sformatf("Spike and DUT mismatch on WENABLE; pc = %0h | DUT's wenable = %0h | Spike's wenable = %0h", 
                                          item.pc_rvfi, item.wenable_rvfi, spike_expected.wenable_commit))

else if (item.wenable_rvfi) 
begin
    if (item.rd_rvfi !== spike_expected.rd_commit)
      `uvm_error("SCOREBOARD_COMPARE", $sformatf("Spike and DUT mismatch on RD; pc = %0h | DUT's rd = %0h | Spike's rd = %0h", 
                                  item.pc_rvfi, item.rd_rvfi, spike_expected.rd_commit))
    if (item.rd_data_rvfi !== spike_expected.rd_data_commit)
      `uvm_error("SCOREBOARD_COMPARE", $sformatf("Spike and DUT mismatch on RD_DATA; pc = %0h | DUT's rd_data = %0h | Spike's rd_data = %0h", 
                                  item.pc_rvfi, item.rd_data_rvfi, spike_expected.rd_data_commit))
  end

 if (item.mem_write_rvfi !== spike_expected.mem_write_commit)
    `uvm_error("SCOREBOARD_COMPARE", $sformatf("Spike and DUT mismatch on MEM_WRITE; pc = %0h | DUT's mem_write = %0h | Spike's mem_write = %0h", 
                                  item.pc_rvfi, item.mem_write_rvfi, spike_expected.mem_write_commit))
  else if (item.mem_write_rvfi) begin
    case(item.func3_rvfi)
    CHOOSE_SB: mem_data_mask = SB_MASK;
    CHOOSE_SH: mem_data_mask = SH_MASK; 
    CHOOSE_SW: mem_data_mask = SW_MASK; 
    default: 
    begin
      `uvm_error("SCOREBOARD_COMPARE", $sformatf("Invalid func3 detected from interface (func3_rvfi); pc = %0h | Interface's func3 = %0h", 
                                  item.pc_rvfi, item.func3_rvfi))
      mem_data_mask = SW_MASK; 
    end
    endcase
    if (item.alu_rvfi !== spike_expected.mem_addr_commit)
      `uvm_error("SCOREBOARD_COMPARE", $sformatf("Spike and DUT mismatch on MEM_ADDR(alu); pc = %0h | DUT's mem_addr = %0h | Spike's mem_addr = %0h", 
                                  item.pc_rvfi, item.alu_rvfi, spike_expected.mem_addr_commit))
    if ((item.rs2_data_rvfi & mem_data_mask) !== (spike_expected.mem_data_commit & mem_data_mask))
      `uvm_error("SCOREBOARD_COMPARE", $sformatf("Spike and DUT mismatch on MEM_DATA(rs2_data); pc = %0h | DUT's mem_data = %0h | Spike's mem_data = %0h | mem_data_mask = %0h", 
                                  item.pc_rvfi, item.rs2_data_rvfi, spike_expected.mem_data_commit, mem_data_mask))
    if (item.alu_rvfi == HALT_ADDR) test_finished = 1; 
  end
endfunction

function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  analysis_implementation = new("analysis_implementation", this);
endfunction

//DUT commits check 2, if queue isn't empty after last commit/prorgam end
function void check_phase(uvm_phase phase);
super.check_phase(phase);
  if (ref_model.spike_commit_queue.size() != 0)
    `uvm_error("SCOREBOARD_COMPARE", $sformatf("DUT committed fewer instructions than Spike (ref queue not empty after program ended); %0d reference commits left over", ref_model.spike_commit_queue.size()))
endfunction
endclass

//builds interface, moniters if sw to halt address happens; if 1 is stored, success; else, fail
class rvfi_halt_monitor extends uvm_monitor;
  `uvm_component_utils(rvfi_halt_monitor)

  virtual tb_interface virtual_interface;
  localparam HALT_ADDR = 32'h8000_3FF0;   // MUST MATCH ALL OTHER INSTANCES

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual tb_interface)::get(this, "", "virtual_interface", virtual_interface))
      `uvm_fatal("NO_VIF", "halt monitor did not get the virtual interface")
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);                        
    forever begin
      @(virtual_interface.cb);
      if (virtual_interface.cb.mem_write_tb &&
          virtual_interface.cb.alu_tb == HALT_ADDR) begin
        if (virtual_interface.cb.rs2_data_tb == 32'd1)
          `uvm_info ("HALT", "TEST PASSED", UVM_LOW)
        else
          `uvm_error("HALT", $sformatf("TEST FAILED, Data Detected =%0d",
                                       virtual_interface.cb.rs2_data_tb))
        break;
      end
    end
    phase.drop_objection(this);                         
  endtask
endclass

// builds agent, scoreboard, halt monitor, ref_model; connects analysis port to analysis implementation 
class rvfi_env extends uvm_env; 
`uvm_component_utils(rvfi_env)

rvfi_agent agent; 
rvfi_scoreboard scoreboard;
rvfi_halt_monitor halt_monitor;
spike_ref_model ref_model;

function new(string name, uvm_component parent); 
  super.new(name, parent); 
endfunction

function void build_phase(uvm_phase phase); 
  super.build_phase(phase); 
  agent = rvfi_agent::type_id::create("agent", this); 
  scoreboard = rvfi_scoreboard::type_id::create("scoreboard", this); 
  halt_monitor = rvfi_halt_monitor::type_id::create("halt_monitor", this);
  ref_model = spike_ref_model::type_id::create("ref_model", this);
endfunction

function void connect_phase(uvm_phase phase); 
  super.connect_phase(phase); 
  agent.analysis_port.connect(scoreboard.analysis_implementation);
  scoreboard.ref_model = ref_model;
endfunction
endclass

//builds tasks, loads the program path into memory and checks pc_initial 
class rvfi_program_loader extends uvm_component;
`uvm_component_utils(rvfi_program_loader)

virtual tb_tasks virtual_tasks;

function new(string name, uvm_component parent);
super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db#(virtual tb_tasks)::get(this, "", "virtual_tasks", virtual_tasks))
  `uvm_fatal("NO_VIRTUAL_TASKS", "rvfi_program_loader did not get virtual_tasks")
endfunction

  task load_program(string program_path);
    virtual_tasks.load_instructions(program_path);
    virtual_tasks.check_pc_initial(); 
  endtask
endclass

//builds env and program loader; makes sure we get a program and writes final report
class rvfi_test extends uvm_test; 
`uvm_component_utils(rvfi_test)

rvfi_env env;
rvfi_program_loader program_loader;

function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  env = rvfi_env::type_id::create("env", this);
  program_loader = rvfi_program_loader::type_id::create("program_loader", this);
endfunction

task run_phase(uvm_phase phase);
  string program_path;
  if (!$value$plusargs("PROGRAM=%s", program_path))
  `uvm_fatal("NO_PROGRAM_LOADED", "rvfi_test did not recieve a program in program_path")          
  program_loader.load_program(program_path);
endtask

function void end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  uvm_top.print_topology();
endfunction
endclass
endpackage
