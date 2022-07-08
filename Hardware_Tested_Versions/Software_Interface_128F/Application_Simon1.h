/* Application_Simon1.h
 * Author: Vinicius Borba da Rocha
 * Created: 09/08/2021
 * Author 2 : STUDENT ID B820928
 */

// This header file is application layer1 and only contains encrypting+decrypting 
// funtions 
#pragma once

#include <stdio.h> // for printf
#include <stdlib.h>// for calloc(), free() dynamic memory allocation
#include <stdint.h> // for uin64_t, integer widths 

typedef struct // struct used for initialising the SIMON Algorithm 
{
	uint8_t nrSubkeys;
	uint64_t subkeys[72];
} SimonContext;

/*
	Function : SIMON_init
	Purpose : Initialises the Simon Algorithm
	Arguments: pointer to SimonContext struct, pointer to uin64_t integer key, integer key length. 
	Return values: void
*/
void SIMON_init(SimonContext* context, uint64_t* key, uint16_t keyLen);

/*
	Function : SIMON_encrypt
	Purpose : Encrypts text and outputs the encrypted text.
	Arguments: pointer to SimonContext struct, pointer to uin64_t integer text,
	pointer to uint64_t integer encrypted text.
	Return values: void
*/
void SIMON_encrypt(SimonContext* context, uint64_t* block, uint64_t* out);

/*
	Function : SIMON_decrypt
	Purpose : Decrypts text and outputs the decrypted text.
	Arguments: pointer to SimonContext struct, pointer to uin64_t integer encrypted text,
	pointer to uint64_t integer decrypted text.
	Return values: void
*/
void SIMON_decrypt(SimonContext* context, uint64_t* block, uint64_t* out);

/*
	Function : Simon_begin 
	Purpose : Encrypts and decrypts data based on the key and key length(helper function). 
	Arguments: int(size of packed data array),pointer to uint64_t data array,
	pointer to uint64_t key, int(length of key).
	Return values: void
*/
void Simon_begin(int, uint64_t*, uint64_t*, int);

/*
	Function : Simon_EncDec
	Purpose : Used as a helper function for Simon_begin, to be used in a for loop 
	Arguments: pointer to SimonContext struct, pointer to uint64_t text, pointer
	to uint64_t decrypted data, pointer to uint64_t encrypted data,
	pointer to uint64_t key, int(length of key), size_t(integer loop iteration number).
	Return values: void
*/
void Simon_EncDec(SimonContext*,uint64_t*,uint64_t*,uint64_t*,uint64_t*,int,size_t);


/*
	Function : SIMON_main
	Purpose : This is the MAIN function that came with the sample code, used to 
	begin the algorithm(not used in this application). 
	Arguments: none.
	Return values: void
*/
void SIMON_main(void);



/*
	Function : FPGA_decrypt
	Purpose : Function that decrypts data using keys and ecrypted data
	Arguments: pointer to uint64_t key, pointer to uint64_t encrypted data,pointer
	to uint64_t decrypted data
	Return values: int(but the return value is not used, only for correct syntax)
*/
int FPGA_decrypt(uint64_t*,uint64_t*,uint64_t*);
