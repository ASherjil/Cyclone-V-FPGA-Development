#include <stdio.h> // for printf
#include <stdlib.h>// for calloc(), free() dynamic memory allocation
#include <stdint.h> // for uin64_t 
#include "SIMON.h"

void packer();
void unpacker(int,uint64_t*);
void Simon_begin(int,uint64_t*,uint64_t*,int);


int main()
{
	packer();
	return 0;
}

void packer()
{
	const char string[] = { "1234567812345678123456781234567812345678" };
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

void Simon_begin(int size,uint64_t* packet,uint64_t* key,int key_length)
{
	uint64_t cipherText[2];
	uint64_t decryptedText[2];
	uint64_t text[2] = { 0,0 }; // data to be encrypted
	uint64_t* unpacked_encrypted = calloc((size+1), sizeof(*unpacked_encrypted)); // dynamically allocate memory
	uint64_t* unpacked_decrypted = calloc((size+1), sizeof(*unpacked_decrypted)); // dynamically allocate memory

	if (unpacked_encrypted == NULL)
	{
		printf("Memory allocation failure for unpacked encrypted array");
		free(unpacked_encrypted); // release the dynamically allocated memory
		//free(unpacked_decrypted); // release the dynamically allocated memory 
	}


	if (unpacked_decrypted == NULL)
	{
		printf("Memory allocation failure for unpacked decrypted array");
		//free(unpacked_encrypted); // release the dynamically allocated memory
		free(unpacked_decrypted); // release the dynamically allocated memory 
	}

	if ((!(size % 2))) // if size is a mutiple of 2 
	{
		for (size_t i = 0; i < size; i += 2)
		{
			text[0] = packet[i];
			text[1] = packet[i + 1];


			SimonContext context;
			SIMON_init(&context, key, key_length);
			SIMON_encrypt(&context, text, cipherText);

			unpacked_encrypted[i] = cipherText[0];
			unpacked_encrypted[i+1] = cipherText[1];

			SIMON_decrypt(&context, cipherText, decryptedText);

			unpacked_decrypted[i] = decryptedText[0];
			unpacked_decrypted[i + 1] = decryptedText[1];

			printf("key: \t\t\t\t");
			for (size_t i = 0; i < (key_length / 64); i++)
			{
				printf("%016llx ", key[i]);
			}
			printf("\n");


			printf("text: \t\t\t\t");
			for (size_t i = 0; i < 2; i++)
			{
				printf("%016llx ", text[i]);
			}
			printf("\n");

			printf("encrypted text: \t\t");
			for (size_t i = 0; i < 2; i++)
			{
				printf("%016llx ", cipherText[i]);
			}
			printf("\n");

			unpacker(2, cipherText);


			printf("decrypted text: \t\t");
			for (size_t i = 0; i < 2; i++)
			{
				printf("%016llx ", decryptedText[i]);
			}
			printf("\n");

			unpacker(2, decryptedText);
		}
		unpacker(size, unpacked_encrypted);
		unpacker(size, unpacked_decrypted);
	}
	else if (size < 2) // if size is than 2 
	{
		text[0] = packet[0];// assign packet 0 to text 0 and leave text 1 as zero 

		SimonContext context;
		SIMON_init(&context, key, key_length);
		SIMON_encrypt(&context, text, cipherText);
		SIMON_decrypt(&context, cipherText, decryptedText);

		printf("key: \t\t\t\t");
		for (size_t i = 0; i < (key_length / 64); i++)
		{
			printf("%016llx ", key[i]);
		}
		printf("\n");


		printf("text: \t\t\t\t");
		for (size_t i = 0; i < 2; i++)
		{
			printf("%016llx ", text[i]);
		}
		printf("\n");

		printf("encrypted text: \t\t");
		for (size_t i = 0; i < 2; i++)
		{
			printf("%016llx ", cipherText[i]);
		}
		printf("\n");

		unpacker(2, cipherText);


		printf("decrypted text: \t\t");
		for (size_t i = 0; i < 2; i++)
		{
			printf("%016llx ", decryptedText[i]);
		}
		printf("\n");

		unpacker(2, decryptedText);
	}
	else // if(size %2)  size of array is not a mutiple of 2 and larger than 2 
	{
		for (size_t i = 0; i < size; i += 2)
		{
			text[0] = packet[i];
			text[1] = packet[i + 1];


			SimonContext context;
			SIMON_init(&context, key, key_length);
			SIMON_encrypt(&context, text, cipherText);

			unpacked_encrypted[i] = cipherText[0];
			unpacked_encrypted[i + 1] = cipherText[1];

			SIMON_decrypt(&context, cipherText, decryptedText);

			unpacked_decrypted[i] = decryptedText[0];
			unpacked_decrypted[i + 1] = decryptedText[1];


			printf("key: \t\t\t\t");
			for (size_t i = 0; i < (key_length / 64); i++)
			{
				printf("%016llx ", key[i]);
			}
			printf("\n");


			printf("text: \t\t\t\t");
			for (size_t i = 0; i < 2; i++)
			{
				printf("%016llx ", text[i]);
			}
			printf("\n");

			printf("encrypted text: \t\t");
			for (size_t i = 0; i < 2; i++)
			{
				printf("%016llx ", cipherText[i]);
			}
			printf("\n");

			unpacker(2, cipherText);


			printf("decrypted text: \t\t");
			for (size_t i = 0; i < 2; i++)
			{
				printf("%016llx ", decryptedText[i]);
			}
			printf("\n");

			unpacker(2, decryptedText);

			if ((i + 2) == (size -1)) // check for the last odd number in the array 
			{
				text[0] = packet[i+2]; // assign last value of array 
				text[1] = 0; // make it zero 


				SimonContext context;
				SIMON_init(&context, key, key_length);
				SIMON_encrypt(&context, text, cipherText);
				
				unpacked_encrypted[i+2] = cipherText[0];
				unpacked_encrypted[i + 3] = cipherText[1];

				SIMON_decrypt(&context, cipherText, decryptedText);

				unpacked_decrypted[i+2] = decryptedText[0];
				unpacked_decrypted[i + 3] = decryptedText[1];


				printf("key: \t\t\t\t");
				for (size_t i = 0; i < (key_length / 64); i++)
				{
					printf("%016llx ", key[i]);
				}
				printf("\n");


				printf("text: \t\t\t\t");
				for (size_t i = 0; i < 2; i++)
				{
					printf("%016llx ", text[i]);
				}
				printf("\n");

				printf("encrypted text: \t\t");
				for (size_t i = 0; i < 2; i++)
				{
					printf("%016llx ", cipherText[i]);
				}
				printf("\n");

				unpacker(2, cipherText);


				printf("decrypted text: \t\t");
				for (size_t i = 0; i < 2; i++)
				{
					printf("%016llx ", decryptedText[i]);
				}
				printf("\n");

				unpacker(2, decryptedText);
				break; // break out of the for loop 
			}
		}
		unpacker(size + 1, unpacked_encrypted);
		unpacker(size+1, unpacked_decrypted);
	}

	free(unpacked_encrypted); // release the dynamically allocated memory
	free(unpacked_decrypted); // release the dynamically allocated memory 
}

void unpacker(int size,uint64_t* packet)
{
	char* unpacked = calloc(((size * 8)+1), sizeof(*unpacked)); // dynamically allocate memory
	uint64_t extracter = 0xFF;// used for ANDing data
	uint64_t chars = 0; // individual chars which is 8-bits
	size_t index = 0;// index to store unpacked data 

	for (size_t i = 0; i < size; ++i)
	{
		for (size_t j = 0; j < 8; ++j)
		{
			chars = packet[i] & (extracter << (j * 8)); // extract the packed chars from the 64-bit integer
		//	unpacked[index++] = static_cast<char>(chars >> (j*8));// convert integer back to char
			unpacked[index++] = (char)(chars >> (j * 8));// convert integer back to char
		}
	}
	//	std::cout << "Unpacked data: '" << unpacked<<"'\n";
	printf("Unpacked data:\t\t\t'%s'\n\n", unpacked); // print the unpacked integer 

	f
