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
		printf("\n192-bit Key\n");
		t = y;
		y = x;
		x = t;
		y ^= context->subkeys[68];
		y ^= f(x);

		printf("%d- %016llx %016llx\n", 68, x, y);

		for (i = 67; i >= 0; i -= 2)
		{
			R2(&y, &x, context->subkeys[i], context->subkeys[i - 1]);
			printf("%d- %016llx %016llx\n", i, x, y);
		}
	}
	else
	{
		printf("\n128 / 256 - bit Key\n");
		for (i = context->nrSubkeys - 1; i >= 0; i -= 2)
		{
			R2(&y, &x, context->subkeys[i], context->subkeys[i - 1]);
			printf("%d- %016llx %016llx\n",i, x, y);
		}
	}

	out[0] = x;
	out[1] = y;
}

void SIMON_main(void)
{
	printf("deleted function\n");

}

int open_physical(int);
void* map_physical(int, unsigned int, unsigned int);
void close_physical(int);
int unmap_physical(void*, unsigned int);

int main()
{
	SimonContext context;
	int i;
	uint64_t key[3];
	uint32_t key32[6];
	uint64_t text[2];
	uint64_t cipherText[2];
	uint32_t encrypt_in[4];
	uint64_t decryptedText[2] = {0,0};

	uint64_t ext = 0xFFFFFFFF; // 32-bit mask 

	// *** 192-bits key test ***

	// key 0f0e0d0c0b0a0908 0706050403020100
	key[0] = 0xABCDEF0123456789;
	key[1] = 0xDEADBEEA99999999;
	key[2] = 0xCABEFABCDEFABCDE;

	// text 6373656420737265 6c6c657661727420
	text[0] = 0x01234567A5A5A5A5;
	text[1] = 0x5A5A5A5AFEDCBA98;


	SIMON_init(&context, key, 192);

	SIMON_encrypt(&context, text, cipherText);

	for (size_t i = 0; i < 6; ++i)
	{
		if ((i == 0) || (i == 2) || (i == 4))
		{
			key32[i] = (key[i / 2] & ext);
		}
		else
		{
			key32[i] = ((key[i / 2] >> 32) & ext);
		}
			printf("32-bit key [%d] is: %x\n",i,key32[i]);
	}

	for (size_t i = 0; i < 4; ++i)
	{
		if ((i == 0) || (i == 2) || (i == 4))
		{
			encrypt_in[i] = (cipherText[i / 2] & ext);
		}
		else
		{
			encrypt_in[i] = ((cipherText[i / 2] >> 32) & ext);
		}
			printf("32-bit Encrypted Dat: [%d] is: %x\n",i,encrypt_in[i]);
	}

	volatile uint32_t* pData;
	int fd = -1;
	void* LW_virtual;

	if ((fd = open_physical(fd)) == -1)
		return -1;
	if (!(LW_virtual = map_physical(fd, LW_BRIDGE_BASE, LW_BRIDGE_SPAN)))
		return -1;

	pData = (uint32_t*)(LW_virtual + COUNT_BASE); // use base address of 0x0

	*(pData + 0xB) = 0; // reset first
	*(pData + 0xB) = 1;// now start program, reset_n set to 1

	printf("Data_ready signal is: %d\n",*(pData+6));
	

	*(pData + 3) = 0; // encryption at 0x3 set to 0 = decryption

//----------------------------------------------------------SENDING KEY 
	*(pData + 0) = 1; // key length set to 1, 192-bit key length 

	*(pData + 5) 	= key32[0]; // key word in # 0
	*(pData + 0xC)	= key32[1]; // key word in, #1 
	*(pData + 0xD)  = key32[2]; // #2
	*(pData + 0xE)  = key32[3];//#3
	*(pData + 0xF)  = key32[4];//#4
	*(pData + 0x10) = key32[5];// #5 

	*(pData + 1) = 1; // key valid set to 1 
	*(pData + 1) = 0; // key valid set to 0 
//------------------------------------------------SENDING ENCRYPTED DATA

	*(pData + 4) 	= encrypt_in[0]; // data word in 
	*(pData + 0x11) = encrypt_in[1]; // data word in 
	*(pData + 0x12) = encrypt_in[2]; // data word in 
	*(pData + 0x13) = encrypt_in[3]; // data word in

	*(pData + 2) = 1; // data_valid set 1 
	*(pData + 2) = 0; // data_valid set 0
//-----------------------------------------------------------------------

	while( ! ( (*(pData+6))& 0x1 )   ){}// wait until avs_s0_readdata(0) = '1'; -- wait until data_ready = '1'

	decryptedText[0] = *(pData + 7);
	decryptedText[0] |= ( ((uint64_t)(*(pData + 8))) << 32 );// shift the data then OR, to pack
	// inside the 64-bit integer
	decryptedText[1] = *(pData + 9);
	decryptedText[1] |= ( ((uint64_t)(*(pData + 0xA))) << 32 );// shift the data then OR, to pack
	// inside the 64-bit integer

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

	printf("Data_ready signal is: %d\n",*(pData+6));

	unmap_physical(LW_virtual, LW_BRIDGE_SPAN);
	close_physical(fd);
	return 0;
}





//---------------------------------------------------LINUX KERNAL FUNCTIONS

/* Open /dev/mem to give access to physical addresses */
int open_physical(int fd)
{
	if (fd == -1) // check if already open
		if ((fd = open("/dev/mem", (O_RDWR | O_SYNC))) == -1)
		{
			printf("ERROR: could not open \"/dev/mem\"...\n");
			return (-1);
		}
	return fd;
}

/* Close /dev/mem to give access to physical addresses */
void close_physical(int fd)
{
	close(fd);
}

/* Establish a virtual address mapping for the physical addresses starting
 * at base and extending by span bytes */
void* map_physical(int fd, unsigned int base, unsigned int span)
{
	void* virtual_base;
	// Get a mapping from physical addresses to virtual addresses
	virtual_base = mmap(NULL, span, (PROT_READ | PROT_WRITE), MAP_SHARED,
		fd, base);
	if (virtual_base == MAP_FAILED)
	{
		printf("ERROR: mmap() failed...\n");
		close(fd);
		return (NULL);
	}
	return virtual_base;
}

/* Close the previously-opened virtual address mapping */
int unmap_physical(void* virtual_base, unsigned int span)
{
	if (munmap(virtual_base, span) != 0)
	{
		printf("ERROR: munmap() failed...\n");
		return (-1);
	}
	return 0;
}

