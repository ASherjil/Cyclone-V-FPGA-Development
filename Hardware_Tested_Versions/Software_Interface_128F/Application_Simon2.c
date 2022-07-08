#include "Application_Simon2.h"
#include "Application_Simon1.h"

/*
	Function : packer
	Purpose : This is the MAIN function that begins the string packing algorithm.
	Arguments: pointer to char(C-style string), int(size of the array).
	Return values: void
	Algorithm: Dynamically allocates a uint64_t array depending on the 
	length of string passed in. Each char in the string is AND with 
	0xFF(255) to extract the char. Since only 8 chars fit 64-bit,
	the subsequent element of the arrays are used to store the 
	next set of chars. Once packed, the 64-bit integers are encrypted and 
	decrypted using the Simon algorithm. 
*/
void packer(const char* string, int length)
{
	int size = (length % 8) ? ((length / 8) + 1) : (length / 8); // size of array required 

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

	printf("'%s' is packed to give: \n", string);
	for (size_t i = 0; i < size; ++i)
	{
		printf("%d- %016llx\n", (i + 1), packet[i]);
	}


	printf("\n128-bit key Test-----------------------------------------------\n");

	uint64_t key2[2]; // 128-bit key 
	key2[0] = 0x1716151413121110;
	key2[1] = 0x0f0e0d0c0b0a0908;

	Simon_begin(size, packet, key2,128);// encrypt data using 192-bit key

	free(packet);// release the dynamically allocated memory 
}


/*
	Function : unpacker
	Purpose : Unpacks an array of 64-bit integers,
	extracts chars and prints them(helper function).
	Arguments: int (size of the array), pointer to the array uint64_t of data.
	Return values: void
	Algorithm: Since each char is 8-bit, the 64-bit integer is 
	AND with 255(or 0xFF), then it is AND with ((0xFF)<<8)
	to extract the next 8-bits this continues untill all the 
	8-bits are extracted. 
	There are 8 chars in one 64-bit integer, they are
	stored in a char array which has its index
	incremented by each iteration of the for loop.
*/
void unpacker(int size, uint64_t* packet)
{
	char* unpacked = calloc(((size * 8) + 1), sizeof(*unpacked)); // dynamically allocate memory
	uint64_t extracter = 0xFFu;// used for ANDing data
	uint64_t chars = 0; // individual chars which is 8-bits
	size_t index = 0;// index to store unpacked data 

	for (size_t i = 0; i < size; ++i) // for loop only runs as times as the size of the array
	{
		for (size_t j = 0; j < 8; ++j)// run 8 times since each char is 8-bit,64/8 =8 
		{
			chars = packet[i] & (extracter << (j * 8)); // extract the packed chars from the 64-bit integer
			unpacked[index++] = (char)(chars >> (j * 8));// convert integer back to char
		}
	}
	printf("Unpacked data:\t\t\t'%s'\n\n", unpacked); // print the unpacked integer 
	free(unpacked); // release dynamically allocated memory
}

/*
	Function : inputString
	Purpose : This function is used to take a string from the user of an
	unknown length
	Arguments: pointer to FILE struct, size_t initial length of string
	Return values: pointer to the first element of string
*/
char* inputString(FILE* fp, size_t size) {
	//The size is extended by the input with the value of the provisional
	char* str;
	int ch;
	size_t len = 0;
	str = realloc(NULL, sizeof(*str) * size);//size is start size
	if (!str)return str;
	while (EOF != (ch = fgetc(fp)) && ch != '*') {
		str[len++] = ch;
		if (len == size) {
			str = realloc(str, sizeof(*str) * (size += 16));
			if (!str)return str;
		}
	}
	str[len++] = '\0';

	return realloc(str, sizeof(*str) * len);
}

