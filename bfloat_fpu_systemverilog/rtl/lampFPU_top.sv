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

module lampFPU_top (
	clk, rst,
	flush_i, padv_i,
	opcode_i, rndMode_i, op1_i, op2_i,
	result_o, isResultValid_o, isReady_o
);

import lampFPU_pkg::*;

input									clk;
input									rst;
input									flush_i;	// Flush the FPU invalidating the current operation
input									padv_i;		// Pipeline advance signal: accept new operation
input	opcodeFPU_t						opcode_i;
input	rndModeFPU_t					rndMode_i;
input			[LAMP_INTEGER_DW-1:0]	op1_i;
input			[LAMP_FLOAT_DW-1:0]		op2_i;

output	logic	[LAMP_INTEGER_DW-1:0]	result_o;
output	logic							isResultValid_o;
output	logic							isReady_o;

// INPUT wires: to drive registered input
	logic 									flush_r, flush_r_next;
	opcodeFPU_t								opcode_r, opcode_r_next;
	rndModeFPU_t							rndMode_r, rndMode_r_next;
	logic	[LAMP_INTEGER_DW-1:0]			op1_r, op1_r_next;

// OUTPUT wires: to drive registered output
	logic	[LAMP_INTEGER_DW-1:0]			result_o_next;
	logic									isResultValid_o_next;
	logic									fpcsr_o_next;

	//	add/sub outputs
	logic									addsub_s_res;
	logic	[LAMP_FLOAT_E_DW-1:0]			addsub_e_res;
	logic	[LAMP_FLOAT_F_DW+5-1:0]			addsub_f_res;
	logic									addsub_valid;
	logic									addsub_isOverflow;
	logic									addsub_isUnderflow;
	logic									addsub_isToRound;

	//	mul outputs
	logic									mul_s_res;
	logic	[LAMP_FLOAT_E_DW-1:0]			mul_e_res;
	logic	[LAMP_FLOAT_F_DW+5-1:0]			mul_f_res;
	logic									mul_valid;
	logic									mul_isOverflow;
	logic									mul_isUnderflow;
	logic									mul_isToRound;

	//	div outputs
	logic									div_s_res;
	logic	[LAMP_FLOAT_E_DW-1:0]			div_e_res;
	logic	[LAMP_FLOAT_F_DW+5-1:0]			div_f_res;
	logic									div_valid;
	logic									div_isOverflow;
	logic									div_isUnderflow;
	logic									div_isToRound;

	//	f2i outputs
	logic									f2i_s_res;
	logic	[(LAMP_INTEGER_DW+3)-1:0] 		f2i_f_res;
	logic									f2i_valid;
	logic									f2i_isOverflow;
	logic									f2i_isUnderflow;
	logic									f2i_isSNaN;

	//	i2f outputs
	logic									i2f_s_res;
	logic	[LAMP_FLOAT_E_DW-1:0]			i2f_e_res;
	logic	[LAMP_FLOAT_F_DW+5-1:0]			i2f_f_res;
	logic									i2f_valid;
	logic									i2f_isOverflow;
	logic									i2f_isUnderflow;
	logic									i2f_isToRound;

	//	cmp outputs
	logic									cmp_res;
	logic									cmp_isResValid;
	logic									cmp_isCmpInvalid;

	//	log	outputs
	logic									log_s_res;
	logic	[LAMP_FLOAT_E_DW-1:0]			log_e_res;
	logic	[LAMP_FLOAT_F_DW+5-1:0]			log_f_res;
	logic									log_valid;
	logic									log_isOverflow;
	logic									log_isUnderflow;
	logic									log_isToRound;

	logic	[LAMP_FLOAT_DW-1:0]				i2f_res;
	logic									i2f_isResValid;
	logic									i2f_isResInexact;
	logic	[LAMP_INTEGER_DW-1:0]			f2i_res;
	logic									f2i_isResValid;
	logic									f2i_isResSNaN;
	logic									f2i_isResZero;
	logic									f2i_isResInexact;
	logic									f2i_isResInvalid;

	logic									doAddSub_r, doAddSub_r_next;
	logic									isOpSub_r, isOpSub_r_next;
	logic									doMul_r, doMul_next;
	logic									doDiv_r, doDiv_next;
	logic									doF2i_r, doF2i_next;
	logic									doI2f_r, doI2f_next;
	logic									doCmpEq_r, doCmpEq_next;
	logic									doCmpLt_r, doCmpLt_next;
	logic									doCmpLe_r, doCmpLe_next;

	logic									doLog_r, doLog_next;

	// FUs results and valid bits
	logic	[LAMP_INTEGER_DW-1:0]			res;
	logic									isResValid;

	logic	[LAMP_FLOAT_S_DW-1:0] 			s_op1_r;
	logic	[LAMP_FLOAT_E_DW-1:0] 			e_op1_r;
	logic	[LAMP_FLOAT_F_DW-1:0] 			f_op1_r;
	logic	[(LAMP_FLOAT_F_DW+1)-1:0] 		extF_op1_r;
	logic	[(LAMP_FLOAT_E_DW+1)-1:0] 		extE_op1_r;
	logic									isInf_op1_r;
	logic									isZ_op1_r;
	logic									isSNAN_op1_r;
	logic									isQNAN_op1_r;
	logic	[LAMP_FLOAT_S_DW-1:0] 			s_op2_r;
	logic	[LAMP_FLOAT_E_DW-1:0] 			e_op2_r;
	logic	[LAMP_FLOAT_F_DW-1:0] 			f_op2_r;
	logic	[(LAMP_FLOAT_F_DW+1)-1:0] 		extF_op2_r;
	logic	[(LAMP_FLOAT_E_DW+1)-1:0] 		extE_op2_r;
	logic									isInf_op2_r;
	logic									isZ_op2_r;
	logic									isSNAN_op2_r;
	logic									isQNAN_op2_r;
	//	add/sub only
	logic									op1_GT_op2_r;
	logic	[LAMP_FLOAT_E_DW+1-1 : 0] 		e_diff_r;
	//	mul/div only
	logic	[(1+LAMP_FLOAT_F_DW)-1:0] 		extShF_op1_r;
	logic	[$clog2(1+LAMP_FLOAT_F_DW)-1:0]	nlz_op1_r;
	logic	[(1+LAMP_FLOAT_F_DW)-1:0] 		extShF_op2_r;
	logic	[$clog2(1+LAMP_FLOAT_F_DW)-1:0]	nlz_op2_r;

	//	pre-operation wires/regs
	logic	[LAMP_FLOAT_S_DW-1:0] 			s_op1_wire;
	logic	[LAMP_FLOAT_E_DW-1:0] 			e_op1_wire;
	logic	[LAMP_FLOAT_F_DW-1:0] 			f_op1_wire;
	logic	[(LAMP_FLOAT_F_DW+1)-1:0] 		extF_op1_wire;
	logic	[(LAMP_FLOAT_E_DW+1)-1:0] 		extE_op1_wire;
	logic									isDN_op1_wire;
	logic									isZ_op1_wire;
	logic									isInf_op1_wire;
	logic									isSNAN_op1_wire;
	logic									isQNAN_op1_wire;
	logic	[LAMP_FLOAT_S_DW-1:0] 			s_op2_wire;
	logic	[LAMP_FLOAT_E_DW-1:0] 			e_op2_wire;
	logic	[LAMP_FLOAT_F_DW-1:0] 			f_op2_wire;
	logic	[(LAMP_FLOAT_F_DW+1)-1:0] 		extF_op2_wire;
	logic	[(LAMP_FLOAT_E_DW+1)-1:0] 		extE_op2_wire;
	logic									isDN_op2_wire;
	logic									isZ_op2_wire;
	logic									isInf_op2_wire;
	logic									isSNAN_op2_wire;
	logic									isQNAN_op2_wire;
	//	add/sub only
	logic									op1_GT_op2_wire;
	logic	[LAMP_FLOAT_E_DW+1-1 : 0] 		e_diff_wire;
	//	mul/div only
	logic	[(1+LAMP_FLOAT_F_DW)-1:0] 		extShF_op1_wire;
	logic	[$clog2(1+LAMP_FLOAT_F_DW)-1:0]	nlz_op1_wire;
	logic	[(1+LAMP_FLOAT_F_DW)-1:0] 		extShF_op2_wire;
	logic	[$clog2(1+LAMP_FLOAT_F_DW)-1:0]	nlz_op2_wire;
	

	//	pre-rounding wires/regs
	logic									s_res;
	logic	[LAMP_FLOAT_E_DW-1:0]			e_res;
	logic	[LAMP_FLOAT_F_DW+5-1:0]			f_res;
	logic									isOverflow;
	logic									isUnderflow;
	logic									isToRound;

	// post-rounding wires/regs
	logic									s_res_postRnd;
	logic	[LAMP_FLOAT_F_DW-1:0]			f_res_postRnd;
	logic	[LAMP_FLOAT_E_DW-1:0]			e_res_postRnd;
	logic	[LAMP_INTEGER_DW-1:0]			res_postRnd;
	logic									isOverflow_postRnd;
	logic									isUnderflow_postRnd;

	// integer post-rounding wires/regs
	logic									f2i_s_res_postRnd;
	logic	[LAMP_INTEGER_DW-1:0]			f2i_f_res_postRnd;
	logic	[LAMP_INTEGER_DW-1:0]			f2i_res_postRnd;
	logic									f2i_isOverflow_postRnd;
	logic									f2i_isUnderflow_postRnd;
	logic									f2i_isInvalid_postRnd;

