/* SIMON.h
*
 * Author: Vinicius Borba da Rocha
 * Created: 09/08/2021
 *
 */
#pragma once

#define _GNU_SOURCE
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include "address_map_arm.h"
#define COUNT_BASE 0x0


typedef struct
{
	uint8_t nrSubkeys;
	uint64_t subkeys[72];
} SimonContext;

void SIMON_init(SimonContext* context, uint64_t* key, uint16_t keyLen);
void SIMON_encrypt(SimonContext* context, uint64_t* block, uint64_t* out);
void SIMON_decrypt(SimonContext* context, uint64_t* block, uint64_t* out);

//------------------------------------------------FPGA Interfacing functions
int FPGA_decrypt(uint64_t*,uint64_t*,uint64_t*);
//-----------------------------------------------linux kernal functions----
int open_physical(int);
void* map_physical(int, unsigned int, unsigned int);
void close_physical(int);
int unmap_physical(void*, unsigned int);
//--------------------------------------------------------------------------

void SIMON_main(void);