/*
	Function : fibon_begin
	Purpose : This function generates fibonacci numbers upto a limit
	specified by the user, then encrypts/ decrypts them.
	Arguments: none 
	Return values: none
*/
void fibon_begin()
{
	int limit = 0;

	printf("Please enter limit of fibonacci sequence(must be greater than 2).\n");
	scanf("%d", &limit);

	uint64_t* fibonacci = calloc(limit, sizeof(*fibonacci));// allocate array 

	fibonacci[0] = 0;
	fibonacci[1] = 1; // first 2 terms of fibonacci sequence 

	for (size_t i = 2; i < limit; ++i) // only generate until the limit 
	{
		fibonacci[i] = fibonacci[i - 1] + fibonacci[i - 2];// generate fibonacci 
	}

	size_t perline = 0;// counter to store perline data 
	printf("Fibonacci sequence is shown below:\n");
	for (size_t i = 0; i < limit; ++i)
	{
		if (perline == 5)// print only 5 per line
		{
			printf("\n");
			perline = 0;//reset 
		}
		printf("{'%lld'}", fibonacci[i]);
		++perline; // increase perline variable 
	}
	printf("\n\n"); // add gap 

	uint64_t key[3]; // set keys 
	key[0] = 0x1716151413121110;
	key[1] = 0x0f0e0d0c0b0a0908;
	key[2] = 0x0706050403020100;

	fibon_EncDec(fibonacci,key, limit, 128); // encrypt/decrypt using 128-bit keys

	free(fibonacci); // free the fibonacci array 
}

/*
	Function : fibon_EncDec
	Purpose : This is a helper function for fibon_begin()
	it encrypts and decrypts fibocci numbers
	Arguments: pointer to fibonacci array,
	pointer to keys array, limit of fiboacci numbers,
	length of keys(128 or 192)
	Return values: none
*/
void fibon_EncDec(uint64_t* fibonacci,uint64_t* key, int limit,int key_length)
{
	uint64_t* encrypted = calloc(limit+1, sizeof(*encrypted));// allocate array for encrypted
	uint64_t* decrypted = calloc(limit+1, sizeof(*encrypted));// allocate array for decrypted 

	SimonContext context;
	SIMON_init(&context, key, key_length); // begin generating keys 

	uint64_t text[2] = { 0,0 }; // data to be encrypted
	uint64_t cipherText[2];
	uint64_t decryptedText[2]; // store 2 of encrypted/decrypted text 

	if ((limit % 2) == 0)// if the fibanocci limit is a multiple of 2
	{
		for (size_t i = 0; i < limit; i += 2)
		{
			text[0] = fibonacci[i];
			text[1] = fibonacci[i+1];

			SIMON_encrypt(&context, text, cipherText);// encrypt data
			encrypted[i] = cipherText[0];
			encrypted[i + 1] = cipherText[1]; // store the encrypted data in array 
			FPGA_decrypt(key,cipherText,decryptedText);// decrypt data using the FPGA 
			decrypted[i] = decryptedText[0];
			decrypted[i + 1] = decryptedText[1];// store the decrypted data in array
		}
	}
	else if (limit % 2)// if the limit is not a multiple of 2
	{
		for (size_t i = 0; i < limit; i += 2)
		{
			text[0] = fibonacci[i];
			text[1] = fibonacci[i + 1];

			SIMON_encrypt(&context, text, cipherText);// encrypt data
			encrypted[i] = cipherText[0];
			encrypted[i + 1] = cipherText[1]; // store the encrypted data in array 
			FPGA_decrypt(key,cipherText,decryptedText);// decrypt data using the FPGA 
			decrypted[i] = decryptedText[0];
			decrypted[i + 1] = decryptedText[1];// store the decrypted data in array

			if (i + 2 == limit)// reached the last remaining number
			{
				text[0] = fibonacci[i+2]; // assign last value of array 
				text[1] = 0; // make it zero 

				SIMON_encrypt(&context, text, cipherText);
				encrypted[i + 2] = cipherText[0];// store the last encrypted fibonacci number
				FPGA_decrypt(key,cipherText,decryptedText);// decrypt data using the FPGA 
				decrypted[i + 2] = decryptedText[0];// store the last decrypted fibonacci number
				break; // end the for loop 
			}
		}
	}

	printf("\n\n%d Fibonacci numbers have been encrypted.\n", limit);

	printf("\n%d-bit Keys:\n",key_length);

	for (size_t i = 0; i < key_length / 64; ++i) // print the master keys 
	{
		printf("%016llx\n", key[i]);
	}

	printf("\nEncrypted data:\n");// print all the encrypted data
	for (size_t i = 0; i < limit; ++i) 
	{
		printf("\t%016llx\n", encrypted[i]);
	}


	printf("Decrypted data:\n");// print all the decrypted data
	for (size_t i = 0; i < limit; ++i)
	{
		printf("\t%016lld\n", decrypted[i]);
	}

	free(encrypted);
	free(decrypted);// free all the dynamically allocated memory to prevent memory leaks 
}
