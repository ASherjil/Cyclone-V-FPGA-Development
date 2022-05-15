# make a library and map it
# vlib work 
# vmap work work

# Compile the modules
vcom FSM.vhd
vcom FSM_tb.vhd

# Simulate the testbench
vsim work.FSM_tb

# stop Arith warnings
set StdArithNoWarfnings 1

# show complted in modelsim window
echo "-----------Completed ------------"

# Set the waves 
add wave *

# Run until testbench asserts false
run 500ns