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

package lampFPU_pkg;

	parameter LAMP_FLOAT_DW		=	16;
	parameter LAMP_FLOAT_S_DW 	=	1;
	parameter LAMP_FLOAT_E_DW 	=	8;
	parameter LAMP_FLOAT_F_DW 	=	7;

	parameter LAMP_INTEGER_DW	=	32;
	parameter LAMP_INTEGER_S_DW	=	1;
	parameter LAMP_INTEGER_F_DW	=	31;

	parameter LAMP_FLOAT_E_BIAS	=	(2 ** (LAMP_FLOAT_E_DW - 1)) - 1;
	parameter LAMP_FLOAT_E_MAX	=	(2 ** LAMP_FLOAT_E_DW) - 1;

	parameter INF				=	15'h7f80;
	parameter ZERO				=	15'h0000;
	parameter SNAN				=	15'h7fbf;		//signaling nan
	parameter QNAN				=	15'h7fc0;		//quiet nan

	//	used in TB only
	parameter PLUS_INF			=	16'h7f80;
	parameter MINUS_INF			=	16'hff80;
	parameter PLUS_ZERO			=	16'h0000;
	parameter MINUS_ZERO		=	16'h8000;

	parameter INF_E_F			=	15'b111111110000000; // w/o sign
	parameter SNAN_E_F			=	15'b111111110111111; // w/o sign
	parameter QNAN_E_F			=	15'b111111111000000; // w/o sign
	parameter ZERO_E_F			=	15'b000000000000000; // w/o sign

	//	div-only
	parameter LAMP_APPROX_DW	=	4;
	parameter LAMP_PREC_DW		=	8;
	parameter LAMP_APPROX_MULS	=	$clog2 ((LAMP_FLOAT_DW+1)/LAMP_APPROX_DW);

	typedef enum logic
	{
		FPU_RNDMODE_NEAREST		=	'd0,
		FPU_RNDMODE_TRUNCATE	=	'd1
	} rndModeFPU_t;

	typedef enum logic[3:0]
	{
		FPU_IDLE	= 4'd0,

		FPU_I2F		= 4'd1,
		FPU_F2I		= 4'd2,

		FPU_ADD		= 4'd3,
		FPU_SUB		= 4'd4,
		FPU_MUL		= 4'd5,
		FPU_DIV		= 4'd6,

		FPU_EQ		= 4'd7,
		FPU_LT		= 4'd8,
		FPU_LE		= 4'd9,

		FPU_LOG		= 4'd10
	} opcodeFPU_t;

	function automatic logic [LAMP_FLOAT_S_DW+LAMP_FLOAT_E_DW+LAMP_FLOAT_F_DW-1:0] FUNC_splitOperand(input [LAMP_FLOAT_DW-1:0] op);
		return op;
	endfunction

	function automatic logic [LAMP_FLOAT_E_DW+1-1:0] FUNC_extendExp(input [LAMP_FLOAT_E_DW-1:0] e_op, input isDN);
		return	{ 1'b0, e_op[7:1], (e_op[0] | isDN) };
	endfunction

	function automatic logic [LAMP_FLOAT_F_DW+1-1:0] FUNC_extendFrac(input [LAMP_FLOAT_F_DW-1:0] f_op, input isDN, input isZ);
		return	{ (~isDN & ~isZ), f_op};
	endfunction

	function automatic logic FUNC_op1_GT_op2(
			input [LAMP_FLOAT_F_DW+1-1:0] f_op1, input [LAMP_FLOAT_E_DW+1-1:0] e_op1,
			input [LAMP_FLOAT_F_DW+1-1:0] f_op2, input [LAMP_FLOAT_E_DW+1-1:0] e_op2
	);
		logic 		e_op1_GT_op2, e_op1_EQ_op2;
		logic 		f_op1_GT_op2;
		logic 		op1_GT_op2, op1_EQ_op2;

		e_op1_GT_op2 	= (e_op1 > e_op2);
		e_op1_EQ_op2 	= (e_op1 == e_op2);

		f_op1_GT_op2 	= (f_op1 > f_op2);

		op1_GT_op2		= e_op1_GT_op2 | (e_op1_EQ_op2 & f_op1_GT_op2);

		return	op1_GT_op2;
	endfunction

	function automatic logic [$clog2(1+1+LAMP_FLOAT_F_DW+3)-1:0] FUNC_AddSubPostNorm_numLeadingZeros( input [1+1+LAMP_FLOAT_F_DW+3-1:0] f_initial_res);

		casez(f_initial_res)
			12'b1???????????: return  'd0;
			12'b01??????????: return  'd0;
			12'b001?????????: return  'd1;
			12'b0001????????: return  'd2;
			12'b00001???????: return  'd3;
			12'b000001??????: return  'd4;
			12'b0000001?????: return  'd5;
			12'b00000001????: return  'd6;
			12'b000000001???: return  'd7;
			12'b0000000001??: return  'd8;
			12'b00000000001?: return  'd9;
			12'b000000000001: return  'd10;
			12'b000000000000: return  'd0; // zero result
		endcase
	endfunction

	function automatic logic [$clog2(LAMP_FLOAT_F_DW+1)-1:0] FUNC_numLeadingZeros(
					input logic [(LAMP_FLOAT_F_DW+1)-1:0] f_i
				);
				    casez(f_i)
				      8'b1???????: return 'd0;
				      8'b01??????: return 'd1;
				      8'b001?????: return 'd2;
				      8'b0001????: return 'd3;
				      8'b00001???: return 'd4;
				      8'b000001??: return 'd5;
				      8'b0000001?: return 'd6;
				      8'b00000001: return 'd7;
				      8'b00000000: return 'd0; // zero result
    				endcase
	endfunction

	function automatic logic [5-1:0] FUNC_checkOperand(input [LAMP_FLOAT_DW-1:0] op);
		logic [LAMP_FLOAT_S_DW-1:0] s_op;
		logic [LAMP_FLOAT_E_DW-1:0] e_op;
		logic [LAMP_FLOAT_F_DW-1:0] f_op;

		logic isInf_op, isDN_op, isZ_op, isSNAN_op, isQNAN_op;
		s_op = op[15];
		e_op = op[14-:8];
		f_op = op[8:0];

		// check deNorm (isDN), +/-inf (isInf), +/-zero (isZ), not a number (isSNaN, isQNaN)
		isInf_op 	= (&e_op) &  ~(|f_op); 					// E==0xFF	&&	f==0x0
		isDN_op 	= ~(|e_op) & (|f_op);					// E==0x0	&&	f!=0x0
		isZ_op 		= ~(|op[14:0]);							// E==0x0	&&	f==0x0
		isSNAN_op 	= (&e_op) & ~f_op[6] & (|f_op[5:0]);
		isQNAN_op 	= (&e_op) & f_op[6];

		return {isInf_op, isDN_op, isZ_op, isSNAN_op, isQNAN_op};
	endfunction

	function automatic logic [$clog2(LAMP_INTEGER_DW)-1:0] FUNC_i2f_integerExponent(
					input logic [LAMP_INTEGER_DW-1:0] int32_i
				);
					casez(int32_i)
						32'b1???????????????????????????????: return 'd31;
						32'b01??????????????????????????????: return 'd30;
						32'b001?????????????????????????????: return 'd29;
						32'b0001????????????????????????????: return 'd28;
						32'b00001???????????????????????????: return 'd27;
						32'b000001??????????????????????????: return 'd26;
						32'b0000001?????????????????????????: return 'd25;
						32'b00000001????????????????????????: return 'd24;
						32'b000000001???????????????????????: return 'd23;
						32'b0000000001??????????????????????: return 'd22;
						32'b00000000001?????????????????????: return 'd21;
						32'b000000000001????????????????????: return 'd20;
						32'b0000000000001???????????????????: return 'd19;
						32'b00000000000001??????????????????: return 'd18;
						32'b000000000000001?????????????????: return 'd17;
						32'b0000000000000001????????????????: return 'd16;
						32'b00000000000000001???????????????: return 'd15;
						32'b000000000000000001??????????????: return 'd14;
						32'b0000000000000000001?????????????: return 'd13;
						32'b00000000000000000001????????????: return 'd12;
						32'b000000000000000000001???????????: return 'd11;
						32'b0000000000000000000001??????????: return 'd10;
						32'b00000000000000000000001?????????: return 'd9;
						32'b000000000000000000000001????????: return 'd8;
						32'b0000000000000000000000001???????: return 'd7;
						32'b00000000000000000000000001??????: return 'd6;
						32'b000000000000000000000000001?????: return 'd5;
						32'b0000000000000000000000000001????: return 'd4;
						32'b00000000000000000000000000001???: return 'd3;
						32'b000000000000000000000000000001??: return 'd2;
						32'b0000000000000000000000000000001?: return 'd1;
						32'b0000000000000000000000000000000?: return 'd0;
					endcase
	endfunction

	function automatic logic FUNC_i2f_stickyBit(
					input logic [(LAMP_INTEGER_F_DW+3)-1:0] f_i,
					input logic [$clog2(LAMP_INTEGER_DW)-1:0] s_i
				);
					case (s_i)
						0	:	return 1'b0;
						1	:	return 1'b0;
						2	:	return f_i[3];
						3	:	return |f_i[4:3];
						4	:	return |f_i[5:3];
						5	:	return |f_i[6:3];
						6	:	return |f_i[7:3];
						7	:	return |f_i[8:3];
						8	:	return |f_i[9:3];
						9	:	return |f_i[10:3];
						10	:	return |f_i[11:3];
						11	:	return |f_i[12:3];
						12	:	return |f_i[13:3];
						13	:	return |f_i[14:3];
						14	:	return |f_i[15:3];
						15	:	return |f_i[16:3];
						16	:	return |f_i[17:3];
						17	:	return |f_i[18:3];
						18	:	return |f_i[19:3];
						19	:	return |f_i[20:3];
						20	:	return |f_i[21:3];
						21	:	return |f_i[22:3];
						22	:	return |f_i[23:3];
						23	:	return |f_i[24:3];
					endcase
	endfunction

	function automatic logic FUNC_f2i_stickyBit(
					input logic [(LAMP_INTEGER_DW+3)-1:0] f_i,
					input logic [$clog2(LAMP_INTEGER_DW)-1:0] s_i
				);
					case (s_i)
						0	:	return 1'b0;
						1	:	return 1'b0;
						2	:	return f_i[3];
						3	:	return |f_i[4:3];
						4	:	return |f_i[5:3];
						5	:	return |f_i[6:3];
						6	:	return |f_i[7:3];
						7	:	return |f_i[8:3];
						8	:	return |f_i[9:3];
					endcase
	endfunction

	/*
	* FUNC_addsub_calcStickyBit:
	*
	* Calculate the sticky bit in add sub operations.
	*
	* Input: the f mantissa extended with 3 LSB, i.e., G,R,S, one
	* hidden bit, i.e., MSB-1, and an extra MSB for ovf or 2'complement.
	*
	* Output: the computed sticky bit
	*/
	function automatic logic FUNC_addsub_calcStickyBit(
					input logic [(1+LAMP_FLOAT_F_DW+3)-1:0] f_i,
					input logic [(LAMP_FLOAT_E_DW+1)-1:0] num_shr_i
				);
			    case(num_shr_i)
			    	5'd0 :		return 1'b0;		// no right shift -> 0 sticky
					5'd1 :		return 1'b0;		// two added zero bits G,R
					5'd2 :		return 1'b0;		// two added zero bits G,R
					5'd3 :		return f_i[3];
					5'd4 :		return |f_i[3+:1];
			    	5'd5 :		return |f_i[3+:2];
			    	5'd6 :		return |f_i[3+:3];
			    	5'd7 :		return |f_i[3+:4];
			    	5'd8 :		return |f_i[3+:5];
			    	5'd9 :		return |f_i[3+:6];
					default:	return |f_i[3+:7];
			    endcase
		endfunction

	/* FUNC_rndToNearestEven (Round-to-nearest-even):
	*
	* Description: performs the round to nearest even required by the IEEE 754-SP standard
	* with a minor modification to trade performance/area with precision.
	* instead of adding .1 in some scenarios with a possible 23bit carry chain
	* the number of bit in the carry chain is configurable. This way if the
	* considered LSB of the f are all 1 a truncation is performed instead of
	* a rnd. This removes the possible normalization stage after rounding.
	*/
	function automatic logic[LAMP_FLOAT_F_DW-1:0] FUNC_rndToNearestEven
			(
				input [(1/*ovf*/+1/*hidden*/+LAMP_FLOAT_F_DW+3/*G,R,S*/)-1:0]		f_res_postNorm
			);

		localparam NUM_BIT_TO_RND	=	4;

		logic 								isAddOne;
		logic [(1+1+LAMP_FLOAT_F_DW+3)-1:0] tempF_1;
		logic [(1+1+LAMP_FLOAT_F_DW+3)-1:0] tempF;
		//
		// Rnd to nearest even
		//	X0.00 -> X0		|	X1.00 -> X1
		//	X0.01 -> X0		|	X1.01 -> X1
		//	X0.10 -> X0		|	X1.10 -> X1. +1
		//	X0.11 -> X1		|	X1.11 -> X1. +1
		//
		tempF_1 = f_res_postNorm;
		case(f_res_postNorm[3:1] /*3 bits X.G(S|R)*/ )
			3'b0_00:	begin tempF_1[3] = 0;	isAddOne =0; end
			3'b0_01:	begin tempF_1[3] = 0;	isAddOne =0; end
			3'b0_10:	begin tempF_1[3] = 0;	isAddOne =0; end
			3'b0_11:	begin tempF_1[3] = 1;	isAddOne =0; end
			3'b1_00:	begin tempF_1[3] = 1;	isAddOne =0; end
			3'b1_01:	begin tempF_1[3] = 1; 	isAddOne =0; end
			3'b1_10:	begin tempF_1[3] = 1;	isAddOne =1; end
			3'b1_11:	begin tempF_1[3] = 1;	isAddOne =1; end
		endcase

		// limit rnd to NUM_BIT_TO_RND LSBs of the f, truncate otherwise
		// this avoid another normalization step, if any
		if(&tempF_1[3+:NUM_BIT_TO_RND])
			tempF =	tempF_1 ;
		else
			tempF =	tempF_1 + (isAddOne<<3);

		return tempF[3+:LAMP_FLOAT_F_DW];
	endfunction

	function automatic logic[LAMP_INTEGER_DW-1:0] FUNC_f2i_rndToNearestEven
			(
				input [(LAMP_INTEGER_DW+3)-1:0]	f_res_postNorm
			);

		logic							isAddOne;
		logic	[LAMP_INTEGER_DW-1:0]	f_res;

		isAddOne	=	(f_res_postNorm[3] && f_res_postNorm[2]) || (f_res_postNorm[2] && f_res_postNorm[1]);
		f_res		=	f_res_postNorm[3+:LAMP_INTEGER_DW] + isAddOne;

		return f_res;
	endfunction

	/*
	* Nan +/- X	  -> Nan
	* X   +/- Nan -> Nan
	* +inf + +inf -> +inf
	* +inf - -inf -> +inf
	* -inf - +inf -> -inf
	* -inf + -inf -> -inf
	* +inf - inf -> NAN
	* -inf + inf -> NAN
	*/
	function automatic logic[3:0] FUNC_calcInfNanResAddSub (
				input isOpSub_i,
				input isInf_op1_i, input sign_op1_i, input isSNan_op1_i, input isQNan_op1_i,
				input isInf_op2_i, input sign_op2_i, input isSNan_op2_i, input isQNan_op2_i

			);

		logic realOp2_sign;
		logic isNan_op1 = isSNan_op1_i || isQNan_op1_i;
		logic isNan_op2 = isSNan_op2_i || isQNan_op2_i;

		logic isValidRes, isInfRes, isNanRes, signRes;
		realOp2_sign 	= sign_op2_i ^ isOpSub_i;

		isValidRes 		= (isInf_op1_i || isInf_op2_i || isNan_op1 || isNan_op2) ? 1 : 0;
		if (isNan_op1)
		begin //sign is not important, since a Nan remains a nan what-so-ever
			isInfRes = 0; isNanRes = 1; signRes = sign_op1_i;
		end
		else if (isNan_op2)
		begin
			isInfRes = 0; isNanRes = 1; signRes = sign_op2_i;
		end
		else // both are not NaN
		begin
			case({sign_op1_i, isInf_op1_i, realOp2_sign, isInf_op2_i})
				4'b00_00: begin isNanRes = 0; isInfRes = 0; signRes = 0; end
				4'b00_01: begin isNanRes = 0; isInfRes = 1; signRes = 0; end
				4'b00_10: begin isNanRes = 0; isInfRes = 0; signRes = 0; end
				4'b00_11: begin isNanRes = 0; isInfRes = 1; signRes = 1; end
				4'b01_00: begin isNanRes = 0; isInfRes = 1; signRes = 0; end
				4'b01_01: begin isNanRes = 0; isInfRes = 1; signRes = 0; end
				4'b01_10: begin isNanRes = 0; isInfRes = 1; signRes = 0; end
				4'b01_11: begin isNanRes = 1; isInfRes = 0; signRes = 1; end //Nan - NOTE sign goes neg if one of the operands is neg
				4'b10_00: begin isNanRes = 0; isInfRes = 0; signRes = 0; end
				4'b10_01: begin isNanRes = 0; isInfRes = 1; signRes = 0; end
				4'b10_10: begin isNanRes = 0; isInfRes = 0; signRes = 0; end
				4'b10_11: begin isNanRes = 0; isInfRes = 1; signRes = 1; end
				4'b11_00: begin isNanRes = 0; isInfRes = 1; signRes = 1; end
				4'b11_01: begin isNanRes = 1; isInfRes = 0; signRes = 1; end //Nan - NOTE sign goes neg if one of the operands is neg
				4'b11_10: begin isNanRes = 0; isInfRes = 1; signRes = 1; end
				4'b11_11: begin isNanRes = 0; isInfRes = 1; signRes = 1; end
			endcase
		end
		return {isValidRes, isInfRes, isNanRes, signRes};
	endfunction

	/*
	* 		Nan 	x 			X		-> 		 Nan
	* 		X 		x 			Nan 	-> 		 Nan
	* (+/-) inf 	x 	(+/-) 	inf 	-> (+/-) inf
	* (+/-) inf 	x 			0		-> 		 Nan
	* (+/-) inf		x 	(+/-)	X		-> (+/-) inf
	*/
	function automatic logic[4:0] FUNC_calcInfNanZeroResMul (
				input isZero_op1_i, isInf_op1_i, input sign_op1_i, input isSNan_op1_i, input isQNan_op1_i,
				input isZero_op2_i, isInf_op2_i, input sign_op2_i, input isSNan_op2_i, input isQNan_op2_i

			);

		logic isNan_op1 = isSNan_op1_i || isQNan_op1_i;
		logic isNan_op2 = isSNan_op2_i || isQNan_op2_i;

		logic isValidRes, isZeroRes, isInfRes, isNanRes, signRes;

		isValidRes	= (isZero_op1_i || isZero_op2_i || isInf_op1_i || isInf_op2_i || isNan_op1 || isNan_op2) ? 1 : 0;
		if (isNan_op1)
		begin //sign is not important, since a Nan remains a nan what-so-ever
			isZeroRes = 0; isInfRes = 0; isNanRes = 1; signRes = sign_op1_i;
		end
		else if (isNan_op2)
		begin
			isZeroRes = 0; isInfRes = 0; isNanRes = 1; signRes = sign_op2_i;
		end
		else // both are not NaN
		begin
			case({isZero_op1_i, isZero_op2_i, isInf_op1_i,isInf_op2_i})
				4'b00_00: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end
				4'b00_01: begin isNanRes = 0; isZeroRes = 0; isInfRes = 1; signRes = sign_op1_i ^ sign_op2_i; 	end
				4'b00_10: begin isNanRes = 0; isZeroRes = 0; isInfRes = 1; signRes = sign_op1_i ^ sign_op2_i; 	end
				4'b00_11: begin isNanRes = 0; isZeroRes = 0; isInfRes = 1; signRes = sign_op1_i ^ sign_op2_i; 	end
				4'b01_00: begin isNanRes = 0; isZeroRes = 1; isInfRes = 0; signRes = sign_op1_i ^ sign_op2_i; 	end	//TODO check sign of zero res
				4'b01_01: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end	//Impossible
				4'b01_10: begin isNanRes = 1; isZeroRes = 0; isInfRes = 0; signRes = 1; 						end	//TODO check sign of zero res
				4'b01_11: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //Impossible
				4'b10_00: begin isNanRes = 0; isZeroRes = 1; isInfRes = 0; signRes = sign_op1_i ^ sign_op2_i; 	end
				4'b10_01: begin isNanRes = 1; isZeroRes = 0; isInfRes = 0; signRes = 1;						 	end
				4'b10_10: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //Impossible
				4'b10_11: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //Impossible
				4'b11_00: begin isNanRes = 0; isZeroRes = 1; isInfRes = 0; signRes = sign_op1_i ^ sign_op2_i; 	end
				4'b11_01: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //Impossible
				4'b11_10: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //Impossible
				4'b11_11: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //Impossible
			endcase
		end
		return {isValidRes, isZeroRes, isInfRes, isNanRes, signRes};
	endfunction

	/*
	* 		Nan 	/ 			X		-> 		 Nan
	* 		X 		/ 			Nan 	-> (+/-) inf
	* (+/-)	inf		/ 			X 		-> (+/-) inf
	* 		X 		/ 	(+/-) 	inf 	-> (+/-) 0
	* (+/-) !0 		/ 	(+/-) 	0 		-> 		 inf
	* (+/-) 0 		/ 	(+/-) 	0 		-> 		 Nan
	* (+/-) inf 	/ 	(+/-) 	inf 	-> 		 Nan
	*/
	function automatic logic[4:0] FUNC_calcInfNanZeroResDiv (
				input isZero_op1_i, isInf_op1_i, input sign_op1_i, input isSNan_op1_i, input isQNan_op1_i,
				input isZero_op2_i, isInf_op2_i, input sign_op2_i, input isSNan_op2_i, input isQNan_op2_i
			);

		logic isNan_op1 = isSNan_op1_i || isQNan_op1_i;
		logic isNan_op2 = isSNan_op2_i || isQNan_op2_i;

		logic isValidRes, isZeroRes, isInfRes, isNanRes, signRes;

		isValidRes	= (isZero_op1_i || isZero_op2_i || isInf_op1_i || isInf_op2_i || isNan_op1 || isNan_op2) ? 1 : 0;
		if (isNan_op1)
		begin //sign is not important, since a Nan remains a nan what-so-ever
			isZeroRes = 0; isInfRes = 0; isNanRes = 1; signRes = sign_op1_i;
		end
		else if (isNan_op2)
		begin
			isZeroRes = 0; isInfRes = 0; isNanRes = 1; signRes = sign_op2_i;
		end
		else // both are not NaN
		begin
			case({isZero_op1_i, isZero_op2_i, isInf_op1_i,isInf_op2_i})
				4'b00_00: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end
				4'b00_01: begin isNanRes = 0; isZeroRes = 1; isInfRes = 0; signRes = sign_op1_i ^ sign_op2_i;	end	//	x	/ inf
				4'b00_10: begin isNanRes = 0; isZeroRes = 0; isInfRes = 1; signRes = sign_op1_i ^ sign_op2_i; 	end	//	inf	/ x
				4'b00_11: begin isNanRes = 1; isZeroRes = 0; isInfRes = 0; signRes = sign_op1_i ^ sign_op2_i; 	end	//	inf	/ inf
				4'b01_00: begin isNanRes = 0; isZeroRes = 0; isInfRes = 1; signRes = sign_op1_i ^ sign_op2_i; 	end	//	x	/ 0
				4'b01_01: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end	//	Impossible
				4'b01_10: begin isNanRes = 0; isZeroRes = 0; isInfRes = 1; signRes = sign_op1_i ^ sign_op2_i; 	end	//	inf	/ 0
				4'b01_11: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //	Impossible
				4'b10_00: begin isNanRes = 0; isZeroRes = 1; isInfRes = 0; signRes = sign_op1_i ^ sign_op2_i; 	end	//	0	/ x
				4'b10_01: begin isNanRes = 0; isZeroRes = 1; isInfRes = 0; signRes = sign_op1_i ^ sign_op2_i; 	end	//	0	/ inf
				4'b10_10: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //	Impossible
				4'b10_11: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //	Impossible
				4'b11_00: begin isNanRes = 1; isZeroRes = 0; isInfRes = 0; signRes = sign_op1_i ^ sign_op2_i; 	end	//	0	/ 0
				4'b11_01: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //	Impossible
				4'b11_10: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //	Impossible
				4'b11_11: begin isNanRes = 0; isZeroRes = 0; isInfRes = 0; signRes = 0; 						end //	Impossible
			endcase
		end
		return {isValidRes, isZeroRes, isInfRes, isNanRes, signRes};
	endfunction

	function automatic logic[LAMP_APPROX_DW-1:0] FUNC_approxRecip(
		input [(1+LAMP_FLOAT_F_DW)-1:0] f_i
	);
		case(f_i[(1+LAMP_FLOAT_F_DW)-2-:LAMP_APPROX_DW])
			'b0000	:	return 'b1111;
			'b0001	:	return 'b1101;
			'b0010	:	return 'b1100;
			'b0011	:	return 'b1010;
			'b0100	:	return 'b1001;
			'b0101	:	return 'b1000;
			'b0110	:	return 'b0111;
			'b0111	:	return 'b0110;
			'b1000	:	return 'b0101;
			'b1001	:	return 'b0100;
			'b1010	:	return 'b0011;
			'b1011	:	return 'b0011;
			'b1100	:	return 'b0010;
			'b1101	:	return 'b0001;
			'b1110	:	return 'b0001;
			'b1111	:	return 'b0000;
		endcase
	endfunction


	function automatic logic[11:0] LUT_log(
		input [(LAMP_FLOAT_F_DW+1)-1:0] lut_in
	);

		case(lut_in)
			8'b00000001 :    return 12'b100111000111; 
            8'b00000010 :    return 12'b100001110011; 
            8'b00000011 :    return 12'b011110101111; 
            8'b00000100 :    return 12'b011100100111; 
            8'b00000101 :    return 12'b011010111111; 
            8'b00000110 :    return 12'b011001101011; 
            8'b00000111 :    return 12'b011000100110; 
            8'b00001000 :    return 12'b010111101010; 
            8'b00001001 :    return 12'b010110110110; 
            8'b00001010 :    return 12'b010110000111; 
            8'b00001011 :    return 12'b010101011110; 
            8'b00001100 :    return 12'b010100111001; 
            8'b00001101 :    return 12'b010100010111; 
            8'b00001110 :    return 12'b010011111000; 
            8'b00001111 :    return 12'b010011011011; 
            8'b00010000 :    return 12'b010011000000; 
            8'b00010001 :    return 12'b010010100111; 
            8'b00010010 :    return 12'b010010010000; 
            8'b00010011 :    return 12'b010001111010; 
            8'b00010100 :    return 12'b010001100110; 
            8'b00010101 :    return 12'b010001010011; 
            8'b00010110 :    return 12'b010001000000; 
            8'b00010111 :    return 12'b010000101111; 
            8'b00011000 :    return 12'b010000011110; 
            8'b00011001 :    return 12'b010000001111; 
            8'b00011010 :    return 12'b010000000000; 
            8'b00011011 :    return 12'b001111110001; 
            8'b00011100 :    return 12'b001111100100; 
            8'b00011101 :    return 12'b001111010110; 
            8'b00011110 :    return 12'b001111001010; 
            8'b00011111 :    return 12'b001110111110; 
            8'b00100000 :    return 12'b001110110010; 
            8'b00100001 :    return 12'b001110100111; 
            8'b00100010 :    return 12'b001110011100; 
            8'b00100011 :    return 12'b001110010001; 
            8'b00100100 :    return 12'b001110000111; 
            8'b00100101 :    return 12'b001101111101; 
            8'b00100110 :    return 12'b001101110100; 
            8'b00100111 :    return 12'b001101101011; 
            8'b00101000 :    return 12'b001101100010; 
            8'b00101001 :    return 12'b001101011001; 
            8'b00101010 :    return 12'b001101010001; 
            8'b00101011 :    return 12'b001101001001; 
            8'b00101100 :    return 12'b001101000001; 
            8'b00101101 :    return 12'b001100111001; 
            8'b00101110 :    return 12'b001100110001; 
            8'b00101111 :    return 12'b001100101010; 
            8'b00110000 :    return 12'b001100100011; 
            8'b00110001 :    return 12'b001100011100; 
            8'b00110010 :    return 12'b001100010101; 
            8'b00110011 :    return 12'b001100001111; 
            8'b00110100 :    return 12'b001100001000; 
            8'b00110101 :    return 12'b001100000010; 
            8'b00110110 :    return 12'b001011111100; 
            8'b00110111 :    return 12'b001011110110; 
            8'b00111000 :    return 12'b001011110000; 
            8'b00111001 :    return 12'b001011101010; 
            8'b00111010 :    return 12'b001011100101; 
            8'b00111011 :    return 12'b001011011111; 
            8'b00111100 :    return 12'b001011011010; 
            8'b00111101 :    return 12'b001011010100; 
            8'b00111110 :    return 12'b001011001111; 
            8'b00111111 :    return 12'b001011001010; 
            8'b01000000 :    return 12'b001011000101; 
            8'b01000001 :    return 12'b001011000000; 
            8'b01000010 :    return 12'b001010111100; 
            8'b01000011 :    return 12'b001010110111; 
            8'b01000100 :    return 12'b001010110010; 
            8'b01000101 :    return 12'b001010101110; 
            8'b01000110 :    return 12'b001010101001; 
            8'b01000111 :    return 12'b001010100101; 
            8'b01001000 :    return 12'b001010100001; 
            8'b01001001 :    return 12'b001010011101; 
            8'b01001010 :    return 12'b001010011001; 
            8'b01001011 :    return 12'b001010010100; 
            8'b01001100 :    return 12'b001010010000; 
            8'b01001101 :    return 12'b001010001101; 
            8'b01001110 :    return 12'b001010001001; 
            8'b01001111 :    return 12'b001010000101; 
            8'b01010000 :    return 12'b001010000001; 
            8'b01010001 :    return 12'b001001111110; 
            8'b01010010 :    return 12'b001001111010; 
            8'b01010011 :    return 12'b001001110110; 
            8'b01010100 :    return 12'b001001110011; 
            8'b01010101 :    return 12'b001001101111; 
            8'b01010110 :    return 12'b001001101100; 
            8'b01010111 :    return 12'b001001101001; 
            8'b01011000 :    return 12'b001001100101; 
            8'b01011001 :    return 12'b001001100010; 
            8'b01011010 :    return 12'b001001011111; 
            8'b01011011 :    return 12'b001001011100; 
            8'b01011100 :    return 12'b001001011001; 
            8'b01011101 :    return 12'b001001010110; 
            8'b01011110 :    return 12'b001001010011; 
            8'b01011111 :    return 12'b001001010000; 
            8'b01100000 :    return 12'b001001001101; 
            8'b01100001 :    return 12'b001001001010; 
            8'b01100010 :    return 12'b001001000111; 
            8'b01100011 :    return 12'b001001000100; 
            8'b01100100 :    return 12'b001001000001; 
            8'b01100101 :    return 12'b001000111111; 
            8'b01100110 :    return 12'b001000111100; 
            8'b01100111 :    return 12'b001000111001; 
            8'b01101000 :    return 12'b001000110110; 
            8'b01101001 :    return 12'b001000110100; 
            8'b01101010 :    return 12'b001000110001; 
            8'b01101011 :    return 12'b001000101111; 
            8'b01101100 :    return 12'b001000101100; 
            8'b01101101 :    return 12'b001000101010; 
            8'b01101110 :    return 12'b001000100111; 
            8'b01101111 :    return 12'b001000100101; 
            8'b01110000 :    return 12'b001000100010; 
            8'b01110001 :    return 12'b001000100000; 
            8'b01110010 :    return 12'b001000011110; 
            8'b01110011 :    return 12'b001000011011; 
            8'b01110100 :    return 12'b001000011001; 
            8'b01110101 :    return 12'b001000010111; 
            8'b01110110 :    return 12'b001000010101; 
            8'b01110111 :    return 12'b001000010010; 
            8'b01111000 :    return 12'b001000010000; 
            8'b01111001 :    return 12'b001000001110; 
            8'b01111010 :    return 12'b001000001100; 
            8'b01111011 :    return 12'b001000001010; 
            8'b01111100 :    return 12'b001000001000; 
            8'b01111101 :    return 12'b001000000110; 
            8'b01111110 :    return 12'b001000000100; 
            8'b01111111 :    return 12'b001000000010; 
            8'b10000000 :    return 12'b001000000000; 
            8'b10000001 :    return 12'b000111111110; 
            8'b10000010 :    return 12'b000111111100; 
            8'b10000011 :    return 12'b000111111010; 
            8'b10000100 :    return 12'b000111111000; 
            8'b10000101 :    return 12'b000111110110; 
            8'b10000110 :    return 12'b000111110100; 
            8'b10000111 :    return 12'b000111110010; 
            8'b10001000 :    return 12'b000111110000; 
            8'b10001001 :    return 12'b000111101110; 
            8'b10001010 :    return 12'b000111101100; 
            8'b10001011 :    return 12'b000111101011; 
            8'b10001100 :    return 12'b000111101001; 
            8'b10001101 :    return 12'b000111100111; 
            8'b10001110 :    return 12'b000111100101; 
            8'b10001111 :    return 12'b000111100100; 
            8'b10010000 :    return 12'b000111100010; 
            8'b10010001 :    return 12'b000111100000; 
            8'b10010010 :    return 12'b000111011111; 
            8'b10010011 :    return 12'b000111011101; 
            8'b10010100 :    return 12'b000111011011; 
            8'b10010101 :    return 12'b000111011010; 
            8'b10010110 :    return 12'b000111011000; 
            8'b10010111 :    return 12'b000111010110; 
            8'b10011000 :    return 12'b000111010101; 
            8'b10011001 :    return 12'b000111010011; 
            8'b10011010 :    return 12'b000111010010; 
            8'b10011011 :    return 12'b000111010000; 
            8'b10011100 :    return 12'b000111001111; 
            8'b10011101 :    return 12'b000111001101; 
            8'b10011110 :    return 12'b000111001011; 
            8'b10011111 :    return 12'b000111001010; 
            8'b10100000 :    return 12'b000111001000; 
            8'b10100001 :    return 12'b000111000111; 
            8'b10100010 :    return 12'b000111000110; 
            8'b10100011 :    return 12'b000111000100; 
            8'b10100100 :    return 12'b000111000011; 
            8'b10100101 :    return 12'b000111000001; 
            8'b10100110 :    return 12'b000111000000; 
            8'b10100111 :    return 12'b000110111110; 
            8'b10101000 :    return 12'b000110111101; 
            8'b10101001 :    return 12'b000110111100; 
            8'b10101010 :    return 12'b000110111010; 
            8'b10101011 :    return 12'b000110111001; 
            8'b10101100 :    return 12'b000110111000; 
            8'b10101101 :    return 12'b000110110110; 
            8'b10101110 :    return 12'b000110110101; 
            8'b10101111 :    return 12'b000110110100; 
            8'b10110000 :    return 12'b000110110010; 
            8'b10110001 :    return 12'b000110110001; 
            8'b10110010 :    return 12'b000110110000; 
            8'b10110011 :    return 12'b000110101110; 
            8'b10110100 :    return 12'b000110101101; 
            8'b10110101 :    return 12'b000110101100; 
            8'b10110110 :    return 12'b000110101011;  
		endcase
	endfunction
	
	parameter G0        =   1;
	function automatic logic[(LAMP_FLOAT_E_DW+LAMP_FLOAT_F_DW+3)-1:0] FUNC_fix2float_log(	//8bit exp, 7bit mant, guard, round, sticky
		input [(LAMP_FLOAT_E_DW+2*LAMP_FLOAT_F_DW+G0+2+1)-1 : 0] res_preNorm
	);
		casez(res_preNorm)
            25'b1????????????????????????: return {(24-16+LAMP_FLOAT_E_BIAS),res_preNorm[23:15],(|res_preNorm[14:12])};
			25'b01???????????????????????: return {(23-16+LAMP_FLOAT_E_BIAS),res_preNorm[22:14],(|res_preNorm[13:11])};
			25'b001??????????????????????: return {(22-16+LAMP_FLOAT_E_BIAS),res_preNorm[21:13],(|res_preNorm[12:10])};
			25'b0001?????????????????????: return {(21-16+LAMP_FLOAT_E_BIAS),res_preNorm[20:12],(|res_preNorm[11: 9])};
			25'b00001????????????????????: return {(20-16+LAMP_FLOAT_E_BIAS),res_preNorm[19:11],(|res_preNorm[10: 8])};
			25'b000001???????????????????: return {(19-16+LAMP_FLOAT_E_BIAS),res_preNorm[18:10],(|res_preNorm[ 9: 7])};
			25'b0000001??????????????????: return {(18-16+LAMP_FLOAT_E_BIAS),res_preNorm[17: 9],(|res_preNorm[ 8: 6])};
			25'b00000001?????????????????: return {(17-16+LAMP_FLOAT_E_BIAS),res_preNorm[16: 8],(|res_preNorm[ 7: 5])};
			25'b000000001????????????????: return {(16-16+LAMP_FLOAT_E_BIAS),res_preNorm[15: 7],(|res_preNorm[ 6: 4])};
			25'b0000000001???????????????: return {(15-16+LAMP_FLOAT_E_BIAS),res_preNorm[14: 6],(|res_preNorm[ 5: 3])};
			25'b00000000001??????????????: return {(14-16+LAMP_FLOAT_E_BIAS),res_preNorm[13: 5],(|res_preNorm[ 4: 2])};
			25'b000000000001?????????????: return {(13-16+LAMP_FLOAT_E_BIAS),res_preNorm[12: 4],(|res_preNorm[ 3: 1])};
			25'b0000000000001????????????: return {(12-16+LAMP_FLOAT_E_BIAS),res_preNorm[11: 3],(|res_preNorm[ 2: 0])};
			25'b00000000000001???????????: return {(11-16+LAMP_FLOAT_E_BIAS),res_preNorm[10: 2],(|res_preNorm[ 1:0])};
			25'b00000000000000???????????: return {(10-16+LAMP_FLOAT_E_BIAS),res_preNorm[ 9: 1],(res_preNorm[0])};			//to keep track also of lower numbers (less than LSB -> zero)
		endcase

	endfunction

	/*
	* 		ln(SNaN)		->		NaN
	* 		ln(QNaN)	 	->		NaN
	*		ln(+inf)	  	->		+inf
	* 		ln(zero)		->		-inf
	* 		ln(-x)			->		NaN
	*/
	function automatic logic[3:0] FUNC_calcInfNanResLog (
				input isZ_op_i, input isInf_op_i, input isSNan_op_i, input isQNan_op_i, input s_op_i
			);

		logic isNan_op_i = isSNan_op_i || isQNan_op_i;
		logic isValidRes, isNanRes, isInfRes, signRes;							//signRes is the sign of the special case output

		isValidRes	= (isZ_op_i || isInf_op_i || isNan_op_i || s_op_i) ? 1 : 0;			//signal that tells us if the result is a special case

		case({isZ_op_i, isInf_op_i, isNan_op_i, s_op_i})
			4'b00_00: begin isNanRes = 0; isInfRes = 0; signRes = 0;			end
			4'b00_01: begin	isNanRes = 1; isInfRes = 0; signRes = 0;			end		//ln(x<0) returns NaN; sign is not important for a NaN so use the same sign of the operand
			4'b00_10: begin	isNanRes = 1; isInfRes = 0; signRes = 0;			end		//ln(NaN) returns NaN; sign is not important for a NaN so use the same sign of the operand
			4'b00_11: begin isNanRes = 1; isInfRes = 0; signRes = 0;			end		//ln(NaN) returns NaN; sign is not important for a NaN so use the same sign of the operand
			4'b01_00: begin	isNanRes = 0; isInfRes = 1; signRes = 0;			end		//ln(+inf) returns +inf
			4'b01_01: begin isNanRes = 1; isInfRes = 0;	signRes = 0;			end		//ln(-inf) returns NaN; sign is not important for a NaN so use the same sign of the operand
			4'b01_10: begin isNanRes = 0; isInfRes = 0; signRes = 0;			end		//impossible!
			4'b01_11: begin isNanRes = 0; isInfRes = 0; signRes = 0;			end		//impossible!
			4'b10_00: begin	isNanRes = 0; isInfRes = 1; signRes = 1;			end     //ln(zero+) or ln(DN) returns -inf
			4'b10_01: begin isNanRes = 1; isInfRes = 0; signRes = 0;			end		//ln(zero-) or ln(DN<0) returns Nan; sign is not important for a NaN so use the same sign of the operand
			4'b10_10: begin isNanRes = 0; isInfRes = 0; signRes = 0;			end		//impossible!
			4'b10_11: begin isNanRes = 0; isInfRes = 0; signRes = 0;			end		//impossible!
			4'b11_00: begin isNanRes = 0; isInfRes = 0; signRes = 0;			end		//impossible!
			4'b11_01: begin isNanRes = 0; isInfRes = 0; signRes = 0;			end		//impossible!
			4'b11_10: begin isNanRes = 0; isInfRes = 0; signRes = 0;			end		//impossible!
			4'b11_11: begin isNanRes = 0; isInfRes = 0; signRes = 0;			end		//impossible!
		endcase

		return {isValidRes, isNanRes, isInfRes, signRes};
	endfunction

endpackage