#include "SIMON.h"

int main()
{
	const char message[] = { "Brian was in Barbados on holiday on the beach." };


	int length = (sizeof(message) / sizeof(message[0])) - 1; // length of string without null termination
	packer(message,length); // BEGIN APPLICATION 
	return 0;
}

