// This is the software interface for 192-bit keys fast Simon

#pragma warning(disable : 4996) // disable warning about scanf_s
#include "Application_Simon1.h"// include application layer 1(Simon Algorithm)
#include "Application_Simon2.h"// include application layer 2(String+fibonacci application)

int main()
{
	int option; // integer to store the the option selected 

	while (1)
	{
		printf("Select application(enter either 1,2 or 3):"
			"\n1 - Send secret message\n2 - Fibonacci Number encryption\n3 - Quit.\n");

		scanf("%d", &option);

		int c;  // dummy variable for getchar() 
		while ((c = getchar()) != '\n' && c != EOF); // remove the last '\n' from user input

		switch(option){
			case 1:

				printf("Enter your message(terminated by '*'):\n");
				
				char* message = inputString(stdin, 10); // store input from the user 
				packer(message, strlen(message));// begin application  
				break;

			case 2:

				fibon_begin(); // start fibonacci sequence 
				break;

			case 3:
				return 0; // exit 
				break;

			default:  // terminate program 
				printf("Incorrect number entered.\n");
				return 0;//exit 
		}
	}
}