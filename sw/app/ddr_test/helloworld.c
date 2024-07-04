#include <stdio.h>
#include <stdlib.h>

#define START_ADDR  0x90070000
#define END_ADDR    0x90090000
#define DDR_SIZE (END_ADDR-START_ADDR)/4
  
int main(void) {

  printf("==============================\r\n");
  printf("         Memory test!\r\n"); 
  printf("==============================\r\n");
  
  int volatile * addr = (int *) START_ADDR;

  printf("Starting at address %p\r\n", addr);

  for(int i = 0; i<DDR_SIZE; i+=1) {
    *(addr+i) = i;
    if(i % (DDR_SIZE/0x100) == 0) {
      printf("Writing address %p...\r\n", addr+i);
    }
  }

  printf("==============================\r\n");
  printf("Done writing, starting reading\r\n");
  printf("==============================\r\n");

  for(int i=0; i<DDR_SIZE; i+=1) {
    if(*(addr+i) != i) {
      printf("Error at %p: read value 0x%x, should be 0x%x\r\n", addr+i, *(addr+i), i);
    }
    if(i % (DDR_SIZE/0x100) == 0) {
      printf("Reading address %p, value=0x%x...\r\n", addr+i, *(addr+i));
    }
  }
  
  printf("==============================\r\n");
  printf("Done writing, testing scratch \r\n");
  printf("==============================\r\n");
  
  int volatile * addr_scratch = (int *) 0x80030000;
  
  for(int i = 0; i<0x100; i+=1) {
    *(addr_scratch+i) = i;
  }
  
  for(int i=0; i<0x100; i+=1) {
    if(*(addr_scratch+i) != i) {
      printf("Error at %p: read value 0x%x, should be 0x%x\r\n", addr_scratch+i, *(addr_scratch+i), i);
    }
  }

  printf("==============================\r\n");
  printf("             Done\r\n");
  printf("==============================\r\n");

  return(0);
}

