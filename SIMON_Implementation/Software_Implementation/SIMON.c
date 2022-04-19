/* SIMON.c
*
 * Author: Vinicius Borba da Rocha
 * Created: 09/08/2021
 *
 * Implementation of the SIMON block cipher with
 * 128 bits block length and 128/192/256 bits key length.
 *
 * This code follows a specification:
 *		- https://eprint.iacr.org/2013/404.pdf
 *
 * and uses other codebases as references:
 *		- https://github.com/nsacyber/simon-speck-supercop/blob/master/crypto_stream/simon128128ctr/ref/stream.c
 *
 */
#include <stdio.h> // for printf
#include <stdlib.h>// for calloc(), free() dynamic memory allocation
#include <stdint.h> // for uin64_t 
#include "SIMON.h"

// Rotate Left circular shift 32 bits
static uint64_t ROL_64(uint64_t x, uint32_t n)
{
	return x << n | x >> (64 - n);
}

// Rotate Right circular shift 32 bits
static uint64_t ROR_64(uint64_t x, uint32_t n)
{
	return x >> n | x << (64 - n);
}

static uint64_t f(uint64_t x)
{
	return (ROL_64(x, 1) & ROL_64(x, 8)) ^ ROL_64(x, 2);
}

static void R2(uint64_t* x, uint64_t* y, uint64_t k, uint64_t l)
{
	*y ^= f(*x);
	*y ^= k;
	*x ^= f(*y);
	*x ^= l;
}

void SIMON_init(SimonContext* context, uint64_t* key, uint16_t keyLen)
{
	uint64_t c = 0xfffffffffffffffcLL;
	uint64_t z;
	uint64_t i;

	if (keyLen == 128)
	{
		context->nrSubkeys = 68;

		z = 0x7369f885192c0ef5LL;

		context->subkeys[0] = key[1];
		context->subkeys[1] = key[0];

		for (i = 2; i < 66; i++)
		{
			context->subkeys[i] = c ^ (z & 1) ^ context->subkeys[i - 2] ^ ROR_64(context->subkeys[i - 1], 3) ^ ROR_64(context->subkeys[i - 1], 4);
			z >>= 1;
		}

		context->subkeys[66] = c ^ 1 ^ context->subkeys[64] ^ ROR_64(context->subkeys[65], 3) ^ ROR_64(context->subkeys[65], 4);
		context->subkeys[67] = c ^ context->subkeys[65] ^ ROR_64(context->subkeys[66], 3) ^ ROR_64(context->subkeys[66], 4);
	}
	else if (keyLen == 192)
	{
		context->nrSubkeys = 69;

		z = 0xfc2ce51207a635dbLL;

		context->subkeys[0] = key[2];
		context->subkeys[1] = key[1];
		context->subkeys[2] = key[0];

		for (i = 3; i < 67; i++)
		{
			context->subkeys[i] = c ^ (z & 1) ^ context->subkeys[i - 3] ^ ROR_64(context->subkeys[i - 1], 3) ^ ROR_64(context->subkeys[i - 1], 4);
			z >>= 1;
		}

		context->subkeys[67] = c ^ context->subkeys[64] ^ ROR_64(context->subkeys[66], 3) ^ ROR_64(context->subkeys[66], 4);
		context->subkeys[68] = c ^ 1 ^ context->subkeys[65] ^ ROR_64(context->subkeys[67], 3) ^ ROR_64(context->subkeys[67], 4);
	}
	else // 256
	{
		context->nrSubkeys = 72;

		z = 0xfdc94c3a046d678bLL;

		context->subkeys[0] = key[3];
		context->subkeys[1] = key[2];
		context->subkeys[2] = key[1];
		context->subkeys[3] = key[0];

		for (i = 4; i < 68; i++)
		{
			context->subkeys[i] = c ^ (z & 1) ^ context->subkeys[i - 4] ^ ROR_64(context->subkeys[i - 1], 3) ^ context->subkeys[i - 3] ^ ROR_64(context->subkeys[i - 1], 4) ^ ROR_64(context->subkeys[i - 3], 1);
			z >>= 1;
		}

		context->subkeys[68] = c ^ context->subkeys[64] ^ ROR_64(context->subkeys[67], 3) ^ context->subkeys[65] ^ ROR_64(context->subkeys[67], 4) ^ ROR_64(context->subkeys[65], 1);
		context->subkeys[69] = c ^ 1 ^ context->subkeys[65] ^ ROR_64(context->subkeys[68], 3) ^ context->subkeys[66] ^ ROR_64(context->subkeys[68], 4) ^ ROR_64(context->subkeys[66], 1);
		context->subkeys[70] = c ^ context->subkeys[66] ^ ROR_64(context->subkeys[69], 3) ^ context->subkeys[67] ^ ROR_64(context->subkeys[69], 4) ^ ROR_64(context->subkeys[67], 1);
		context->subkeys[71] = c ^ context->subkeys[67] ^ ROR_64(context->subkeys[70], 3) ^ context->subkeys[68] ^ ROR_64(context->subkeys[70], 4) ^ ROR_64(context->subkeys[68], 1);
	}
}

