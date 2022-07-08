# This is the .tcl script for producing a wave upto a specific time. 
# Once the Questasim project is opened, running this .tcl script will add
# the necessary signals and generate the required waveform. 

# This file is for PERFORMANCE BASED SOLUTION FOR TESTING THE HPS-FPGA BRIDGE

# Compile the modules
vcom SIMON_PACKET.vhd 
vcom Simon_192_HPS.vhd 
vcom Simon_keys_192.vhd 
vcom Simon_Dec192.vhd
vcom Simon_192_topH.vhd
vcom Simon_192H_tb.vhd 


# Simulate the testbench
vsim work.Simon_192H_tb

# stop Arith warnings
set StdArithNoWarfnings 1y

# show complted in modelsim window
echo "PERFORMANCE BASED SOLUTION FOR 192-BIT KEY LENGTH HPS-FPGA BRIDGE"

# Set the waves 
add wave *
# Add only the necessary signals---------------------- 
# 64-bit array for data and keys, final decrypted data, subkeys array 
add wave -position insertpoint  \
sim:/simon_192h_tb/DUT/subkeys

add wave -position insertpoint  \
sim:/simon_192h_tb/DUT/data_input \
sim:/simon_192h_tb/DUT/key_64bit \
sim:/simon_192h_tb/DUT/x_dec_final \
sim:/simon_192h_tb/DUT/y_dec_final

# ------------------------------------------------------------------
# Run the entire testbench, test for two keys   
run 900ns
