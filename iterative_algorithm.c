#include "stdio.h"
#include "math.h"

#define n_iterazioni 6

float num = 1.1640625; //numero di cui voglio effettuare il log2

float a = 0.0;

int result[n_iterazioni+1] = {0};
int i = 0;
float risultato = 0.0;

int main(void){

    a = num;

    for(i = 0; i > -n_iterazioni; i--){             

        if(a >= pow(2, pow(2, i))){
            result[-i] = 1;
            a = a*pow(2, pow(-2, i));
        }
        else
            result[-i] = 0;

    }

    for(i = 0; i < n_iterazioni; i++){
        if(result[i] == 1)
            risultato += pow(2, -i);
    }

    printf("log2 = %f \r\n", risultato);
}