void SIMON_encrypt(SimonContext* context, uint64_t* block, uint64_t* out)
{
	uint8_t i;
	uint64_t x = block[0];
	uint64_t y = block[1];
	uint64_t t;

	if (context->nrSubkeys == 69)
	{
		for (i = 0; i < 68; i += 2)
		{
			R2(&x, &y, context->subkeys[i], context->subkeys[i + 1]);
		}
			
		y ^= f(x);
		y ^= context->subkeys[68];
		t = x;
		x = y;
		y = t;
	}
	else
	{
		for (i = 0; i < context->nrSubkeys; i += 2)
		{
			R2(&x, &y, context->subkeys[i], context->subkeys[i + 1]);
		}
	}

	out[0] = x;
	out[1] = y;
}

void SIMON_decrypt(SimonContext* context, uint64_t* block, uint64_t* out)
{
	int i;
	uint64_t x = block[0];
	uint64_t y = block[1];
	uint64_t t;

	if (context->nrSubkeys == 69)
	{
		t = y;
		y = x;
		x = t;
		y ^= context->subkeys[68];
		y ^= f(x);

		for (i = 67; i >= 0; i -= 2)
		{
			R2(&y, &x, context->subkeys[i], context->subkeys[i - 1]);
		}
	}
	else
	{
		for (i = context->nrSubkeys - 1; i >= 0; i -= 2)
		{
			R2(&y, &x, context->subkeys[i], context->subkeys[i - 1]);
		}
	}

	out[0] = x;
	out[1] = y;
}

void SIMON_main(void)
{
	SimonContext context;
	int i;
	uint64_t key[4];
	uint64_t text[2];
	uint64_t cipherText[2];
	uint64_t expectedCipherText[2];
	uint64_t decryptedText[2];

	// test for 128-bits key

	// key 0f0e0d0c0b0a0908 0706050403020100
	key[0] = 0x0f0e0d0c0b0a0908;
	key[1] = 0x0706050403020100;

	// text 6373656420737265 6c6c657661727420
	text[0] = 0x6373656420737265;
	text[1] = 0x6c6c657661727420;

	// expected encrypted text 49681b1e1e54fe3f 65aa832af84e0bbc
	expectedCipherText[0] = 0x49681b1e1e54fe3f;
	expectedCipherText[1] = 0x65aa832af84e0bbc;

	SIMON_init(&context, key, 128);

	SIMON_encrypt(&context, text, cipherText);
	SIMON_decrypt(&context, cipherText, decryptedText);

	printf("\nSIMON 128-bits key \n\n");

	printf("key: \t\t\t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", key[i]);
	}
	printf("\n");

	printf("text: \t\t\t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", text[i]);
	}
	printf("\n");

	printf("encrypted text: \t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", cipherText[i]);
	}
	printf("\n");

	printf("expected encrypted text: \t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", expectedCipherText[i]);
	}
	printf("\n");

	printf("decrypted text: \t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", decryptedText[i]);
	}
	printf("\n");

	// *** 192-bits key test ***

	// key 1716151413121110 0f0e0d0c0b0a0908 0706050403020100
	key[0] = 0x1716151413121110;
	key[1] = 0x0f0e0d0c0b0a0908;
	key[2] = 0x0706050403020100;

	// text 206572656874206e 6568772065626972
	text[0] = 0x206572656874206e;
	text[1] = 0x6568772065626972;

	// expected encrypted text c4ac61effcdc0d4f 6c9c8d6e2597b85b
	expectedCipherText[0] = 0xc4ac61effcdc0d4f;
	expectedCipherText[1] = 0x6c9c8d6e2597b85b;

	SIMON_init(&context, key, 192);

	SIMON_encrypt(&context, text, cipherText);
	SIMON_decrypt(&context, cipherText, decryptedText);

	printf("\nSIMON 192-bits key \n\n");

	printf("key: \t\t\t\t");
	for (i = 0; i < 3; i++)
	{
		printf("%016llx ", key[i]);
	}
	printf("\n");

	printf("text: \t\t\t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", text[i]);
	}
	printf("\n");

	printf("encrypted text: \t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", cipherText[i]);
	}
	printf("\n");

	printf("expected encrypted text: \t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", expectedCipherText[i]);
	}
	printf("\n");

	printf("decrypted text: \t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", decryptedText[i]);
	}
	printf("\n");

	// *** 256-bits key test ***

	// key  1f1e1d1c1b1a1918 1716151413121110 0f0e0d0c0b0a0908 0706050403020100
	key[0] = 0x1f1e1d1c1b1a1918;
	key[1] = 0x1716151413121110;
	key[2] = 0x0f0e0d0c0b0a0908;
	key[3] = 0x0706050403020100;

	// text 74206e69206d6f6f 6d69732061207369
	text[0] = 0x74206e69206d6f6f;
	text[1] = 0x6d69732061207369;

	// expected encrypted text 8d2b5579afc8a3a0 3bf72a87efe7b868
	expectedCipherText[0] = 0x8d2b5579afc8a3a0;
	expectedCipherText[1] = 0x3bf72a87efe7b868;

	SIMON_init(&context, key, 256);

	SIMON_encrypt(&context, text, cipherText);
	SIMON_decrypt(&context, cipherText, decryptedText);

	printf("\nSIMON 256-bits key \n\n");

	printf("key: \t\t\t\t");
	for (i = 0; i < 4; i++)
	{
		printf("%016llx ", key[i]);
	}
	printf("\n");

	printf("text: \t\t\t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", text[i]);
	}
	printf("\n");

	printf("encrypted text: \t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", cipherText[i]);
	}
	printf("\n");

	printf("expected encrypted text: \t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", expectedCipherText[i]);
	}
	printf("\n");

	printf("decrypted text: \t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", decryptedText[i]);
	}
	printf("\n");
}

