#include<funclib.h>

double func1(double arg1){
   double ratio = 1.25;
   double thresold = 1.0;
   double val = arg1;
   double min = 10000.0;
   int i;

   if (val < min) val = min;

   for ( i = 0; i < 1000; i++){
       val = val / ratio;
       if (val < thresold) 
            break;
       val = val + 1.5;
   }

   return (double)i;
}

double func2(double arg1){
    double ratio = 1.25;
    double thresold = 10000.0;
    double val = arg1;
    double max = 10.0;
    int i;

    if (val > max) val = max;

    for (i = 0; i < 1000; i++){
        val = val * ratio;
        if (val > thresold) break;
        val = val - 1.5;
    }

    return (double)i;
}

double func3(double arg1){
    double val = arg1;

    val = func1(val);
    val = func2(val);

    return val;
}

// Syracuse
double func4(double arg) {
    int val = arg;
    int i = 0;
    while (val != 1) {
        if (val%2) {
            // odd
            val = 3*val+1; 
        } else { 
            val /= 2;
        }
        i++;
    }
    return (double)i;
}