//////////////////////////////////////////////////////////////////
// 							state enum							//
//////////////////////////////////////////////////////////////////

	typedef enum logic [1:0]
	{
		IDLE	= 'd0,
		WORK	= 'd1,
		DONE	= 'd2
	}	ssFpuTop_t;

	ssFpuTop_t 	ss, ss_next;

//////////////////////////////////////////////////////////////////
// 						sequential logic						//
//////////////////////////////////////////////////////////////////

	always_ff @(posedge clk)
	begin
		if (rst)
		begin
			ss					<=	IDLE;
		//input
			doAddSub_r			<=	1'b0;
			isOpSub_r			<=	1'b0;
			doMul_r				<=	1'b0;
			doDiv_r				<=	1'b0;
			doF2i_r				<=	1'b0;
			doI2f_r				<=	1'b0;
			doCmpEq_r			<=	1'b0;
			doCmpLt_r			<=	1'b0;
			doCmpLe_r			<=	1'b0;
			flush_r				<=	1'b0;
			opcode_r			<=	FPU_IDLE;
			rndMode_r			<=	FPU_RNDMODE_NEAREST;
			op1_r				<=	'0;
			doLog_r				<= 	1'b0;
		//output
			result_o			<=	'0;
			isResultValid_o		<=	1'b0;
			//fpcsr_o			<=	'0;
		end
		else
		begin
			ss					<=	ss_next;
		//input
			doAddSub_r			<=	doAddSub_r_next;
			isOpSub_r			<=	isOpSub_r_next;
			doMul_r				<=	doMul_next;
			doDiv_r				<=	doDiv_next;
			doF2i_r				<=	doF2i_next;
			doI2f_r				<=	doI2f_next;
			doCmpEq_r			<=	doCmpEq_next;
			doCmpLt_r			<=	doCmpLt_next;
			doCmpLe_r			<=	doCmpLe_next;
			flush_r				<=	flush_r_next;
			opcode_r			<=	opcode_r_next;
			rndMode_r			<=	rndMode_r_next;
			op1_r				<=	op1_r_next;
			doLog_r				<= doLog_next;
		//output
			result_o			<=	result_o_next;
			isResultValid_o		<=	isResultValid_o_next;
			//fpcsr_o			<=	fpcsr_o_next;
		end
	end

