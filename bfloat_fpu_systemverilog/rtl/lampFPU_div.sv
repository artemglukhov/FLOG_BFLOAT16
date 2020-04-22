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

module lampFPU_div (
	clk, rst,
	//	inputs
	doDiv_i,
	s_op1_i, extShF_op1_i, extE_op1_i, nlz_op1_i,
	isZ_op1_i, isInf_op1_i, isSNAN_op1_i, isQNAN_op1_i,
	s_op2_i, extShF_op2_i, extE_op2_i, nlz_op2_i,
	isZ_op2_i, isInf_op2_i, isSNAN_op2_i, isQNAN_op2_i,
	//	outputs
	s_res_o, e_res_o, f_res_o, valid_o,
	isOverflow_o, isUnderflow_o, isToRound_o
);

import lampFPU_pkg::*;

input											clk;
input											rst;
//	inputs
input											doDiv_i;
input			[LAMP_FLOAT_S_DW-1:0]			s_op1_i;
input			[(1+LAMP_FLOAT_F_DW)-1:0]		extShF_op1_i;
input			[(LAMP_FLOAT_E_DW+1)-1:0]		extE_op1_i;
input			[$clog2(1+LAMP_FLOAT_F_DW)-1:0]	nlz_op1_i;
input											isZ_op1_i;
input											isInf_op1_i;
input											isSNAN_op1_i;
input											isQNAN_op1_i;
input			[LAMP_FLOAT_S_DW-1:0]			s_op2_i;
input			[(1+LAMP_FLOAT_F_DW)-1:0]		extShF_op2_i;
input			[(LAMP_FLOAT_E_DW+1)-1:0]		extE_op2_i;
input			[$clog2(1+LAMP_FLOAT_F_DW)-1:0]	nlz_op2_i;
input											isZ_op2_i;
input											isInf_op2_i;
input											isSNAN_op2_i;
input											isQNAN_op2_i;
//	outputs
output	logic									s_res_o;
output	logic	[LAMP_FLOAT_E_DW-1:0]			e_res_o;
output	logic	[LAMP_FLOAT_F_DW+5-1:0]			f_res_o;
output	logic									valid_o;
output	logic									isOverflow_o;
output	logic									isUnderflow_o;
output	logic									isToRound_o;

//////////////////////////////////////////////////////////////////
//						internal wires							//
//////////////////////////////////////////////////////////////////

	logic									s_initial_res_div;
	logic	[1+1+LAMP_FLOAT_E_DW-1:0]		e_initial_res_div_temp;		// 1+ care for ovf or 2'compl, result of the difference of exponents
	logic	[1+1+LAMP_FLOAT_E_DW-1:0]		e_initial_extra_neg_temp;	// 1+ care for ovf or 2'compl, result of the difference of exponents
	logic	[1+1+LAMP_FLOAT_E_DW-1:0]		e_initial_res_div;			// 1+ care for ovf or 2'compl, result of the difference of exponents
	logic	[2*(1+LAMP_FLOAT_F_DW)-1:0]		f_initial_dsp_res_div;		// f = f_op1 / f_op2 (twice the width)
	logic	[(1+1+LAMP_FLOAT_F_DW+3)-1:0]	f_initial_res_div;			// f = f_op1 / f_op2

	// de-normalization
	logic									leftShift;

	// post normalization wires/regs
	logic									s_res_postNorm;
	logic	[1+1+LAMP_FLOAT_F_DW+3-1:0]		f_res_postNorm;			// still keep hidden bit and overflow bit (MSB) in the bitvector
	logic	[LAMP_FLOAT_E_DW+1-1:0]			e_res_postNorm;
	logic									isOverflow_postNorm;
	logic									isUnderflow_postNorm;

	//	output next values
	logic									s_res;
	logic	[LAMP_FLOAT_E_DW-1:0]			e_res;
	logic	[LAMP_FLOAT_F_DW+5-1:0]			f_res;
	logic									valid;
	logic									isOverflow;
	logic									isUnderflow;
	logic									isToRound;

	logic									stickyBit;

	logic									isCheckNanInfValid;
	logic									isZeroRes;
	logic									isCheckInfRes;
	logic									isCheckNanRes;
	logic									isCheckSignRes;

	logic									fd_doDiv;
	logic	[(1+LAMP_FLOAT_F_DW)-1:0]		fd_n;
	logic	[(1+LAMP_FLOAT_F_DW)-1:0]		fd_d;
	logic	[2*(1+LAMP_FLOAT_F_DW)-1:0]		fd_res;
	logic									fd_valid;

	logic	[LAMP_FLOAT_S_DW-1:0]			s_op1_r;
	logic	[LAMP_FLOAT_S_DW-1:0]			s_op2_r;
	logic									isZ_op1_r, isInf_op1_r, isSNAN_op1_r, isQNAN_op1_r;
	logic									isZ_op2_r, isInf_op2_r, isSNAN_op2_r, isQNAN_op2_r;
	logic	[1+1+LAMP_FLOAT_E_DW-1:0]		e_initial_res_div_r;
	logic	[1+1+LAMP_FLOAT_E_DW-1:0]		e_initial_extra_neg_r;
	logic	[1+1+LAMP_FLOAT_E_DW-1:0]		e_initial_extra_neg;

