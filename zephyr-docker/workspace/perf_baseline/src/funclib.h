#ifndef _TESTAPP_FUNC_LIB_
#define _TESTAPP_FUNC_LIB_

#include<stdint.h>

#define FUNCTION_NUMBER 4

double func1(double arg1);

double func2(double arg1);

double func3(double arg1);
double func4(double arg1);

typedef double(*pdfunc)(double);

typedef struct {
   uint8_t buffer[sizeof(double)];
   pdfunc pfunc;
} buff_ptr_t;

typedef pdfunc dfunctable_t[FUNCTION_NUMBER];

static dfunctable_t ftable = {func1, func2, func3, func4};

#endif
