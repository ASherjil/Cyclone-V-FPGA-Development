#include "SIMON.h"

int main()
{
	const char message[] = { "This is test run, but things can go wrong." };


	int length = (sizeof(message) / sizeof(message[0])) - 1; // length of string without null termination
	packer(message,length); // BEGIN APPLICATION 
	return 0;
}
