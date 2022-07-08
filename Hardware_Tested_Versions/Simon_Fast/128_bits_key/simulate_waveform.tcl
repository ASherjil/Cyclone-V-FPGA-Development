# This is the .tcl script for producing a wave upto a specific time. 
# Once the Questasim project is opened, running this .tcl script will add
# the necessary signals and generate the required waveform. 

# This file is for PERFORMANCE BASED SOLUTION FOR TESTING THE HPS-FPGA BRIDGE

# Compile the modules
vcom SIMON_PACKET_128.vhd 
vcom Simon_128_HPS.vhd 
vcom Simon_keys_128.vhd 
vcom Simon_Decrypt_128.vhd
vcom Simon_128H_top.vhd
vcom simon_128H_tb.vhd 


# Simulate the testbench
vsim work.simon_128H_tb

# stop Arith warnings
set StdArithNoWarfnings 1y

# show complted in modelsim window
echo "PERFORMANCE BASED SOLUTION FOR 128-BIT KEY LENGTH HPS-FPGA BRIDGE"

# Set the waves 
add wave *
# Add only the necessary signals---------------------- 
# 64-bit array for data and keys, final decrypted data, subkeys array 
add wave -position insertpoint  \
sim:/simon_128h_tb/DUT/subkeys

add wave -position insertpoint  \
sim:/simon_128h_tb/DUT/data_input \
sim:/simon_128h_tb/DUT/key_64bit \
sim:/simon_128h_tb/DUT/x_dec_final \
sim:/simon_128h_tb/DUT/y_dec_final

# ------------------------------------------------------------------
# Run the entire testbench, test for two keys   
run 900ns
