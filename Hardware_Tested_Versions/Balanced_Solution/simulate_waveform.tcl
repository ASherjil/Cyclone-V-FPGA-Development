# This is the .tcl script for producing a wave upto a specific time. 
# Once the Questasim project is opened, running this .tcl script will add
# the necessary signals and generate the required waveform. 

# This file is for HYBRID SOLUTION 1 FOR TESTING THE HPS-FPGA BRIDGE

# Compile the modules
vcom SIMON_CH_PACKET.vhd 
vcom Simon_CH_store.vhd 
vcom Simon_CH_Decrypt.vhd 
vcom Simon_CH_HPS.vhd
vcom Simon_CH_top.vhd
vcom Simon_CH_tb.vhd 


# Simulate the testbench
vsim work.Simon_CH_tb

# stop Arith warnings
set StdArithNoWarfnings 1y

# show complted in modelsim window
echo "HYBRID SOLUTION 1 HPS-FPGA BRIDGE SIMULATION"

# Set the waves 
add wave *
# Add only the necessary signals---------------------- 

# reset_n signal to allow the user to reset 
add wave -position insertpoint  \
sim:/simon_ch_tb/DUT/reset_n

# 64-bit array to store the keys
add wave -position insertpoint  \
sim:/simon_ch_tb/DUT/key_64bit

#64-bit array to store the data 
add wave -position insertpoint  \
sim:/simon_ch_tb/DUT/data_input

# the generated subkeys signal array 
#64-bit array to store the data 
add wave -position insertpoint  \
sim:/simon_ch_tb/DUT/subkeys 

#include the decrypted data 
add wave -position insertpoint  \
sim:/simon_ch_tb/DUT/x \
sim:/simon_ch_tb/DUT/y


# Run until the testbench completes the first test for 192-bit  
run 3200ns