//////////////////////////////////////////////////////////////////
// 						combinational logic						//
//////////////////////////////////////////////////////////////////

	always_comb
	begin
		ss_next					=	ss;
		doAddSub_r_next			=	1'b0;
		isOpSub_r_next			=	1'b0;
		doMul_next				=	1'b0;
		doDiv_next				=	1'b0;
		doF2i_next				=	1'b0;
		doI2f_next				=	1'b0;
		doCmpEq_next			=	1'b0;
		doCmpLt_next			=	1'b0;
		doCmpLe_next			=	1'b0;
		doLog_next				=	1'b0; 

		flush_r_next			=	flush_r;
		opcode_r_next			=	opcode_r;
		rndMode_r_next			=	rndMode_r;
		op1_r_next				=	op1_r;
		result_o_next			=	result_o;
		isResultValid_o_next	=	isResultValid_o;

		s_res					=	1'b0;
		e_res					=	'0;
		f_res					=	'0;
		isOverflow				=	1'b0;
		isUnderflow				=	1'b0;
		isToRound				=	1'b0;

		res						=	'0;
		isResValid				=	1'b0;
		case (ss)
			IDLE:
			begin

				// NOTE: the flush signal can only be set during the first cycle
				// the fpu starts operating on the inputs, after the pipeline has advanced.
				// Therefore, if asserted, avoid executing the current operation
				// and don't start any functional unit. We need a more robust solution
				// here in the future: internal functional units must have one flush_i
				// signal each that resets their inner status in case of flush


				if (opcode_i != FPU_IDLE && !flush_i)
				begin
					ss_next							=	WORK;
					case (opcode_i)
						FPU_ADD	:
						begin
									doAddSub_r_next	=	1'b1;
									isOpSub_r_next	=	1'b0;
						end
						FPU_SUB	:
						begin
									doAddSub_r_next	=	1'b1;
									isOpSub_r_next	=	1'b1;
						end
						FPU_MUL	:	doMul_next		=	1'b1;
						FPU_DIV	:	doDiv_next		=	1'b1;
						FPU_F2I	:	doF2i_next		=	1'b1;
						FPU_I2F	:	doI2f_next		=	1'b1;
						FPU_EQ	:	doCmpEq_next	=	1'b1;
						FPU_LT	:	doCmpLt_next	=	1'b1;
						FPU_LE	:	doCmpLe_next	=	1'b1;
						FPU_LOG	:	doLog_next		= 	1'b1;
					endcase
					flush_r_next						=	'0;
					opcode_r_next						=	opcode_i;
					rndMode_r_next						=	rndMode_i;
					op1_r_next							=	op1_i;
				end
			end
			WORK:
			begin
				case (opcode_r)
					FPU_ADD, FPU_SUB:
					begin
						s_res						=	addsub_s_res;
						e_res						=	addsub_e_res;
						f_res						=	addsub_f_res;
						isOverflow					=	addsub_isOverflow;
						isUnderflow					=	addsub_isUnderflow;
						isToRound					=	addsub_isToRound;

						res							=	res_postRnd;
						isResValid					=	addsub_valid;
					end
					FPU_MUL:
					begin
						s_res						=	mul_s_res;
						e_res						=	mul_e_res;
						f_res						=	mul_f_res;
						isOverflow					=	mul_isOverflow;
						isUnderflow					=	mul_isUnderflow;
						isToRound					=	mul_isToRound;

						res							=	res_postRnd;
						isResValid					=	mul_valid;
					end
					FPU_DIV:
					begin
						s_res						=	div_s_res;
						e_res						=	div_e_res;
						f_res						=	div_f_res;
						isOverflow					=	div_isOverflow;
						isUnderflow					=	div_isUnderflow;
						isToRound					=	div_isToRound;

						res							=	res_postRnd;
						isResValid					=	div_valid;
					end
					FPU_F2I:
					begin
						res							=	f2i_res_postRnd;
						isResValid					=	f2i_valid;
					end
					FPU_I2F:
					begin
						s_res						=	i2f_s_res;
						e_res						=	i2f_e_res;
						f_res						=	i2f_f_res;
						isOverflow					=	i2f_isOverflow;
						isUnderflow					=	i2f_isUnderflow;
						isToRound					=	i2f_isToRound;

						res							=	res_postRnd;
						isResValid					=	i2f_valid;
					end
					FPU_EQ, FPU_LT, FPU_LE:
					begin
						res							=	{{(LAMP_INTEGER_DW-1){1'b0}}, cmp_res};
						isResValid					=	cmp_isResValid;
					end
					FPU_LOG:
					begin
						s_res						=	log_s_res;
						e_res						=	log_e_res;
						f_res						=	log_f_res;
						isOverflow					=	log_isOverflow;
						isUnderflow					=	log_isUnderflow;
						isToRound					=	log_isToRound;

						res							=	res_postRnd;
						isResValid					=	log_valid;
					end
				endcase

				if (isResValid)
				begin
					result_o_next					=	res;
					isResultValid_o_next			=	1'b1;
					ss_next							=	DONE;
				end
			end
			DONE:
			begin
				if (padv_i)
				begin
					isResultValid_o_next			=  1'b0;
					ss_next							=	IDLE;
				end
			end
		endcase
	end

//////////////////////////////////////////////////////////////////
// 			operands pre-processing	- sequential logic			//
//////////////////////////////////////////////////////////////////

	always_ff @(posedge clk)
	begin
		if (rst)
		begin
			s_op1_r			<=	'0;
			e_op1_r			<=	'0;
			f_op1_r			<=	'0;
			extF_op1_r		<=	'0;
			extE_op1_r		<=	'0;
			isInf_op1_r		<=	'0;
			isZ_op1_r		<=	'0;
			isSNAN_op1_r	<=	'0;
			isQNAN_op1_r	<=	'0;
			s_op2_r			<=	'0;
			e_op2_r			<=	'0;
			f_op2_r			<=	'0;
			extF_op2_r		<=	'0;
			extE_op2_r		<=	'0;
			isInf_op2_r		<=	'0;
			isZ_op2_r		<=	'0;
			isSNAN_op2_r	<=	'0;
			isQNAN_op2_r	<=	'0;
			//	add/sub only
			op1_GT_op2_r	<=	'0;
			e_diff_r		<=	'0;
			//	mul/div only
			extShF_op1_r	<=	'0;
			nlz_op1_r		<=	'0;
			extShF_op2_r	<=	'0;
			nlz_op2_r		<=	'0;
		end
		else
		begin
			s_op1_r			<=	s_op1_wire;
			e_op1_r			<=	e_op1_wire;
			f_op1_r			<=	f_op1_wire;
			extF_op1_r		<=	extF_op1_wire;
			extE_op1_r		<=	extE_op1_wire;
			isInf_op1_r		<=	isInf_op1_wire;
			isZ_op1_r		<=	isZ_op1_wire;
			isSNAN_op1_r	<=	isSNAN_op1_wire;
			isQNAN_op1_r	<=	isQNAN_op1_wire;
			s_op2_r			<=	s_op2_wire;
			e_op2_r			<=	e_op2_wire;
			f_op2_r			<=	f_op2_wire;
			extF_op2_r		<=	extF_op2_wire;
			extE_op2_r		<=	extE_op2_wire;
			isInf_op2_r		<=	isInf_op2_wire;
			isZ_op2_r		<=	isZ_op2_wire;
			isSNAN_op2_r	<=	isSNAN_op2_wire;
			isQNAN_op2_r	<=	isQNAN_op2_wire;
			//	add/sub only
			op1_GT_op2_r	<=	op1_GT_op2_wire;
			e_diff_r		<=	e_diff_wire;
			//	mul/div only
			extShF_op1_r	<=	extShF_op1_wire;
			nlz_op1_r		<=	nlz_op1_wire;
			extShF_op2_r	<=	extShF_op2_wire;
			nlz_op2_r		<=	nlz_op2_wire;
		end
	end

//////////////////////////////////////////////////////////////////
// 			operands pre-processing	- combinational logic		//
//////////////////////////////////////////////////////////////////

	always_comb
	begin
		{s_op1_wire, e_op1_wire, f_op1_wire}										= FUNC_splitOperand(op1_i[LAMP_FLOAT_DW-1:0]);
		{isInf_op1_wire,isDN_op1_wire,isZ_op1_wire,isSNAN_op1_wire,isQNAN_op1_wire}	= FUNC_checkOperand(op1_i[LAMP_FLOAT_DW-1:0]);
		extE_op1_wire																= FUNC_extendExp(e_op1_wire, isDN_op1_wire);
		extF_op1_wire 																= FUNC_extendFrac(f_op1_wire, isDN_op1_wire, isZ_op1_wire);

		{s_op2_wire, e_op2_wire, f_op2_wire}										= FUNC_splitOperand(op2_i);
		{isInf_op2_wire,isDN_op2_wire,isZ_op2_wire,isSNAN_op2_wire,isQNAN_op2_wire}	= FUNC_checkOperand(op2_i);
		extE_op2_wire																= FUNC_extendExp(e_op2_wire, isDN_op2_wire);
		extF_op2_wire 																= FUNC_extendFrac(f_op2_wire, isDN_op2_wire, isZ_op2_wire);

		//	add/sub only
		op1_GT_op2_wire																= FUNC_op1_GT_op2(extF_op1_wire, extE_op1_wire, extF_op2_wire, extE_op2_wire);
		e_diff_wire																	= op1_GT_op2_wire ? (extE_op1_wire - extE_op2_wire) : (extE_op2_wire - extE_op1_wire);

		//	mul/div only
		nlz_op1_wire																= FUNC_numLeadingZeros(extF_op1_wire);
		nlz_op2_wire																= FUNC_numLeadingZeros(extF_op2_wire);
		extShF_op1_wire																= extF_op1_wire << nlz_op1_wire;
		extShF_op2_wire																= extF_op2_wire << nlz_op2_wire;
	end

	// NOTE: fpu ready signal that makes the pipeline to advance.
	// It is simple and plain combinational logic: this should require
	// some cpu-side optimizations to improve the overall system timing
	// in the future. The entire advancing mechanism should be re-designed
	// from scratch

	assign isReady_o = (opcode_i == FPU_IDLE) | isResultValid_o;

//////////////////////////////////////////////////////////////////
// 				float rounding - combinational logic			//
//////////////////////////////////////////////////////////////////

	always_comb
	begin
		if (rndMode_r == FPU_RNDMODE_NEAREST)
			f_res_postRnd	= FUNC_rndToNearestEven(f_res);
		else
			f_res_postRnd	= f_res[3+:LAMP_FLOAT_F_DW];		//f_res[9 : 3]
		if (isToRound)
			res_postRnd		= {s_res, e_res, f_res_postRnd};				//res_postRnd is a 32 bit vector 
		else
			res_postRnd		= {s_res, e_res, f_res[5+:LAMP_FLOAT_F_DW]};
	end

//////////////////////////////////////////////////////////////////
// 				integer rounding - combinational logic			//
//////////////////////////////////////////////////////////////////

	always_comb
	begin
		if (rndMode_r == FPU_RNDMODE_NEAREST)
			f2i_f_res_postRnd	= FUNC_f2i_rndToNearestEven(f2i_f_res);
		else
			f2i_f_res_postRnd	= f2i_f_res[3+:LAMP_INTEGER_DW];

		f2i_res_postRnd			= (f2i_f_res_postRnd ^ {LAMP_INTEGER_DW{f2i_s_res}}) + f2i_s_res;
		f2i_isInvalid_postRnd	= ((~f2i_s_res) & f2i_f_res_postRnd[LAMP_INTEGER_DW-1]) | f2i_isOverflow | f2i_isSNaN;
	end

//////////////////////////////////////////////////////////////////
//						internal submodules						//
//////////////////////////////////////////////////////////////////

	lampFPU_addsub
		lampFPU_addsub(
			.clk					(clk),
			.rst					(rst),
			//	inputs
			.doAddSub_i				(doAddSub_r),
			.isOpSub_i 				(isOpSub_r),
			.s_op1_i				(s_op1_r),
			.extF_op1_i				(extF_op1_r),
			.extE_op1_i				(extE_op1_r),
			.isInf_op1_i			(isInf_op1_r),
			.isSNAN_op1_i			(isSNAN_op1_r),
			.isQNAN_op1_i			(isQNAN_op1_r),
			.s_op2_i				(s_op2_r),
			.extF_op2_i				(extF_op2_r),
			.extE_op2_i				(extE_op2_r),
			.isInf_op2_i			(isInf_op2_r),
			.isSNAN_op2_i			(isSNAN_op2_r),
			.isQNAN_op2_i			(isQNAN_op2_r),
			.op1_GT_op2_i			(op1_GT_op2_r),
			.e_diff_i				(e_diff_r),
			//	outputs
			.s_res_o				(addsub_s_res),
			.e_res_o				(addsub_e_res),
			.f_res_o				(addsub_f_res),
			.valid_o				(addsub_valid),
			.isOverflow_o			(addsub_isOverflow),
			.isUnderflow_o			(addsub_isUnderflow),
			.isToRound_o			(addsub_isToRound)
		);

	lampFPU_mul
		lampFPU_mul0 (
			.clk					(clk),
			.rst					(rst),
			//	inputs
			.doMul_i				(doMul_r),
			.s_op1_i				(s_op1_r),
			.extShF_op1_i			(extShF_op1_r),
			.extE_op1_i				(extE_op1_r),
			.nlz_op1_i				(nlz_op1_r),
			.isZ_op1_i				(isZ_op1_r),
			.isInf_op1_i			(isInf_op1_r),
			.isSNAN_op1_i			(isSNAN_op1_r),
			.isQNAN_op1_i			(isQNAN_op1_r),
			.s_op2_i				(s_op2_r),
			.extShF_op2_i			(extShF_op2_r),
			.extE_op2_i				(extE_op2_r),
			.nlz_op2_i				(nlz_op2_r),
			.isZ_op2_i				(isZ_op2_r),
			.isInf_op2_i			(isInf_op2_r),
			.isSNAN_op2_i			(isSNAN_op2_r),
			.isQNAN_op2_i			(isQNAN_op2_r),
			//	outputs
			.s_res_o				(mul_s_res),
			.e_res_o				(mul_e_res),
			.f_res_o				(mul_f_res),
			.valid_o				(mul_valid),
			.isOverflow_o			(mul_isOverflow),
			.isUnderflow_o			(mul_isUnderflow),
			.isToRound_o			(mul_isToRound)
		);

	lampFPU_div
		lampFPU_div0 (
			.clk					(clk),
			.rst					(rst),
			//	inputs
			.doDiv_i				(doDiv_r),
			.s_op1_i				(s_op1_r),
			.extShF_op1_i			(extShF_op1_r),
			.extE_op1_i				(extE_op1_r),
			.nlz_op1_i				(nlz_op1_r),
			.isZ_op1_i				(isZ_op1_r),
			.isInf_op1_i			(isInf_op1_r),
			.isSNAN_op1_i			(isSNAN_op1_r),
			.isQNAN_op1_i			(isQNAN_op1_r),
			.s_op2_i				(s_op2_r),
			.extShF_op2_i			(extShF_op2_r),
			.extE_op2_i				(extE_op2_r),
			.nlz_op2_i				(nlz_op2_r),
			.isZ_op2_i				(isZ_op2_r),
			.isInf_op2_i			(isInf_op2_r),
			.isSNAN_op2_i			(isSNAN_op2_r),
			.isQNAN_op2_i			(isQNAN_op2_r),
			//	outputs
			.s_res_o				(div_s_res),
			.e_res_o				(div_e_res),
			.f_res_o				(div_f_res),
			.valid_o				(div_valid),
			.isOverflow_o			(div_isOverflow),
			.isUnderflow_o			(div_isUnderflow),
			.isToRound_o			(div_isToRound)
		);

	lampFPU_f2i
		lampFPU_f2i0 (
			.clk					(clk),
			.rst					(rst),
			//	inputs
			.doF2i_i				(doF2i_r),
			.s_op1_i				(s_op1_r),
			.extF_op1_i				(extF_op1_r),
			.extE_op1_i				(extE_op1_r),
			.isSNAN_op1_i			(isSNAN_op1_r),
			.isQNAN_op1_i			(isQNAN_op1_r),
			//	outputs
			.s_res_o				(f2i_s_res),
			.f_res_o				(f2i_f_res),
			.valid_o				(f2i_valid),
			.isOverflow_o			(f2i_isOverflow),
			.isUnderflow_o			(f2i_isUnderflow),
			.isSNaN_o				(f2i_isSNaN)
		);

	lampFPU_i2f
		lampFPU_i2f0 (
			.clk					(clk),
			.rst					(rst),
			//	inputs
			.doI2f_i				(doI2f_r),
			.op1_i					(op1_r),
			//	outputs
			.s_res_o				(i2f_s_res),
			.e_res_o				(i2f_e_res),
			.f_res_o				(i2f_f_res),
			.valid_o				(i2f_valid),
			.isOverflow_o			(i2f_isOverflow),
			.isUnderflow_o			(i2f_isUnderflow),
			.isToRound_o			(i2f_isToRound)
		);

	lampFPU_cmp
		lampFPU_cmp0 (
			.clk					(clk),
			.rst					(rst),
			//	inputs
			.doEq_i					(doCmpEq_r),
			.doLt_i					(doCmpLt_r),
			.doLe_i					(doCmpLe_r),
			.opASign_i				(s_op1_r),
			.opAExp_i				(e_op1_r),
			.opAFract_i				(f_op1_r),
			.opBSign_i				(s_op2_r),
			.opBExp_i				(e_op2_r),
			.opBFract_i				(f_op2_r),
			.isAZer_i				(isZ_op1_r),
			.isASNaN_i				(isSNAN_op1_r),
			.isAQNaN_i				(isQNAN_op1_r),
			.isBZer_i				(isZ_op2_r),
			.isBSNaN_i				(isSNAN_op2_r),
			.isBQNaN_i				(isQNAN_op2_r),
			//	outputs
			.cmp_o					(cmp_res),
			.isCmpValid_o			(cmp_isResValid),
			.isCmpInvalid_o			(cmp_isCmpInvalid)
		);

	lampFPU_log
		lampFPU_log0 (
			.clk					(clk),
			.rst					(rst),
			//	inputs
			.doLog_i				(doLog_r),
			.s_op_i				    (s_op1_r),
			.extE_op1_i             (extE_op1_r),
			.extF_op1_i             (extF_op1_r),
			.isZ_op_i				(isZ_op1_r),
			.isInf_op_i			    (isInf_op1_r),
			.isSNAN_op_i			(isSNAN_op1_r),
			.isQNAN_op_i			(isQNAN_op1_r),
			//	outputs
			.s_res_o				(log_s_res),
			.e_res_o				(log_e_res),
			.f_res_o				(log_f_res),
			.valid_o				(log_valid),
			.isOverflow_o			(log_isOverflow),
			.isUnderflow_o			(log_isUnderflow),
			.isToRound_o			(log_isToRound)
		);

endmodule
