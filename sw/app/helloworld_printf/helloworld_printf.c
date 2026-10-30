#include <stdio.h>
#include "uart.h"

int main(void)
{

  printf("hello World!\n");

  //wait end of uart frame
  while(UART_tx_complete(&g_uart_0)==0);

  return(0);
}

