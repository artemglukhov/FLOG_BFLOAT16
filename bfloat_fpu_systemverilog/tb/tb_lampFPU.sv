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

module tb_lampFPU;

	import lampFPU_pkg::*;

	import "DPI-C" function int unsigned DPI_fadd( input int unsigned op1, input int unsigned op2 );
	import "DPI-C" function int unsigned DPI_fsub( input int unsigned op1, input int unsigned op2 );
	import "DPI-C" function int unsigned DPI_fmul( input int unsigned op1, input int unsigned op2 );
	import "DPI-C" function int unsigned DPI_fdiv( input int unsigned op1, input int unsigned op2 );
	import "DPI-C" function int unsigned DPI_feq( input int unsigned op1, input int unsigned op2 );
	import "DPI-C" function int unsigned DPI_flt( input int unsigned op1, input int unsigned op2 );
	import "DPI-C" function int unsigned DPI_fle( input int unsigned op1, input int unsigned op2 );
	import "DPI-C" function int unsigned DPI_i2f( input int unsigned op1 );
	import "DPI-C" function int unsigned DPI_f2i( input int unsigned op1 );

	parameter HALF_CLK_PERIOD_NS=20;

	logic							clk;
	logic							rst;
	logic							flush;
	logic							padv;
	opcodeFPU_t						opcodeFPU_i_tb;
	rndModeFPU_t					rndMode_i_tb;
	logic	[LAMP_INTEGER_DW-1:0]	op1_i_tb;
	logic	[LAMP_FLOAT_DW-1:0]		op2_i_tb;
	logic	[LAMP_INTEGER_DW-1:0]	result_o_tb;
	logic							isResultValid_o_tb;
	logic							isReady_o_tb;

	int numTest=0;

	always #HALF_CLK_PERIOD_NS clk = ~clk;

	lampFPU_top
		lampFPU_top0(
				.clk				(clk),
				.rst				(rst),
				.flush_i			(flush),
				.padv_i				(padv),
				.opcode_i			(opcodeFPU_i_tb),
				.rndMode_i			(rndMode_i_tb),
				.op1_i				(op1_i_tb),
				.op2_i				(op2_i_tb),
				.result_o			(result_o_tb),
				.isResultValid_o	(isResultValid_o_tb),
				.isReady_o			(isReady_o_tb)
			);

	initial
	begin
		//$dumpvars(0,tb_lampFPU);
		//$dumpfile("out.vcd");
		clk				<=	1;
		rst				=	1;
		flush			=	0;
		padv			=	1;
		opcodeFPU_i_tb	= 	FPU_IDLE;
		rndMode_i_tb 	= 	FPU_RNDMODE_NEAREST;
		op1_i_tb		=	'0;
		op2_i_tb		=	'0;

		repeat(10) @(posedge clk);
		rst <= 0;
		repeat(10) @(posedge clk);

