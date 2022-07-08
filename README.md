# Cyclone-V-FPGA-Development

This was a major project which was my coursework in third year Electrical Engineering. 

In this project, Simon Cipher algorithm is implemented in software and hardware. This was developed for the DE1-SoC. This SoC is composed of a HPS(ARM Cortex A9 800Mhz(dual core)) coupled with Intel/Altera Cyclone V FPGA. 

The Simon Cipher is a perticular block cipher which is specifically optimised for hardware. The HPS encrypted data then sent that data to the FPGA for decryption. Thus the name "Hybrid" Cryptography. The FPGA was programmed in VHDL, the HPS in C. Two hardware solutions were developed: one which prioritised performance and another which was a balanced solution. The results of these two solutions were compared. 
The FPGA was programmed using Intel Quartus Prime 21.1. 

