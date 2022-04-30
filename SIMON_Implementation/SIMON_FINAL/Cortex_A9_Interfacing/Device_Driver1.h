#pragma once

#define _GNU_SOURCE
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include "address_map_arm.h"
#define COUNT_BASE 0x0


//-----------------------------------------------linux kernal functions----
int open_physical(int);
void* map_physical(int, unsigned int, unsigned int);
void close_physical(int);
int unmap_physical(void*, unsigned int);
//--------------------------------------------------------------------------