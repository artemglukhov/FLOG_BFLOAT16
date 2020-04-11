#include "stdio.h"
#include "string.h"
#include "math.h"
#include "C:\Xilinx\Vivado\2018.2\data\xsim\include\svdpi.h"

unsigned int DPI_C_log2(unsigned int sign, unsigned int exp, unsigned int frac)
{   
    float input_number;

    float frac_real = (float) frac / 128 + 1;
    input_number = pow(2,(double)exp-127) * frac_real * pow(-1,sign);
    float f_res = log2(input_number);
    
    return *((unsigned int*) &f_res);
}
 
/* int main()
{
    
    printf("%X\n", (DPI_C_log2(0, 120, 43) ) );
} */