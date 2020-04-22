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

module lampFPU_i2f (
	clk, rst,
	//	inputs
	doI2f_i, op1_i,
	//	outputs
	s_res_o, e_res_o, f_res_o, valid_o,
	isOverflow_o, isUnderflow_o, isToRound_o
);

import lampFPU_pkg::*;

input									clk;
input									rst;
//	inputs
input									doI2f_i;
input			[LAMP_INTEGER_DW-1:0]	op1_i;
//	outputs
output	logic							s_res_o;
output	logic	[LAMP_FLOAT_E_DW-1:0]	e_res_o;
output	logic	[LAMP_FLOAT_F_DW+5-1:0]	f_res_o;
output	logic							valid_o;
output	logic							isOverflow_o;
output	logic							isUnderflow_o;
output	logic							isToRound_o;

//////////////////////////////////////////////////////////////////
//						internal wires							//
//////////////////////////////////////////////////////////////////

	logic									intOpSign;
	logic	[LAMP_INTEGER_DW-1:0] 			intOpMagnitude;
	logic	[LAMP_FLOAT_E_DW-1:0]			intOpExp;
	logic									isIntOpZero;
	logic	[$clog2(LAMP_INTEGER_DW)-1:0]	shiftLeft;
	logic	[$clog2(LAMP_INTEGER_DW)-1:0]	shiftRight;
	logic	[(LAMP_INTEGER_DW+3)-1:0]		floatFractExt;
	logic	[(1+1+LAMP_FLOAT_F_DW+3)-1:0]	floatFractExtSh;

	// post normalization wires/regs
	logic	[LAMP_FLOAT_S_DW-1:0]			s_res_postNorm;
	logic	[LAMP_FLOAT_E_DW-1:0]			e_res_postNorm;
	logic	[(1+1+LAMP_FLOAT_F_DW+3)-1:0]	f_res_postNorm;
	logic									isOverflow_postNorm;
	logic									isUnderflow_postNorm;

	//	output next values
	logic									s_res;
	logic	[LAMP_FLOAT_E_DW-1:0]			e_res;
	logic	[(1+1+LAMP_FLOAT_F_DW+3)-1:0]	f_res;
	logic									valid;
	logic									isOverflow;
	logic									isUnderflow;
	logic									isToRound;

//////////////////////////////////////////////////////////////////
// 						sequential logic						//
//////////////////////////////////////////////////////////////////

	always_ff @(posedge clk)
	begin
		if (rst)
		begin
			//	output registers
			s_res_o			<=	'0;
			e_res_o			<=	'0;
			f_res_o			<=	'0;
			valid_o			<=	'0;
			isOverflow_o	<=	'0;
			isUnderflow_o	<=	'0;
			isToRound_o		<=	'0;
		end
		else
		begin
			//	output registers
			s_res_o			<=	s_res;
			e_res_o			<=	e_res;
			f_res_o			<=	f_res;
			valid_o			<=	valid;
			isOverflow_o	<=	isOverflow;
			isUnderflow_o	<=	isUnderflow;
			isToRound_o		<=	isToRound;
		end
	end

//////////////////////////////////////////////////////////////////
// 						combinational logic						//
//////////////////////////////////////////////////////////////////

	always_comb
	begin
		intOpSign					=	op1_i[LAMP_INTEGER_DW-1];
		intOpMagnitude				=	(op1_i ^ {LAMP_INTEGER_DW{intOpSign}}) + intOpSign;
		intOpExp					=	FUNC_i2f_integerExponent (intOpMagnitude);
		isIntOpZero					=	~(|op1_i);

		shiftRight					=	'0;
		shiftLeft					=	'0;
		if (intOpExp > LAMP_FLOAT_F_DW)
			shiftRight				=	intOpExp - LAMP_FLOAT_F_DW;
		else
			shiftLeft				=	LAMP_FLOAT_F_DW - intOpExp;

		floatFractExt				=	intOpMagnitude << 3;

		if (intOpExp > LAMP_FLOAT_F_DW)
			floatFractExtSh			=	floatFractExt >> shiftRight;
		else
			floatFractExtSh			=	floatFractExt << shiftLeft;

		floatFractExtSh[1]			=	FUNC_i2f_stickyBit (floatFractExt, shiftRight);

		s_res_postNorm				=	intOpSign;
		e_res_postNorm				=	intOpExp + LAMP_FLOAT_E_BIAS;
		f_res_postNorm				=	floatFractExtSh;
		isOverflow_postNorm			=	1'b0;
		isUnderflow_postNorm		=	1'b0;

		if (isIntOpZero)
			{s_res, e_res, f_res}	=	{1'b0, ZERO_E_F, 5'b0};
		else
			{s_res, e_res, f_res}	=	{s_res_postNorm, e_res_postNorm, f_res_postNorm};
		valid						=	doI2f_i;
		isToRound					=	~isIntOpZero;
		isOverflow					=	isOverflow_postNorm;
		isUnderflow					=	isUnderflow_postNorm;
	end

endmodule