//////////////////////////////////////////////////////////////////
//						internal submodules						//
//////////////////////////////////////////////////////////////////

	lampFPU_fractDiv lampFPU_fractDiv0 (
		.clk		(clk),
		.rst		(rst),
		.doDiv_i	(fd_doDiv),
		.n_i		(fd_n),
		.d_i		(fd_d),
		.res_o		(fd_res),
		.valid_o	(fd_valid)
	);

//////////////////////////////////////////////////////////////////
//						wire assignments						//
//////////////////////////////////////////////////////////////////

	assign	fd_doDiv	=	doDiv_i;
	assign	fd_n		=	extShF_op1_i;
	assign	fd_d		=	extShF_op2_i;

//////////////////////////////////////////////////////////////////
// 						sequential logic						//
//////////////////////////////////////////////////////////////////

	always_ff @(posedge clk)
	begin
		if (rst)
		begin
			//	internal registers
			s_op1_r					<=	'0;
			isZ_op1_r				<=	'0;
			isInf_op1_r				<=	'0;
			isSNAN_op1_r			<=	'0;
			isQNAN_op1_r			<=	'0;
			s_op2_r					<=	'0;
			isZ_op2_r				<=	'0;
			isInf_op2_r				<=	'0;
			isSNAN_op2_r			<=	'0;
			isQNAN_op2_r			<=	'0;
			e_initial_res_div_r		<=	'0;
			e_initial_extra_neg_r	<=	'0;
			//	output registers
			s_res_o					<=	'0;
			e_res_o					<=	'0;
			f_res_o					<=	'0;
			valid_o					<=	'0;
			isOverflow_o			<=	'0;
			isUnderflow_o			<=	'0;
			isToRound_o				<=	'0;
		end
		else
		begin
			//	internal registers
			s_op1_r					<=	s_op1_i;
			isZ_op1_r				<=	isZ_op1_i;
			isInf_op1_r				<=	isInf_op1_i;
			isSNAN_op1_r			<=	isSNAN_op1_i;
			isQNAN_op1_r			<=	isQNAN_op1_i;
			s_op2_r					<=	s_op2_i;
			isZ_op2_r				<=	isZ_op2_i;
			isInf_op2_r				<=	isInf_op2_i;
			isSNAN_op2_r			<=	isSNAN_op2_i;
			isQNAN_op2_r			<=	isQNAN_op2_i;
			e_initial_res_div_r		<=	e_initial_res_div_temp;
			e_initial_extra_neg_r	<=	e_initial_extra_neg_temp;
			//	output registers
			s_res_o					<=	s_res;
			e_res_o					<=	e_res;
			f_res_o					<=	f_res;
			valid_o					<=	valid;
			isOverflow_o			<=	isOverflow;
			isUnderflow_o			<=	isUnderflow;
			isToRound_o				<=	isToRound;
		end
	end

