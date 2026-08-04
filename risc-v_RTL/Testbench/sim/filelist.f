# struct packages
risc-v_RTL/Fetch_Stage/if_id_struct.sv
risc-v_RTL/Decode_Stage/id_ex_struct.sv
risc-v_RTL/Execute_Stage/ex_mem_struct.sv
risc-v_RTL/Memory_Stage/mem_wb_struct.sv

# RTL modules
risc-v_RTL/Decode_Stage/riscv_immext.sv
risc-v_RTL/Decode_Stage/riscv_jump_target.sv
risc-v_RTL/Decode_Stage/riscv_ALU_cu.sv
risc-v_RTL/Decode_Stage/riscv_decoder.sv
risc-v_RTL/Decode_Stage/riscv_id_ex_reg.sv
risc-v_RTL/Decode_Stage/riscv_regfile.sv
risc-v_RTL/Decode_Stage/riscv_forwarding.sv
risc-v_RTL/Decode_Stage/riscv_decode_stage.sv
risc-v_RTL/Execute_Stage/riscv_brancheval.sv
risc-v_RTL/Execute_Stage/riscv_ALU.sv
risc-v_RTL/Execute_Stage/riscv_ALUsrc.sv
risc-v_RTL/Execute_Stage/riscv_ALU_rs1.sv
risc-v_RTL/Execute_Stage/riscv_ALU_rs2.sv
risc-v_RTL/Execute_Stage/riscv_ex_mem_reg.sv
risc-v_RTL/Execute_Stage/riscv_execute_stage.sv
risc-v_RTL/Fetch_Stage/riscv_if_id_reg.sv
risc-v_RTL/Fetch_Stage/riscv_icache.sv
risc-v_RTL/Fetch_Stage/riscv_pc.sv
risc-v_RTL/Fetch_Stage/riscv_fetch_stage.sv
risc-v_RTL/Memory_Stage/riscv_load_ext.sv
risc-v_RTL/Memory_Stage/riscv_mem_forward.sv
risc-v_RTL/Memory_Stage/riscv_mem_wb_reg.sv
risc-v_RTL/Memory_Stage/riscv_dcache.sv
risc-v_RTL/Memory_Stage/riscv_memory_stage.sv
risc-v_RTL/Writeback_Stage/riscv_regwrite_src.sv
risc-v_RTL/Writeback_Stage/riscv_wb_stage.sv
risc-v_RTL/Cross_Register_Units/riscv_main_memory.sv
risc-v_RTL/Cross_Register_Units/riscv_flush.sv
risc-v_RTL/Cross_Register_Units/riscv_stall.sv
risc-v_RTL/Cross_Register_Units/riscv_top.sv

#testbench
risc-v_RTL/Testbench/tb_commit_struct.sv
risc-v_RTL/Testbench/tb_interface.sv
risc-v_RTL/Testbench/tb_tasks.sv
risc-v_RTL/Testbench/tb_package.sv
risc-v_RTL/Testbench/tb_top.sv
