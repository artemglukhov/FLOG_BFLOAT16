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

module lampFPU_f2i (
	clk, rst,
	//	inputs
	doF2i_i,
	s_op1_i, extF_op1_i, extE_op1_i,
	isSNAN_op1_i, isQNAN_op1_i,
	//	outputs
	s_res_o, f_res_o, valid_o,
	isOverflow_o, isUnderflow_o, isSNaN_o
);

import lampFPU_pkg::*;

input										clk;
input										rst;
//	inputs
input										doF2i_i;
input			[LAMP_FLOAT_S_DW-1:0]		s_op1_i;
input			[(LAMP_FLOAT_F_DW+1)-1:0]	extF_op1_i;
input			[(LAMP_FLOAT_E_DW+1)-1:0]	extE_op1_i;
input										isSNAN_op1_i;
input										isQNAN_op1_i;
//	outputs
output	logic								s_res_o;
output	logic	[(LAMP_INTEGER_DW+3)-1:0]	f_res_o;
output	logic								valid_o;
output	logic								isOverflow_o;
output	logic								isUnderflow_o;
output	logic								isSNaN_o;

//////////////////////////////////////////////////////////////////
//						internal wires							//
//////////////////////////////////////////////////////////////////

	logic	[$clog2(LAMP_INTEGER_F_DW)-1:0]	shiftLeft;
	logic	[$clog2(LAMP_INTEGER_F_DW)-1:0]	shiftRight;
	logic									isShiftRight;
	logic									isOverflow_temp;
	logic	[LAMP_INTEGER_S_DW-1:0]			intResSign;
	logic	[(LAMP_INTEGER_DW+3)-1:0]		floatFractExt;
	logic	[(LAMP_INTEGER_DW+3)-1:0]		floatFractExtSh;

	// post normalization wires/regs
	logic	[LAMP_FLOAT_S_DW-1:0]			s_res_postNorm;
	logic	[(LAMP_INTEGER_DW+3)-1:0]		f_res_postNorm;
	logic									isOverflow_postNorm;
	logic									isUnderflow_postNorm;

	//	output next values
	logic									s_res;
	logic	[(LAMP_INTEGER_DW+3)-1:0]		f_res;
	logic									valid;
	logic									isOverflow;
	logic									isUnderflow;
	logic									isSNaN;

//////////////////////////////////////////////////////////////////
// 						sequential logic						//
//////////////////////////////////////////////////////////////////

	always_ff @(posedge clk)
	begin
		if (rst)
		begin
			//	output registers
			s_res_o			<=	'0;
			f_res_o			<=	'0;
			valid_o			<=	'0;
			isOverflow_o	<=	'0;
			isUnderflow_o	<=	'0;
			isSNaN_o		<=	'0;	
		end
		else
		begin
			//	output registers
			s_res_o			<=	s_res;
			f_res_o			<=	f_res;
			valid_o			<=	valid;
			isOverflow_o	<=	isOverflow;
			isUnderflow_o	<=	isUnderflow;
			isSNaN_o		<=	isSNaN;	
		end
	end

//////////////////////////////////////////////////////////////////
// 						combinational logic						//
//////////////////////////////////////////////////////////////////

	always_comb
	begin
		shiftLeft				=	'0;
		shiftRight				=	'0;
		isShiftRight			=	1'b0;
		isOverflow_temp			=	1'b0;
		if (extE_op1_i < (LAMP_FLOAT_E_BIAS + LAMP_FLOAT_F_DW - LAMP_INTEGER_F_DW))
		begin
			shiftRight			=	LAMP_INTEGER_F_DW;
			isShiftRight		=	1'b1;
		end
		else if (extE_op1_i < (LAMP_FLOAT_E_BIAS + LAMP_FLOAT_F_DW))
		begin
			shiftRight			=	LAMP_FLOAT_E_BIAS + LAMP_FLOAT_F_DW - extE_op1_i;
			isShiftRight		=	1'b1;
		end
		else if (extE_op1_i < (LAMP_FLOAT_E_BIAS + LAMP_INTEGER_F_DW) ||
					(s_op1_i == '1 && extE_op1_i == (LAMP_FLOAT_E_BIAS + LAMP_INTEGER_F_DW) &&
						extF_op1_i[(LAMP_FLOAT_F_DW+1)-1] == '1 && extF_op1_i[(LAMP_FLOAT_F_DW+1)-2:0] == '0))
		begin
			shiftLeft			=	extE_op1_i - LAMP_FLOAT_E_BIAS - LAMP_FLOAT_F_DW;
		end
		else
		begin
			isOverflow_temp		=	1'b1;
		end

		intResSign				=	s_op1_i && (~(isQNAN_op1_i | isSNAN_op1_i));
		floatFractExt			=	extF_op1_i << 3;

		if (isShiftRight)
			floatFractExtSh		=	floatFractExt >> shiftRight;
		else
			floatFractExtSh		=	floatFractExt << shiftLeft;

		floatFractExtSh[1]		=	FUNC_f2i_stickyBit (floatFractExtSh, shiftRight);

		s_res_postNorm			=	intResSign;
		f_res_postNorm			=	floatFractExtSh;
		isOverflow_postNorm		=	isOverflow;
		isUnderflow_postNorm	=	1'b0;

		s_res					=	s_res_postNorm;
		f_res					=	f_res_postNorm;
		valid					=	doF2i_i;
		isOverflow				=	isOverflow_postNorm;
		isUnderflow				=	isUnderflow_postNorm;
		isSNaN					=	isSNAN_op1_i;
	end

endmodule