//////////////////////////////////////////////////////////////////
// 						combinational logic						//
//////////////////////////////////////////////////////////////////

	always_comb
	begin
		e_initial_res_div_temp		= LAMP_FLOAT_E_BIAS + extE_op1_i + nlz_op2_i - nlz_op1_i - extE_op2_i;
		e_initial_extra_neg_temp	= nlz_op1_i + extE_op2_i - LAMP_FLOAT_E_BIAS - extE_op1_i - nlz_op2_i;
	//
	// perform F division and do post-normalization
	//
		f_initial_dsp_res_div	= fd_res;

		e_initial_res_div		= e_initial_res_div_r;

		// get the MSB (1+LAMP_FLOAT_DW+3+1) bits from the div result
		f_initial_res_div		= f_initial_dsp_res_div[(2*(1+LAMP_FLOAT_F_DW)-1) -:(1+1+LAMP_FLOAT_F_DW+3/*G,R,S*/)];

		s_initial_res_div		= s_op1_r ^ s_op2_r;

		if (f_initial_dsp_res_div[2*(1+LAMP_FLOAT_F_DW)-2] == 1'b1)
			leftShift	= 1'b0;
		else
			leftShift	= 1'b1;

		e_initial_extra_neg		= e_initial_extra_neg_r;

		if (~e_initial_extra_neg_r[(1+1+LAMP_FLOAT_E_DW)-1])
		begin /*start right shift to increase exponent*/
			if (e_initial_extra_neg_r > 1+LAMP_FLOAT_F_DW+3)
			begin
				f_initial_dsp_res_div	= '0;
				e_initial_res_div		= '0;
			end
			else
			begin
				f_initial_dsp_res_div	= f_initial_dsp_res_div >>  (e_initial_extra_neg_r+1);
				e_initial_res_div 		= e_initial_res_div + e_initial_extra_neg;
			end
		end
		else if (e_initial_res_div >= LAMP_FLOAT_E_MAX & (e_initial_res_div-LAMP_FLOAT_E_MAX) >= leftShift)
		begin
			f_initial_dsp_res_div	= '0;
			e_initial_res_div		= -1;
		end
		else
		begin
			f_initial_dsp_res_div	= f_initial_dsp_res_div << leftShift;
			e_initial_res_div		= e_initial_res_div - leftShift;
		end

		f_initial_res_div	= f_initial_dsp_res_div[(2*(1+LAMP_FLOAT_F_DW)-1) -:(1+1+LAMP_FLOAT_F_DW+3/*G,R,S*/)];

		isOverflow_postNorm		= '0;
		isUnderflow_postNorm	= '0;

		s_res_postNorm			= s_initial_res_div; //final sign does not change

		stickyBit = |f_initial_dsp_res_div[0+: (2*(1+LAMP_FLOAT_F_DW)-1) -(1+1+LAMP_FLOAT_F_DW+3) ];

		f_initial_res_div [0]	= f_initial_res_div[0] | stickyBit;

		if (e_initial_res_div != 0) //no right shift, no left shift -> no postnorm, thus fix the sticky bit for rounding
		begin
			//check if e=0 to signal zero or underflow
			f_res_postNorm	= {f_initial_res_div [1+1+LAMP_FLOAT_F_DW+3-1:2], f_initial_res_div[1] | f_initial_res_div[0], 1'b0 /*old useless sticky*/ };
			e_res_postNorm	= e_initial_res_div;
		end
		else if (f_initial_res_div[1/*extra bit*/+(1/*hidden 1*/+LAMP_FLOAT_F_DW+3/*LSB rnd bits*/)-2] == 1)
		begin
			e_res_postNorm		= '1;
			f_res_postNorm		= f_initial_res_div;
		end
		else
		begin
			isUnderflow_postNorm	= '1;
			e_res_postNorm			= '0;
			f_res_postNorm			= f_initial_res_div;
		end

		f_res_postNorm [1] = f_res_postNorm[1] | stickyBit;
		f_res_postNorm [0] = stickyBit;

	//
	// compute if res is infinite zero or nan
	//
		{isCheckNanInfValid, isZeroRes, isCheckInfRes, isCheckNanRes, isCheckSignRes} = FUNC_calcInfNanZeroResDiv(
					isZ_op1_r, isInf_op1_r, s_op1_r, isSNAN_op1_r, isQNAN_op1_r,	/*op1 */
					isZ_op2_r, isInf_op2_r, s_op2_r, isSNAN_op2_r, isQNAN_op2_r		/*op2 */
			);

		unique if (isZeroRes)
			{s_res, e_res, f_res}	=	{isCheckSignRes, ZERO_E_F, 5'b0};
		else if (isCheckInfRes)
			{s_res, e_res, f_res}	=	{isCheckSignRes, INF_E_F, 5'b0};
		else if (isCheckNanRes)
			{s_res, e_res, f_res}	=	{isCheckSignRes, QNAN_E_F, 5'b0};
		else
			{s_res, e_res, f_res}	=	{s_res_postNorm, e_res_postNorm[LAMP_FLOAT_E_DW-1:0], f_res_postNorm};
		valid		= fd_valid;
		isToRound	= ~isCheckNanInfValid;
		isOverflow	= isOverflow_postNorm;
		isUnderflow	= isUnderflow_postNorm;
	end

endmodule
