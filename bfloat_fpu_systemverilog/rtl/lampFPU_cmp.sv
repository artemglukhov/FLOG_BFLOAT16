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

module lampFPU_cmp (
	clk,rst,
	//	inputs
	doEq_i, doLt_i, doLe_i,
	opASign_i, opAExp_i, opAFract_i,
	opBSign_i, opBExp_i, opBFract_i,
	isAZer_i, isASNaN_i, isAQNaN_i,
	isBZer_i, isBSNaN_i, isBQNaN_i,
	//	outputs
	cmp_o, isCmpValid_o, isCmpInvalid_o
);

import lampFPU_pkg::*;

input							clk;
input							rst;
//	inputs
input							doEq_i;
input							doLt_i;
input							doLe_i;
input	[LAMP_FLOAT_S_DW-1:0]	opASign_i;
input	[LAMP_FLOAT_E_DW-1:0]	opAExp_i;
input	[LAMP_FLOAT_F_DW-1:0]	opAFract_i;
input	[LAMP_FLOAT_S_DW-1:0]	opBSign_i;
input	[LAMP_FLOAT_E_DW-1:0]	opBExp_i;
input	[LAMP_FLOAT_F_DW-1:0]	opBFract_i;
input							isAZer_i;
input							isASNaN_i;
input							isAQNaN_i;
input							isBZer_i;
input							isBSNaN_i;
input							isBQNaN_i;
//	outputs
output	logic					cmp_o;
output	logic					isCmpValid_o;
output	logic					isCmpInvalid_o;		//	invalid operation exception flag

//////////////////////////////////////////////////////////////////
//						internal wires							//
//////////////////////////////////////////////////////////////////

	logic							isABZer;
	logic							isABSNaN, isABQNaN, isABNaN;
	logic							signAEqB, signAEqpB, signAEqmB, signALtB;
	logic							expAGtB, expAEqB, expALtB;
	logic							fractAGtB, fractAEqB, fractALtB;
	logic							cmpAEqB, cmpALtB, cmpALeB;

	//	output next values
	logic							cmp;
	logic							isCmpValid;
	logic							isCmpInvalid;

//////////////////////////////////////////////////////////////////
// 						sequential logic						//
//////////////////////////////////////////////////////////////////

	always_ff @(posedge clk)
	begin
		if (rst)
		begin
			//	output registers
			cmp_o					<=	'0;
			isCmpValid_o			<=	'0;
			isCmpInvalid_o			<=	'0;
		end
		else
		begin
			//	output registers
			cmp_o					<=	cmp;
			isCmpValid_o			<=	isCmpValid;
			isCmpInvalid_o			<=	isCmpInvalid;
		end
	end

//////////////////////////////////////////////////////////////////
// 						combinational logic						//
//////////////////////////////////////////////////////////////////

	always_comb
	begin
		//	zero/NaN flags
		isABZer			=	isAZer_i && isBZer_i;
		isABSNaN		=	isASNaN_i || isBSNaN_i;
		isABQNaN		=	isAQNaN_i || isBQNaN_i;
		isABNaN			=	isABSNaN || isABQNaN;

		//	sign/exponent/significand comparisons
		signAEqB		=	opASign_i == opBSign_i;
		signAEqpB		=	~opASign_i && ~opBSign_i;
		signAEqmB		=	opASign_i && opBSign_i;
		signALtB		=	opASign_i > opBSign_i;
		expAGtB			=	opAExp_i > opBExp_i;
		expAEqB			=	opAExp_i == opBExp_i;
		expALtB			=	opAExp_i < opBExp_i;
		fractAGtB		=	opAFract_i > opBFract_i;
		fractAEqB		=	opAFract_i == opBFract_i;
		fractALtB		=	opAFract_i < opBFract_i;

		//	A-B comparisons
		cmpAEqB			=	~isABNaN && (isABZer ||
											(signAEqB && expAEqB && fractAEqB));
		cmpALtB			=	~isABNaN && ~isABZer && (signALtB ||
														(signAEqpB && expALtB) ||
														(signAEqmB && expAGtB) ||
														(signAEqpB && expAEqB && fractALtB) ||
														(signAEqmB && expAEqB && fractAGtB));
		cmpALeB			=	cmpAEqB || cmpALtB;

		//	output assignments
		if (doEq_i)
			cmp			=	cmpAEqB;
		else if (doLt_i)
			cmp			=	cmpALtB;
		else // if (doLe_i)
			cmp			=	cmpALeB;
		isCmpValid		=	doEq_i || doLt_i || doLe_i;
		isCmpInvalid	=	((doLe_i || doLt_i) && isABNaN) || (doEq_i && isABSNaN);
	end

endmodule
