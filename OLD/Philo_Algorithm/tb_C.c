#include "stdio.h"
#include "string.h"
#include "math.h"
#include "C:\Xilinx\Vivado\2018.2\data\xsim\include\svdpi.h"

#define N_ITERAZIONI 7


unsigned int DPI_C_log2(unsigned int op)
{   
    int result[N_ITERAZIONI] = {0};//{1,1,1,1,0,1,0};   //numero iniziale meno l'1 iniziale
    
   // 1111 1010 0000 0000
   //  ^      ^
    for(int i=6; i>=0;i--){
        result[i]=(op >> (8 + 6 - i))%2;
    }
    //^ mantissa ieee754
    float risultato = 0.0;
    float temp=0;
    //float f_op = *((float*) &u_op);

    for(int i = 1; i < N_ITERAZIONI+1; i++){
        if(result[i-1] == 1)
            risultato += pow(2, -i);
    }

    risultato++;        //lo rendiamo 1.qualcosa_in_decimale

    float f_res = log2(risultato);      //0.qualcosa_in_decimale

    //floating point to fixed point
    temp = f_res * 16384;
    int i_temp = (int) temp;          //occhio al troncamento!!
    
    return *((unsigned int*) &i_temp);
}