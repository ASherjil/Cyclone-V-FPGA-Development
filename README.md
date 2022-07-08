# Cyclone-V-FPGA-Development

This was a major project which was my coursework in third year Electrical Engineering. I achieved a mark of 88% for this effort.  

In this project, Simon Cipher algorithm is implemented in software and hardware. This was developed for the DE1-SoC. This SoC is composed of a HPS(ARM Cortex A9 800Mhz(dual core)) coupled with Intel/Altera Cyclone V FPGA. 

The Simon Cipher is a perticular block cipher which is specifically optimised for hardware. The HPS encrypted data then sent that data to the FPGA for decryption. Thus the name "Hybrid" Cryptography. The FPGA was programmed in VHDL, the HPS in C. Two hardware solutions were developed: one which prioritised performance and another which was a balanced solution. The results of these two solutions were compared. 
The FPGA was programmed using Intel Quartus Prime 21.1. 

The high level daigram below illustrates this point:

![Screenshot from 2022-07-08 22-16-13](https://user-images.githubusercontent.com/92602684/178071454-2b9b5ef1-91b2-488d-9926-ea96be9c13bb.png)


The HPS boots embedded Linux from the microSD card. A running example of the application can be seen here:

![Software_Application_test1](https://user-images.githubusercontent.com/92602684/178074944-7354f2dc-2668-48cd-863f-c767b398f402.png)
![Software_Application_test2](https://user-images.githubusercontent.com/92602684/178074951-4a3a07cc-0175-4223-a829-5588b7852b6e.png)

![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/areebTP/Cyclone-V-FPGA-Development)

# Installation & Usage 

Step 1: It is recommeneded to run embedded linux over RTOS or baremetal for this project. Linux image needs to be mounted on a microSD card. An in depth guide can be found here:

