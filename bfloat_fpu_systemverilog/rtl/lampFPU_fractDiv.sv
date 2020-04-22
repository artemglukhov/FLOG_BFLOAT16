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

module lampFPU_fractDiv (
	clk, rst,
	//	inputs
	doDiv_i, n_i, d_i,
	//	outputs
	res_o, valid_o
);

import lampFPU_pkg::*;

input										clk;
input										rst;
//	inputs
input										doDiv_i;
input			[(1+LAMP_FLOAT_F_DW)-1:0]	n_i;
input			[(1+LAMP_FLOAT_F_DW)-1:0]	d_i;
//	outputs
output	logic	[2*(1+LAMP_FLOAT_F_DW)-1:0]	res_o;
output	logic								valid_o;

//////////////////////////////////////////////////////////////////
//						internal wires							//
//////////////////////////////////////////////////////////////////

	logic	[2*(1+LAMP_FLOAT_F_DW+LAMP_PREC_DW)-1:0] 	n_tmp;
	logic	[2*(1+LAMP_FLOAT_F_DW+LAMP_PREC_DW)-1:0] 	d_tmp;
	logic	[(1+LAMP_FLOAT_F_DW+LAMP_PREC_DW)-1:0]		n_r, n_next;
	logic	[(1+LAMP_FLOAT_F_DW+LAMP_PREC_DW)-1:0]		d_r, d_next;
	logic	[(1+LAMP_FLOAT_F_DW+LAMP_PREC_DW)-1:0]		r_r, r_next;
	logic	[$clog2(LAMP_APPROX_MULS)-1:0]				i_r, i_next;
	logic	[2*(1+LAMP_FLOAT_F_DW)-1:0]					res_next;
	logic												valid_next;

//////////////////////////////////////////////////////////////////
// 							state enum							//
//////////////////////////////////////////////////////////////////

	typedef enum logic [1:0]
	{
		IDLE	= 'd0,
		MUL		= 'd1,
		COMPL	= 'd2
	}	ssFractDiv_t;

	ssFractDiv_t	ss, ss_next;

//////////////////////////////////////////////////////////////////
// 						sequential logic						//
//////////////////////////////////////////////////////////////////

	always_ff @(posedge clk)
	begin
		if (rst)
		begin
			ss		<=	IDLE;
			n_r		<=	'0;
			d_r		<=	'0;
			r_r		<=	'0;
			i_r		<=	'0;
			res_o	<=	'0;
			valid_o	<=	1'b0;
		end
		else
		begin
			ss		<=	ss_next;
			n_r		<=	n_next;
			d_r		<=	d_next;
			r_r		<=	r_next;
			i_r		<=	i_next;
			res_o	<=	res_next;
			valid_o	<=	valid_next;
		end
	end

//////////////////////////////////////////////////////////////////
// 						combinational logic						//
//////////////////////////////////////////////////////////////////

	always_comb
	begin
		ss_next		=	ss;
		n_tmp		=	n_r * r_r;
		d_tmp		=	d_r * r_r;
		n_next		=	n_r;
		d_next		=	d_r;
		r_next		=	r_r;
		i_next		=	i_r;
		res_next	=	res_o;
		valid_next	=	1'b0;
		case (ss)
			IDLE:
			begin
				if (doDiv_i)
				begin
					ss_next		=	MUL;
					n_next		=	n_i << LAMP_PREC_DW;
					d_next		=	d_i << LAMP_PREC_DW;
					r_next		=	{2'b01, FUNC_approxRecip (d_i)} << ((1+LAMP_FLOAT_F_DW+LAMP_PREC_DW)-(LAMP_APPROX_DW+2));
					i_next		=	'0;
				end
			end
			MUL:
			begin
				if (i_r == LAMP_APPROX_MULS - 1)
				begin
					ss_next		=	IDLE;
					res_next	=	n_tmp[(2*(1+LAMP_FLOAT_F_DW+LAMP_PREC_DW)-1)-:(2*(1+LAMP_FLOAT_F_DW))];
					valid_next	=	1'b1;
				end
				else
					ss_next		=	COMPL;
				n_next			=	n_tmp[(2*(1+LAMP_FLOAT_F_DW+LAMP_PREC_DW)-2)-:(1+LAMP_FLOAT_F_DW+LAMP_PREC_DW)];
				d_next			=	d_tmp[(2*(1+LAMP_FLOAT_F_DW+LAMP_PREC_DW)-2)-:(1+LAMP_FLOAT_F_DW+LAMP_PREC_DW)];
			end
			COMPL:
			begin
				ss_next			=	MUL;
				r_next			=	(1'b1 << (LAMP_FLOAT_F_DW+2+LAMP_PREC_DW)) - d_r;
				i_next			=	i_r + 1;
			end
		endcase
	end

endmodule
