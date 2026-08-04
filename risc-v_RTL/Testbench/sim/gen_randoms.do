catch {quit -sim}
vlib work
vmap work work

vlog -sv risc-v_RTL/Testbench/tb_rand_package.sv \
         risc-v_RTL/Testbench/tb_rand_top.sv

vsim tb_rand_top \
     +NUM=400 +START=1 \
     +DIR=risc-v_RTL/Testbench/programs/randoms/src
run -all
quit -sim
