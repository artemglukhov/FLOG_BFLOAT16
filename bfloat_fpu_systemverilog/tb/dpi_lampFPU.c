// Copyright 2019 Politecnico di Milano.
// Copyright and related rights are licensed under the Solderpad Hardware
// Licence, Version 2.0 (the "Licence"); you may not use this file except in
// compliance with the Licence. You may obtain a copy of the Licence at
// https://solderpad.org/licenses/SHL-2.0/. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this Licence is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the Licence for the
// specific language governing permissions and limitations under the Licence.
//
// Authors (in alphabetical order):
// Andrea Galimberti    <andrea.galimberti@polimi.it>
// Davide Zoni          <davide.zoni@polimi.it>
//
// Date: 30.09.2019

#include "C:\Xilinx\Vivado\2018.2\data\xsim\include\svdpi.h"
#include <stdio.h>
#include <math.h>

#define FLOAT_E_DW 8
#define FLOAT_F_DW 7

void
printFloatHex(float fVal)
{
	unsigned int val2hex 	= *(unsigned int*) & fVal;
	unsigned int val_s 		= val2hex >> 31; 		
	unsigned int val_e 		= (val2hex << 1) >> 24;
	unsigned int val_f 		= (val2hex << 9) >> 9;

	printf("printFloatHex - S=%0d E=0x%02x F=0x%06x\n", val_s, val_e, val_f	);
	fflush(stdout);
}

void
printFloatBinary(float fVal)
{
	unsigned int val2hex 	= *(unsigned int*) & fVal;
	unsigned int val_s 		= val2hex >> 31; 		
	unsigned int val_e 		= (val2hex << 1) >> 24;
	unsigned int val_f 		= (val2hex << 9) >> 9;

	unsigned int mask=0;
	unsigned int n_rsh=0;
	printf("printFloatBinary - S=%0d E=0b", val_s);
	for(int i=FLOAT_E_DW-1; i>=0; i--)
	{
			
		mask  = 1 << i;
		n_rsh = i;
		printf("%u", (val_e & mask) >> n_rsh);
	}

	printf(" F=0b"	);
	for(int i=FLOAT_F_DW-1; i>=0; i--)
	{
		mask = 1 << i;
		n_rsh= i;
		printf("%u", (val_f & mask) >>  n_rsh );
	}
	printf("\n");
	fflush(stdout);
}


void
printInt(int iVal)
{
	printf("printInt - iVal=%d\n", iVal);
	fflush(stdout);
}


void
DPI_fPrintHex(unsigned int fVal)
{
	unsigned int val2hex 	= fVal;
	unsigned int val_s 		= val2hex >> 31; 		
	unsigned int val_e 		= (val2hex << 1) >> 24;
	unsigned int val_f 		= (val2hex << 9) >> 9;

	printf("FUNC DPI-C fPrintHex - S=%0d E=0x%02x F=0x%06x\n", val_s, val_e, val_f	);
	fflush(stdout);
}

void
DPI_fPrintBinary(unsigned int fVal)
{
	unsigned int val2hex 	= fVal;
	unsigned int val_s 		= val2hex >> 31; 		
	unsigned int val_e 		= (val2hex << 1) >> 24;
	unsigned int val_f 		= (val2hex << 9) >> 9;

	unsigned int mask 	= 0;
	unsigned int n_rsh	= 0;
	printf("FUNC DPI-C fPrintBinary - S=%0d E=0b", val_s);
	for(int i=FLOAT_E_DW-1; i>=0; i--)
	{
		mask  = 1 << i;
		n_rsh = i;
		printf("%u", (val_e & mask) >> n_rsh);
	}

	printf(" F=0b"	);
	for(int i=FLOAT_F_DW-1; i>=0; i--)
	{
		mask = 1 << i;
		n_rsh= i;
		printf("%u", (val_f & mask) >>  n_rsh );
	}
	printf("\n");
	fflush(stdout);
}

unsigned int
DPI_f2i(unsigned int uVal)
{
	float fVal = *((float*) &uVal);
	int iVal = (int) fVal;
	//printInt(iVal);
	return *((unsigned int*) &iVal);
}

unsigned int
DPI_i2f(int iVal)
{
	float fVal= (float) iVal;
	//printFloatHex(fVal);	
	return *((unsigned int*) &fVal);
}

//////////////////////////////////////////////////
//				FPU OPERATIONS					//
//////////////////////////////////////////////////

//
// fadd
//
unsigned int
DPI_fadd(unsigned int op1, unsigned int op2)
{
	//unsigned -> float
	float f_op1 = *((float*) &op1);
	float f_op2 = *((float*) &op2);
	// perform fadd
	float f_res = f_op1 + f_op2;
	// return 32bit float encoding
	return *((unsigned int*) &f_res);
}

//
// fsub
//
unsigned int
DPI_fsub(unsigned int op1, unsigned int op2)
{
	//unsigned -> float
	float f_op1 = *((float*) &op1);
	float f_op2 = *((float*) &op2);
	// perform fsub
	float f_res = f_op1 - f_op2;
	// return 32bit float encoding
	return *((unsigned int*) &f_res);
}

//
// fdiv
//
unsigned int
DPI_fdiv(unsigned int op1, unsigned int op2)
{
	//unsigned -> float
	float f_op1 = *((float*) &op1);
	float f_op2 = *((float*) &op2);
	// perform fdiv
	float f_res = f_op1 / f_op2;
	// return 32bit float encoding
	return *((unsigned int*) &f_res);
}

//
// fmul
//
unsigned int
DPI_fmul(unsigned int op1, unsigned int op2)
{
	//unsigned -> float
	float f_op1 = *((float*) &op1);
	float f_op2 = *((float*) &op2);
	// perform fmul
	float f_res = f_op1 * f_op2;
	// return 32bit float encoding
	return *((unsigned int*) &f_res);
}

//
// feq
//
unsigned int
DPI_feq(unsigned int op1, unsigned int op2)
{
	//unsigned -> float
	float f_op1 = *((float*) &op1);
	float f_op2 = *((float*) &op2);
	// perform feq
	unsigned int res = f_op1 == f_op2;
	// return 1bit comparison flag
	return res;
}

//
// flt
//
unsigned int
DPI_flt(unsigned int op1, unsigned int op2)
{
	//unsigned -> float
	float f_op1 = *((float*) &op1);
	float f_op2 = *((float*) &op2);
	// perform flt
	unsigned int res = f_op1 < f_op2;
	// return 1bit comparison flag
	return res;
}

//
// fle
//
unsigned int
DPI_fle(unsigned int op1, unsigned int op2)
{
	//unsigned -> float
	float f_op1 = *((float*) &op1);
	float f_op2 = *((float*) &op2);
	// perform fle
	unsigned int res = f_op1 <= f_op2;
	// return 1bit comparison flag
	return res;
}

//int
//main()
//{
//	//float a=1.0*exp2(-(127));
//	float a=1.75*exp2(6);
//	float b=1.3, c=0;
//
//	//unsigned int u_a = DPI_f2i(*((unsigned int*) &a));
//	
//	//printFloatHex(a);
//	//printFloatHex(b);
//	
//	printFloatBinary(a);
//	printFloatBinary(b);
//
//	c = a + b;
//	printFloatBinary(c);
//
//	//unsigned int tmpRes = DPI_fadd (*((unsigned int*) &a), *((unsigned int*) &b)  );
//	//DPI_fPrint(tmpRes);
//
//	return 0;
//}
