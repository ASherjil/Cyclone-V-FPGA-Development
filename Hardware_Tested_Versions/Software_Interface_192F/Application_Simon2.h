/* Application_Simon2.h
 * Author: Vinicius Borba da Rocha
 * Created: 09/08/2021
 * Author 2 : STUDENT ID B820928
 */

/* 
This is the second application layer file. It contains only the functions specific 
to the application that is encrypted or decrypted. 
*/

#pragma once

#include <stdio.h> // for printf
#include <stdlib.h>// for calloc(), free() dynamic memory allocation
#include <stdint.h> // for uin64_t, integer widths 
#include <string.h>// for strlen 

/*
	Function : packer
	Purpose : This is the MAIN function that begins the string packing algorithm.
	Arguments: pointer to char(char array = C-style string), int(size of the array).
	Return values: void
*/
void packer(const char*, int l);


/*
	Function : unpacker
	Purpose : Unpacks an array of 64-bit integers, 
	extracts chars and prints them(helper function). 
	Arguments: int (size of the array), pointer to the array uint64_t of data.
	Return values: void
*/
void unpacker(int, uint64_t*);

/*
	Function : inputString
	Purpose : This function is used to take a string from the user of an
	unknown length 
	Arguments: pointer to FILE struct, size_t initial length of string 
	Return values: pointer to the first element of string 
*/
char* inputString(FILE*, size_t);

/*
	Function : fibon_begin
	Purpose : This function generates fibonacci numbers upto a limit 
	specified by the user, then encrypts/ decrypts them. 
	Arguments: pointer to FILE struct, size_t initial length of string
	Return values: none
*/
void fibon_begin();


/*
	Function : fibon_EncDec
	Purpose : This is a helper function for fibon_begin()
	it encrypts and decrypts fibocci numbers
	Arguments: pointer to fibonacci array,
	pointer to keys array, limit of fiboacci numbers,
	length of keys(128 or 192)
	Return values: none
*/
void fibon_EncDec(uint64_t*,uint64_t*, int,int);