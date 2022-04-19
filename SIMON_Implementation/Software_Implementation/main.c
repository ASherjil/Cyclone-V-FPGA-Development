#include <stdio.h> // for printf
#include <stdlib.h>// for calloc(), free() dynamic memory allocation
#include <stdint.h> // for uin64_t 
#include "SIMON.h"

void packer();


int main()
{
	packer();
	return 0;
}

void packer()
{
	const char string[] = { "This is a test run."};
	int length = (sizeof(string) / sizeof(string[0])) - 1; // length of string without null termination
	int size = (length % 8) ? ((length / 8) + 1) : (length / 8); // size of array required 

	//uint64_t packet[size]; // store packed chars from string into 64-bit integer
	uint64_t* packet = calloc(size, sizeof(*packet)); // dynamically allocate memory
	uint64_t chars = 0; // individual chars which is 8-bits

	for (size_t i = 0; i < size; ++i) // pack the string into integer array 
	{
		for (size_t j = (i * 8); (j < 8 * (i + 1)) && (string[j] != '\0'); ++j)
		{
			chars = (string[j] & 0xFF);// AND with 255 to extract 8-bit value 
			packet[j / 8] |= (chars << ((j - ((j / 8) * 8)) * 8)); // shift the bits left by 0-7
		}
	}

	//	std::cout << "'" << string << "' is packed to give: \n";
	printf("'%s' is packed to give: \n", string);
	for (size_t i = 0; i < size; ++i)
	{
		//		std::cout << i << "- " << packet[i] << "\n";
		printf("%d- %016llx\n", (i + 1), packet[i]);
	}

	printf("\n128-bit key Test-----------------------------------------------\n");
	
	uint64_t key[2] = { 0x0f0e0d0c0b0a0908 ,0x0706050403020100 }; // 128-bit Key

	Simon_begin(size, packet,key,128);// encrypt data using 128-bit key
	
	printf("\n192-bit key Test-----------------------------------------------\n");

	uint64_t key2[3]; // 192-bit key 
	key2[0] = 0x1716151413121110;
	key2[1] = 0x0f0e0d0c0b0a0908;
	key2[2] = 0x0706050403020100;

	Simon_begin(size, packet, key2, 192);// encrypt data using 192-bit key

	free(packet);// release the dynamically allocated memory 
}