//		repeat(1000)
//		begin
//			numTest++;
//			$display("Test-%d",numTest);
//	        TASK_doFPU_op();
//			@(posedge clk);
//		end
		rndMode_i_tb	= 	FPU_RNDMODE_NEAREST;
		TASK_testArith (FPU_ADD);
		TASK_testArith (FPU_SUB);
		TASK_testArith (FPU_MUL);
		TASK_testArith (FPU_DIV);
		TASK_testCmp ();
		TASK_testI2f ();
		rndMode_i_tb	= 	FPU_RNDMODE_TRUNCATE;
		TASK_testF2i ();
		repeat(200) @(posedge clk);
		$finish;
	end

	task TASK_testArith (input opcodeFPU_t opcode);
		logic	[LAMP_FLOAT_S_DW-1:0]	op1_sign;
		logic	[LAMP_FLOAT_E_DW-1:0]	op1_exponent;
		logic	[LAMP_FLOAT_F_DW-1:0]	op1_fraction;

		logic	[LAMP_FLOAT_S_DW-1:0]	op2_sign;
		logic	[LAMP_FLOAT_E_DW-1:0]	op2_exponent;
		logic	[LAMP_FLOAT_F_DW-1:0]	op2_fraction;

		int								numTest;

		numTest				=	0;
		repeat (100)
		begin
			@(posedge clk);
			numTest++;
			$display("Test-%d",numTest);
			op1_sign		=	$urandom_range(0,1);
			op1_exponent	=	$urandom_range(0,255);
			op1_fraction	=	(op1_exponent>=0 && op1_exponent<255) ? $random : $urandom_range(0,1)<<22 /*inf or qnan*/;

			op2_sign		=	$urandom_range(0,1);
			op2_exponent	=	$urandom_range(0,255);
			op2_fraction	=	(op2_exponent>=0 && op2_exponent<255) ? $random : $urandom_range(0,1)<<22 /*inf or qnan*/;

			TASK_doArith_op (opcode, {op1_sign, op1_exponent, op1_fraction}, {op2_sign, op2_exponent, op2_fraction});
		end
	endtask

	task TASK_testI2f ();
		int	numTest;

		numTest	=	0;
		repeat (100)
		begin
			numTest++;
			$display("Test-%d",numTest);
			@(posedge clk);
			TASK_doI2f_op ($random);
		end

		//	zero
		numTest++;
		$display("Test-%d",numTest);
		@(posedge clk);
		TASK_doI2f_op (32'b00000000000000000000000000000000);

		//	max
		numTest++;
		$display("Test-%d",numTest);
		@(posedge clk);
		TASK_doI2f_op (32'b01111111111111111111111111111111);

		//	min
		numTest++;
		$display("Test-%d",numTest);
		@(posedge clk);
		TASK_doI2f_op (32'b10000000000000000000000000000000);
	endtask

	task TASK_testF2i ();
		logic	[LAMP_FLOAT_S_DW-1:0]	sign;
		logic	[LAMP_FLOAT_E_DW-1:0]	exponent;
		logic	[LAMP_FLOAT_F_DW-1:0]	fraction;
		int								numTest;

		numTest			=	0;
		repeat (100)
		begin
			@(posedge clk);
			numTest++;
			$display("Test-%d",numTest);
			sign		=	$random;
			exponent	=	$urandom_range(0, LAMP_FLOAT_E_BIAS + LAMP_INTEGER_F_DW - 1);
			fraction	=	$random;
			TASK_doF2i_op ({sign, exponent, fraction});
		end

		//	- 2^31
		@(posedge clk);
		numTest++;
		$display("Test-%d",numTest);
		sign		=	'1;
		exponent	=	'd31 + 'd127;
		fraction	=	'0;
		TASK_doF2i_op ({sign, exponent, fraction});

		//	+ (2^31 - 1)
		@(posedge clk);
		numTest++;
		$display("Test-%d",numTest);
		sign		=	'0;
		exponent	=	'd30 + 'd127;
		fraction	=	'h7ffffff;
		TASK_doF2i_op ({sign, exponent, fraction});
	endtask

	task TASK_testCmp ();
		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_EQ, $random, $random);
		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_LT, $random, $random);
		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_LE, $random, $random);

		TASK_doCmp_op (FPU_EQ, PLUS_INF, PLUS_INF);
		TASK_doCmp_op (FPU_LT, PLUS_INF, PLUS_INF);
		TASK_doCmp_op (FPU_LE, PLUS_INF, PLUS_INF);

		TASK_doCmp_op (FPU_EQ, MINUS_INF, MINUS_INF);
		TASK_doCmp_op (FPU_LT, MINUS_INF, MINUS_INF);
		TASK_doCmp_op (FPU_LE, MINUS_INF, MINUS_INF);

		TASK_doCmp_op (FPU_EQ, PLUS_ZERO, PLUS_ZERO);
		TASK_doCmp_op (FPU_LT, PLUS_ZERO, PLUS_ZERO);
		TASK_doCmp_op (FPU_LE, PLUS_ZERO, PLUS_ZERO);

		TASK_doCmp_op (FPU_EQ, MINUS_ZERO, MINUS_ZERO);
		TASK_doCmp_op (FPU_LT, MINUS_ZERO, MINUS_ZERO);
		TASK_doCmp_op (FPU_LE, MINUS_ZERO, MINUS_ZERO);

		TASK_doCmp_op (FPU_EQ, PLUS_ZERO, MINUS_ZERO);
		TASK_doCmp_op (FPU_LT, PLUS_ZERO, MINUS_ZERO);
		TASK_doCmp_op (FPU_LE, PLUS_ZERO, MINUS_ZERO);

		TASK_doCmp_op (FPU_EQ, MINUS_ZERO, PLUS_ZERO);
		TASK_doCmp_op (FPU_LT, MINUS_ZERO, PLUS_ZERO);
		TASK_doCmp_op (FPU_LE, MINUS_ZERO, PLUS_ZERO);

		TASK_doCmp_op (FPU_EQ, PLUS_INF, MINUS_INF);
		TASK_doCmp_op (FPU_LT, PLUS_INF, MINUS_INF);
		TASK_doCmp_op (FPU_LE, PLUS_INF, MINUS_INF);

		TASK_doCmp_op (FPU_EQ, MINUS_INF, PLUS_INF);
		TASK_doCmp_op (FPU_LT, MINUS_INF, PLUS_INF);
		TASK_doCmp_op (FPU_LE, MINUS_INF, PLUS_INF);

		TASK_doCmp_op (FPU_EQ, PLUS_ZERO, MINUS_INF);
		TASK_doCmp_op (FPU_LT, PLUS_ZERO, MINUS_INF);
		TASK_doCmp_op (FPU_LE, PLUS_ZERO, MINUS_INF);

		TASK_doCmp_op (FPU_EQ, MINUS_ZERO, PLUS_INF);
		TASK_doCmp_op (FPU_LT, MINUS_ZERO, PLUS_INF);
		TASK_doCmp_op (FPU_LE, MINUS_ZERO, PLUS_INF);

		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_EQ, PLUS_INF, $random);
		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_LT, PLUS_INF, $random);
		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_LE, PLUS_INF, $random);

		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_EQ, $random, MINUS_INF);
		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_LT, $random, MINUS_INF);
		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_LE, $random, MINUS_INF);

		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_EQ, MINUS_ZERO, $random);
		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_LT, MINUS_ZERO, $random);
		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_LE, MINUS_ZERO, $random);

		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_EQ, $random, PLUS_ZERO);
		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_LT, $random, PLUS_ZERO);
		repeat(20) @(posedge clk) TASK_doCmp_op (FPU_LE, $random, PLUS_ZERO);

		//	TODO: NaNs!!!
	endtask

	task TASK_doArith_op (input opcodeFPU_t opcode, input logic [LAMP_FLOAT_DW-1:0] op1, input logic [LAMP_FLOAT_DW-1:0] op2);
		logic	[31:0]	tb_res;

		case (opcode)
			FPU_ADD:	tb_res	=	DPI_fadd (op1 << (LAMP_INTEGER_DW - LAMP_FLOAT_DW), op2 << (LAMP_INTEGER_DW - LAMP_FLOAT_DW));
			FPU_SUB:	tb_res	=	DPI_fsub (op1 << (LAMP_INTEGER_DW - LAMP_FLOAT_DW), op2 << (LAMP_INTEGER_DW - LAMP_FLOAT_DW));
			FPU_MUL:	tb_res	=	DPI_fmul (op1 << (LAMP_INTEGER_DW - LAMP_FLOAT_DW), op2 << (LAMP_INTEGER_DW - LAMP_FLOAT_DW));
			FPU_DIV:	tb_res	=	DPI_fdiv (op1 << (LAMP_INTEGER_DW - LAMP_FLOAT_DW), op2 << (LAMP_INTEGER_DW - LAMP_FLOAT_DW));
		endcase

		$strobe ("@%0t - Start FPU operation: opcode:%s",
								$time, opcode.name);

		@(posedge clk);
		opcodeFPU_i_tb	<=	opcode;
		op1_i_tb 		<=	op1;
		op2_i_tb 		<=	op2;

		@(posedge clk);
		opcodeFPU_i_tb	<=	FPU_IDLE;
		wait (isResultValid_o_tb);
		$display ("OP1 - S=%b E=0x%02x f=0x%x", op1[LAMP_FLOAT_DW-1], op1[LAMP_FLOAT_DW-2-:LAMP_FLOAT_E_DW], op1[0+:LAMP_FLOAT_F_DW]);
		$display ("OP2 - S=%b E=0x%02x f=0x%x", op2[LAMP_FLOAT_DW-1], op2[LAMP_FLOAT_DW-2-:LAMP_FLOAT_E_DW], op2[0+:LAMP_FLOAT_F_DW]);
		if (tb_res[31-:LAMP_FLOAT_DW] !== result_o_tb)
		begin
			$display("ERR DPI-FPU - S=%b E=0x%02x f=0x%x", tb_res[31], tb_res[30-:LAMP_FLOAT_E_DW], tb_res[30-LAMP_FLOAT_E_DW-:LAMP_FLOAT_F_DW]);
			$display("ERR RTL-FPU - S=%b E=0x%02x f=0x%x", result_o_tb[LAMP_FLOAT_DW-1], result_o_tb[LAMP_FLOAT_DW-2-:LAMP_FLOAT_E_DW], result_o_tb[0+:LAMP_FLOAT_F_DW]);
		end
		else
		begin
			$display("OK DPI-FPU - S=%b E=0x%02x f=0x%x", tb_res[31], tb_res[30-:LAMP_FLOAT_E_DW], tb_res[30-LAMP_FLOAT_E_DW-:LAMP_FLOAT_F_DW]);
			$display("OK RTL-FPU - S=%b E=0x%02x f=0x%x", result_o_tb[LAMP_FLOAT_DW-1], result_o_tb[LAMP_FLOAT_DW-2-:LAMP_FLOAT_E_DW], result_o_tb[0+:LAMP_FLOAT_F_DW]);
		end
		$strobe ("@%0t - END FPU operation", $time);
	endtask

	task TASK_doI2f_op (input logic [LAMP_INTEGER_DW-1:0] op1);
		opcodeFPU_t		opcode;
		logic	[31:0]	tb_res;

		opcode			=	FPU_I2F;
        tb_res			=	DPI_i2f (op1);

		$strobe ("@%0t - Start FPU operation: opcode:%s op1:%0x",
								$time, opcode.name, op1);

		@(posedge clk);
		opcodeFPU_i_tb	<=	opcode;
		op1_i_tb 		<=	op1;

		@(posedge clk);
		opcodeFPU_i_tb	<=	FPU_IDLE;
		wait (isResultValid_o_tb);
		$display ("OP1 - I=0x%08x(0b%032b)", op1, op1);
		if (tb_res[31-:LAMP_FLOAT_DW] !== result_o_tb)
		begin
			$display("ERR DPI-FPU - S=%b E=0x%02x f=0x%x", tb_res[31], tb_res[30-:LAMP_FLOAT_E_DW], tb_res[30-LAMP_FLOAT_E_DW-:LAMP_FLOAT_F_DW]);
			$display("ERR RTL-FPU - S=%b E=0x%02x f=0x%x", result_o_tb[LAMP_FLOAT_DW-1], result_o_tb[LAMP_FLOAT_DW-2-:LAMP_FLOAT_E_DW], result_o_tb[0+:LAMP_FLOAT_F_DW]);
		end
		else
		begin
			$display("OK DPI-FPU - S=%b E=0x%02x f=0x%x", tb_res[31], tb_res[30-:LAMP_FLOAT_E_DW], tb_res[30-LAMP_FLOAT_E_DW-:LAMP_FLOAT_F_DW]);
			$display("OK RTL-FPU - S=%b E=0x%02x f=0x%x", result_o_tb[LAMP_FLOAT_DW-1], result_o_tb[LAMP_FLOAT_DW-2-:LAMP_FLOAT_E_DW], result_o_tb[0+:LAMP_FLOAT_F_DW]);
		end
		$strobe ("@%0t - END FPU operation", $time);
	endtask

	task TASK_doF2i_op (input logic [LAMP_FLOAT_DW-1:0] op1);
		opcodeFPU_t		opcode;
		logic	[31:0]	tb_res;

		opcode			=	FPU_F2I;
        tb_res			=	DPI_f2i (op1 << (LAMP_INTEGER_DW - LAMP_FLOAT_DW));

		$strobe ("@%0t - Start FPU operation: opcode:%s op1:%0x",
								$time, opcode.name, op1);

		@(posedge clk);
		opcodeFPU_i_tb	<=	opcode;
		op1_i_tb 		<=	op1;

		@(posedge clk);
		opcodeFPU_i_tb	<=	FPU_IDLE;
		wait (isResultValid_o_tb);
		$display ("OP1 - S=%b E=0x%02x f=0x%x", op1[LAMP_FLOAT_DW-1], op1[LAMP_FLOAT_DW-2-:LAMP_FLOAT_E_DW], op1[0+:LAMP_FLOAT_F_DW]);
		if (tb_res !== result_o_tb)
		begin
			$display("ERR DPI-FPU - I=0x%08x(0b%032b)", tb_res, tb_res);
			$display("ERR RTL-FPU - I=0x%08x(0b%032b)", result_o_tb, result_o_tb);
		end
		else
		begin
			$display("OK DPI-FPU - I=0x%08x(0b%032b)", tb_res, tb_res);
			$display("OK RTL-FPU - I=0x%08x(0b%032b)", result_o_tb, result_o_tb);
		end
		$strobe ("@%0t - END FPU operation", $time);
	endtask

	task TASK_doCmp_op (input opcodeFPU_t opcode, input logic [31:0] op1, input logic [31:0] op2);
		logic	[31:0]	tb_res;

		case (opcode)
        	FPU_EQ:	tb_res	=	DPI_feq (op1,op2);
        	FPU_LT:	tb_res	=	DPI_flt (op1,op2);
        	FPU_LE:	tb_res	=	DPI_fle (op1,op2);
		endcase

		$strobe ("@%0t - Start FPU operation: opcode:%s op1:%0x op2:%0x",
								$time, opcode.name, op1, op2);

		@(posedge clk);
		opcodeFPU_i_tb		<=	opcode;
		op1_i_tb 			<=	op1;
		op2_i_tb 			<=	op2;

		@(posedge clk);
		opcodeFPU_i_tb		<=	FPU_IDLE;
		wait (isResultValid_o_tb);
		$display ("OP1 - S=%b E=0x%02x f=0x%x", op1[LAMP_FLOAT_DW-1], op1[LAMP_FLOAT_DW-2-:LAMP_FLOAT_E_DW], op1[0+:LAMP_FLOAT_F_DW]);
		$display ("OP2 - S=%b E=0x%02x f=0x%x", op2[LAMP_FLOAT_DW-1], op2[LAMP_FLOAT_DW-2-:LAMP_FLOAT_E_DW], op2[0+:LAMP_FLOAT_F_DW]);
		if (tb_res[0] !== result_o_tb[0])
		begin
			$display ("ERR DPI-FPU - C=%b", tb_res[0]);
			$display ("ERR RTL-FPU - C=%b", result_o_tb[0]);
		end
		$strobe ("@%0t - END FPU operation", $time);
	endtask

	task TASK_doFPU_op;
		opcodeFPU_t  tb_opcodeFPU;
		logic [31:0] tb_op1;
		logic [31:0] tb_op2;
		logic [31:0] tb_res;

		logic 		 signTmp;
		logic [7:0]	 expTmp;
		logic [22:0] significandTmp;

		tb_opcodeFPU	=	opcodeFPU_t'($urandom_range(5,5));

	// test all but de-norm
		signTmp 		=	$urandom_range(0,1);
		expTmp 			=	$urandom_range(0,0);
		significandTmp	=	( expTmp>=0 && expTmp<255) ? $random : $urandom_range(0,1)<<22 /*inf or qnan*/;

		tb_op1			=	{signTmp,expTmp,significandTmp}; // 127 biased exponent

	//test all but denorm
		signTmp 		=	$urandom_range(0,1);
		expTmp 			=	$urandom_range(1,255);
		significandTmp	=	'0; //( expTmp>=0 && expTmp<255) ? $random : $urandom_range(0,1)<<22 /*inf or qnan*/;

		tb_op2			=	{signTmp,expTmp,significandTmp}; // 127 biased exponent

		case(tb_opcodeFPU)
			FPU_I2F: begin tb_res = DPI_i2f(tb_op1); end
			FPU_F2I: begin tb_res = DPI_f2i(tb_op1); end
			FPU_ADD: begin tb_res = DPI_fadd(tb_op1,tb_op2); end
			FPU_SUB: begin tb_res = DPI_fsub(tb_op1,tb_op2); end
        	FPU_MUL: begin tb_res = DPI_fmul(tb_op1,tb_op2); end
        	FPU_DIV: begin tb_res = DPI_fdiv(tb_op1,tb_op2); end
		endcase

		$strobe("@%0t - Start FPU operation: opcode:%s | op1.s=%0b op1.e=%8b op1.f=%23b | op2.s=%0b op2.e=%8b op2.f=%23b",
								$time, tb_opcodeFPU.name,
								tb_op1[31], tb_op1[23+:8], tb_op1[0+:23],
								tb_op2[31], tb_op2[23+:8], tb_op2[0+:23]
						);

		@(posedge clk);
		opcodeFPU_i_tb	<= tb_opcodeFPU;
		op1_i_tb 		<= tb_op1;
		op2_i_tb 		<= tb_op2;

		@(posedge clk);
		opcodeFPU_i_tb <= FPU_IDLE;
		wait(isResultValid_o_tb);
		if (tb_res[31-:LAMP_FLOAT_DW] !== result_o_tb)
		begin
			$display("ERR DPI-FPU - S=%b E=0x%02x(0b%08b) f=0x%06x(0b%023b)",tb_res[31],tb_res[30:23],tb_res[30:23],tb_res[22:0],tb_res[22:0]);
			$display("ERR RTL-FPU - S=%b E=0x%02x(0b%08b) f=0x%06x(0b%023b)",result_o_tb[31],result_o_tb[30:23],result_o_tb[30:23],result_o_tb[22:0],result_o_tb[22:0]);
			#200;
			$finish;
		end
		else
		begin
			$display("OK - RTL == DPI test passed | DPI-FPU - S=%b E=0x%02x f=0x%06x(0b%023b) | RTL-FPU - S=%b E=0x%02x f=0x%06x(0b%023b)",
					tb_res[31],			tb_res[30:23],			tb_res[22:0],		 tb_res[22:0],
					result_o_tb[31],	result_o_tb[30:23],	result_o_tb[22:0], result_o_tb[22:0]
				);
			#200;
		end
		//DPI_fPrintHex(res_o);
		$strobe("@%0t - END FPU operation",$time);

	endtask

endmodule
