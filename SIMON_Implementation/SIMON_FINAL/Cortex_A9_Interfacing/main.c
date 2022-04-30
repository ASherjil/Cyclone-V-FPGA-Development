#include "SIMON.h"



int main()
{
	SimonContext context;
	int i;
	uint64_t key[3];
	uint64_t text[2];
	uint64_t cipherText[2];
	uint64_t decryptedText[2] = {0,0};

	// *** 192-bits key test ***

	key[0] = 0x1235484984325688;
	key[1] = 0xBEEFBEEFBEEFBEEF;
	key[2] = 0x0123456789ABCDEF;

	// text 6373656420737265 6c6c657661727420
	text[0] = 0x01234567A5A5A5A5;
	text[1] = 0x5A5A5A5AFEDCBA98;


	SIMON_init(&context, key, 192);// initialise keys for encryption 
	SIMON_encrypt(&context, text, cipherText);// encrypt data using embedded processor 
	FPGA_decrypt(key,cipherText,decryptedText,192); // decrypt data using the FPGA 

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


	printf("decrypted text: \t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", decryptedText[i]);
	}
	printf("\n");
	
	SIMON_init(&context, key, 128);// initialise keys for encryption 
	SIMON_encrypt(&context, text, cipherText);// encrypt data using embedded processor 
	FPGA_decrypt(key,cipherText,decryptedText,128); // decrypt data using the FPGA 
	
	
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


	printf("decrypted text: \t\t");
	for (i = 0; i < 2; i++)
	{
		printf("%016llx ", decryptedText[i]);
	}
	printf("\n");


	return 0;
}