void Simon_begin(int size, uint64_t* packet, uint64_t* key, int key_length)
{
	uint64_t cipherText[2];
	uint64_t decryptedText[2];
	uint64_t text[2] = { 0,0 }; // data to be encrypted
	uint64_t* unpacked_encrypted = calloc(size+1 , sizeof(*unpacked_encrypted)); // dynamically allocate memory
	uint64_t* unpacked_decrypted = calloc(size+1 , sizeof(*unpacked_decrypted)); // dynamically allocate memory

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

			//unpacker(2, cipherText);


			printf("decrypted text: \t\t");
			for (size_t i = 0; i < 2; i++)
			{
				printf("%016llx ", decryptedText[i]);
			}
			printf("\n");

			unpacker(2, decryptedText);
		}
		//unpacker(size, unpacked_encrypted);
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

		//unpacker(2, cipherText);


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

			//unpacker(2, cipherText);


			printf("decrypted text: \t\t");
			for (size_t i = 0; i < 2; i++)
			{
				printf("%016llx ", decryptedText[i]);
			}
			printf("\n");

			unpacker(2, decryptedText);

			if ((i + 2) == (size - 1)) // check for the last odd number in the array 
			{
				text[0] = packet[i + 2]; // assign last value of array 
				text[1] = 0; // make it zero 


				SimonContext context;
				SIMON_init(&context, key, key_length);
				SIMON_encrypt(&context, text, cipherText);

				unpacked_encrypted[i + 2] = cipherText[0];
				//unpacked_encrypted[i + 3] = cipherText[1];

				SIMON_decrypt(&context, cipherText, decryptedText);

				unpacked_decrypted[i + 2] = decryptedText[0];
				//unpacked_decrypted[i + 3] = decryptedText[1];


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

				//unpacker(2, cipherText);


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
		//unpacker(size, unpacked_encrypted);
		unpacker(size, unpacked_decrypted);
	}

	free(unpacked_encrypted); // release the dynamically allocated memory
	free(unpacked_decrypted); // release the dynamically allocated memory 
}

void unpacker(int size, uint64_t* packet)
{
	char* unpacked = calloc(((size * 8) + 1), sizeof(*unpacked)); // dynamically allocate memory
	uint64_t extracter = 0xFFu;// used for ANDing data
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

	free(unpacked); // release dynamically allocated memory
}