# Cyclone-V-FPGA-Development

This was a major project which was my coursework in third year Electrical Engineering. I achieved a mark of 86% for this effort.  

In this project, Simon Cipher algorithm is implemented in software and hardware. This was developed for the DE1-SoC. This SoC is composed of a HPS(ARM Cortex A9 800Mhz(dual core)) coupled with Intel/Altera Cyclone V FPGA. 

The Simon Cipher is a perticular block cipher which is specifically optimised for hardware. The HPS encrypted data then sent that data to the FPGA for decryption. Thus the name "Hybrid" Cryptography. The FPGA was programmed in VHDL, the HPS in C. Two hardware solutions were developed: one which prioritised performance and another which was a balanced solution. The results of these two solutions were compared. 
The FPGA was programmed using Intel Quartus Prime 21.1. 

The high level daigram below illustrates this point:

![Screenshot from 2022-07-08 22-16-13](https://user-images.githubusercontent.com/92602684/178071454-2b9b5ef1-91b2-488d-9926-ea96be9c13bb.png)


The HPS boots embedded Linux from the microSD card. A running example of the application can be seen here:

![Software_Application_test1](https://user-images.githubusercontent.com/92602684/178074944-7354f2dc-2668-48cd-863f-c767b398f402.png)
![Software_Application_test2](https://user-images.githubusercontent.com/92602684/178074951-4a3a07cc-0175-4223-a829-5588b7852b6e.png)

The full report can be found in the file named "Hybrid Cryptography on the DE1-SoC Report.pdf"

![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/areebTP/Cyclone-V-FPGA-Development)

# Installation & Usage 

Step 1: It is recommeneded to run embedded linux over RTOS or baremetal for this project. Linux image needs to be mounted on a microSD card. An in depth guide can be found here:

https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/17.0/Tutorials/Linux_On_DE_Series_Boards.pdf

Step 2: Download and install Intel Quartus Prime(any edition). Then open the golden hardware reference design(GHRD) and follow the steps provided in the pdf file. 
The files for GHRD and pdf instructions are password protected. The password can be found in the "Installation_Instructions" folder. 

Step 3: Synthesize the VHDL component and use the programmer to upload the bitstream to the FPGA. 

Step 4: Run the "main.c" file in the Software Interface Folder of the perticular solution. The folder also contains "COMPILE_ME.txt" file which contains the linux terminial commands for quick compilation and run. 

Find files "Hardware_Tested_Versions" -> Software Interface

Step 5: Enjoy!

# Other Interesting Project I worked on 

Another interesting project I worked on was creating a GUI polynomial long division calculator using C++17 with the Qt framework. Check it out:

[https://github.com/areebTP/Polynomial_Long_Division_GUI](https://github.com/ASherjil/Polynomial_Long_Division_GUI)https://github.com/ASherjil/Polynomial_Long_Division_GUI
