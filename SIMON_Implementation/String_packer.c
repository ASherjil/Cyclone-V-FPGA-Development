//#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main()
{
  const char string[] = { "Zelis gave me an idea" };
	int length = (sizeof(string) / sizeof(string[0]))-1; // length of string without null termination
	int size = (length % 8) ? ((length / 8) + 1) : (length / 8); // size of array required 

	//uint64_t packet[size]; // store packed chars from string into 64-bit integer
	uint64_t* packet = calloc(size , sizeof(*packet)); // dynamically allocate memory
	uint64_t chars = 0; // individual chars which is 8-bits

	for (size_t i = 0; i < size; ++i) // pack the string into integer array 
	{
		for (size_t j = (i*8); (j < 8*(i+1)) && (string[j] != '\0'); ++j)
		{
			chars = (string[j] & 0xFF);// AND with 255 to extract 8-bit value 
			packet[j / 8] |= (chars << ((j - ((j / 8) * 8)) * 8)); // shift the bits left by 0-7
		}
	}

//	std::cout << "'" << string << "' is packed to give: \n";
	printf("'%s' is packed to give: \n",string);
	for (size_t i = 0; i < size; ++i)
	{
//		std::cout << i << "- " << packet[i] << "\n";
		printf("%lu- %lu\n",i+1,packet[i]);
	}

	char* unpacked = calloc((size*8), sizeof(*unpacked)); // dynamically allocate memory 
	uint64_t extracter = 0xFF;// used for ANDing data
	size_t index = 0;// index to store unpacked data 

	for (size_t i = 0; i < size; ++i)
	{
		for (size_t j = 0; j < 8; ++j)
		{
			chars = packet[i] &  (extracter << (j*8)); // extract the packed chars from the 64-bit integer
		//	unpacked[index++] = static_cast<char>(chars >> (j*8));// convert integer back to char
		    unpacked[index++] = (char)(chars >> (j*8));// convert integer back to char
		}
	}

//	std::cout << "Unpacked data: '" << unpacked<<"'\n";
    printf("Unpacked data: '%s'\n",unpacked);
	
	free(unpacked); // release dynamically allocated memory
	free(packet); // release dynamically allocated memory
}
