#include<funclib.h>
#include<stdio.h>
#include<stdlib.h>

#define MAX_DEPTH 100
#define MAX_CALLS 10000

#define FREQ 25000000.0

double main_func(double, int);
double main_func_rec(double, int, int);


static int depth = 0;
static int callsnb = 0;

inline uint64_t get_mcycle() {
    uint64_t mcycle = 0;
    __asm__ volatile ("csrr %0,mcycle"   : "=r" (mcycle)  );
    return mcycle;
}

void main(void)
{
   // definitions used for measuring execution time
   uint64_t start, end;
   uint64_t total_cycles;

   // arguments
   depth = 12;
   callsnb = 50;
   double value = 63728127;
   double sum = 0.0;

   // sanity checks
   if ((1 > depth) || (MAX_DEPTH < depth)){
      fprintf(stderr,"ERROR: specified depth (%d) is out of allowed range (1-%d)\n", depth, MAX_DEPTH);
      exit(1);
   }
   if ((1 > callsnb) || (MAX_CALLS < callsnb)){
      fprintf(stderr,"ERROR: specified call number (%d) is out of allowed range (1-%d)\n", callsnb, MAX_CALLS);
      exit(1);
   }

   fprintf(stdout,"Begining of execution with depth %d, call number %d, seed value %f\n", depth, callsnb, value);

   start = get_mcycle();

   // main computation loop
   for (int i = 0; i < callsnb; i++)
      sum += main_func_rec(value, 0, 1);

   end = get_mcycle();
   total_cycles = end - start;

   fprintf(stdout,"SUCCESS: computed value %f - duration: %f sec %u cycles\n", sum, total_cycles/FREQ, total_cycles);
}


double main_func_rec(double value, int first_func_call, int curdepth){
   // allocation on stack, trigger canaries
   buff_ptr_t buff_ptr;
   *((double*)buff_ptr.buffer) = 0.0;

   // recusive calls, as to create deep stack
   if (curdepth < depth){
      *((double*)buff_ptr.buffer) += main_func_rec(value, ((first_func_call+1)%FUNCTION_NUMBER), curdepth+1);
   }

    double tmp = main_func(value, first_func_call);

   *((double*)buff_ptr.buffer) +=  tmp;

   return *((double*)buff_ptr.buffer);
}


double main_func(double value, int first_func_call){
   int cur_index;
   buff_ptr_t* heap_mem = NULL;
   double res = 0.0;

   // allocate a buffer + fonction pointer on heap, will test heap memory protection such as heap canaries
   heap_mem = (buff_ptr_t*)malloc(sizeof(buff_ptr_t));
   *((double*)heap_mem->buffer) = 0.0;


   for (int i = 0; i < FUNCTION_NUMBER; i++){
      // hopefully this trick bypasses compiler optimization
      cur_index = (first_func_call + i) % FUNCTION_NUMBER; 

      // should cause an indirect jump, triggering forward-edge CFI
      heap_mem->pfunc = ftable[cur_index];

      //res += ftable[cur_index](value);

      // writing in buffer preceding a pointer should lead to a canary
      *((double*)heap_mem->buffer) += heap_mem->pfunc(value);
   }
   res = *((double*)heap_mem->buffer);

   free(heap_mem);

   return res;
}
