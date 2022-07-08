# Cyclone-V-FPGA-Development

This was a major project which was my coursework in third year Electrical Engineering. 

In this project, Simon Cipher algorithm is implemented in software and hardware. This was developed for the DE1-SoC. This SoC is composed of a HPS(ARM Cortex A9 800Mhz(dual core)) coupled with Intel/Altera Cyclone V FPGA. 

The Simon Cipher is a perticular block cipher which is specifically optimised for hardware. The HPS encrypted data then sent that data to the FPGA for decryption. Thus the name "Hybrid" Cryptography. The FPGA was programmed in VHDL, the HPS in C. Two hardware solutions were developed: one which prioritised performance and another which was a balanced solution. The results of these two solutions were compared. 
The FPGA was programmed using Intel Quartus Prime 21.1. 

The high level daigram below illustrates this point:

![Screenshot from 2022-07-08 22-16-13](https://user-images.githubusercontent.com/92602684/178071454-2b9b5ef1-91b2-488d-9926-ea96be9c13bb.png)


The HPS boots embedded Linux from the microSD card. 
