/* SIMON.h
*
 * Author: Vinicius Borba da Rocha
 * Created: 09/08/2021
 *
 */
#pragma once

#include <stdio.h>
#include <stdint.h>
#include "Device_Driver1.h"// include the device driver for FPGA functions 

typedef struct
{
	uint8_t nrSubkeys;
	uint64_t subkeys[72];
} SimonContext;

void SIMON_init(SimonContext* context, uint64_t* key, uint16_t keyLen);
void SIMON_encrypt(SimonContext* context, uint64_t* block, uint64_t* out);
void SIMON_decrypt(SimonContext* context, uint64_t* block, uint64_t* out);


//------------------------------------------------FPGA Interfacing function
int FPGA_decrypt(uint64_t*,uint64_t*,uint64_t*,int);
