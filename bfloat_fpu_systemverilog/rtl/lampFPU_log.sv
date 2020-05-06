module lampFPU_log (
    clk,rst,
    //inputs
    doLog_i,
    s_op_i, extE_op1_i, extF_op1_i,
    isZ_op_i, isInf_op_i, isSNAN_op_i, isQNAN_op_i,

    //outputs
    s_res_o, e_res_o, f_res_o, valid_o,
    isOverflow_o, isUnderflow_o, isToRound_o
);

import lampFPU_pkg::*;
parameter SQRT2     =   8'b10110101;                                    //1.4140625 sqrt(2) in 8 bit-> 1.0110101                                                     
                                     

parameter G0        =   1;                                              //guard bit for precision/rounding
parameter G1        =   3;                                              //guard bit for precision/rounding
parameter LOG2      =   10'b1011000101;                                 //0.6931471806;

input                                       clk;
input                                       rst;
//inputs
input                                               doLog_i;
input           [LAMP_FLOAT_S_DW-1:0]               s_op_i;
input           [LAMP_FLOAT_E_DW:0]                 extE_op1_i;
input           [LAMP_FLOAT_F_DW:0]                 extF_op1_i;
input                                               isZ_op_i;
input                                               isInf_op_i;
input                                               isSNAN_op_i;
input                                               isQNAN_op_i;
//outputs
output logic    [LAMP_FLOAT_S_DW-1:0]               s_res_o;
output logic    [LAMP_FLOAT_E_DW-1:0]               e_res_o;
output logic    [(1+1+LAMP_FLOAT_F_DW+3)-1:0]       f_res_o;            
output logic							            valid_o;
output logic                                        isOverflow_o;
output logic                                        isUnderflow_o;
output logic                                        isToRound_o;

//////////////////////////////////////////////////
//              internal wires                  //
//////////////////////////////////////////////////



logic   [LAMP_FLOAT_E_DW  :0]               e_op_r;                     //register of the input exponent- 1bit padding for overflow correction
logic   [LAMP_FLOAT_F_DW  :0]               f_op_r;                     //register of the input fractional, padded for hidden bit
logic   [LAMP_FLOAT_S_DW-1:0]               s_res_r, s_res_r_n;
logic   [LAMP_FLOAT_E_DW-1:0]               e_res_r, e_res_r_n;
logic   [(1+1+LAMP_FLOAT_F_DW+3)-1:0]       f_res_r, f_res_r_n;
logic									    valid, valid_n;
logic									    isOverflow;
logic									    isUnderflow;
logic									    isToRound;

logic									    stickyBit;

logic									    isCheckNanInfValid;
logic									    isCheckInfRes;
logic									    isCheckNanRes;
logic									    isCheckSignRes;


logic                                                       compare_sqrt2;
logic   [(LAMP_FLOAT_F_DW + G0 + 2+2)-1 : 0]                lut_output;                                     //lut output wf+g0+2 bits
logic   [(LAMP_FLOAT_F_DW+1)-1 : 0]                         f_temp;                                         //(M-1)*(+-1)= (1.F-1)*(+-1) -> wf+1 bits          
logic   [LAMP_FLOAT_S_DW-1:0]                               s_intermediate, s_intermediate_n;
logic   [(LAMP_FLOAT_E_DW + LAMP_FLOAT_F_DW + G1)-1 : 0]    e_intermediate, e_intermediate_n;               //X = result of log(2)*exp -> we+wf+g1 bits
logic   [(2*LAMP_FLOAT_F_DW+G0+3+1)-1 : 0]                  f_intermediate, f_intermediate_n;               //Y = result of f_temp*lut_ouput -> 2wf+g0+4 bits
logic   [(LAMP_FLOAT_E_DW+2*LAMP_FLOAT_F_DW+G0+1)-1 : 0]    res_preNorm;                                    //Z = X + Y -> we+2wf+g0+1 bits
logic                                                       is_f_temp_negative, is_f_temp_negative_n;

//////////////////////////////////////////////////////////////////
// 							state enum							//
//////////////////////////////////////////////////////////////////

	typedef enum logic [1:0]
	{
		IDLE	= 'd0,
		WORK	= 'd1,
		OUT	    = 'd2
    }	ssLog;

	ssLog 	ss, ss_next;


//////////////////////////////////////////////////
//              sequential                      //
//////////////////////////////////////////////////

always@(posedge clk)
begin
    if(rst)
    begin
        //output registers
        s_res_o             <= '0;
        e_res_o             <= '0;
        f_res_o             <= '0;
        valid_o             <= '0;    
        isOverflow_o        <= '0;
        isUnderflow_o       <= '0;
        isToRound_o         <= '0;

        ss                  <= IDLE;
        is_f_temp_negative  <= '0;
        s_intermediate      <= '0;
        e_intermediate      <= '0;
        f_intermediate      <= '0;
    end
    else
    begin
        //output registers
        s_res_o             <= s_res_r_n;
        e_res_o             <= e_res_r_n;
        f_res_o             <= f_res_r_n;
        valid_o             <= valid_n;
        isOverflow_o	    <= isOverflow;
        isUnderflow_o	    <= isUnderflow;
        isToRound_o		    <= isToRound;

        ss                  <= ss_next;
        is_f_temp_negative  <= is_f_temp_negative_n;
        s_intermediate      <= s_intermediate_n;
        e_intermediate      <= e_intermediate_n;
        f_intermediate      <= f_intermediate_n;
    end
end


//////////////////////////////////////////////////
//          combinational logic                 //
//////////////////////////////////////////////////
always_comb
begin
    ss_next                 =   ss;
    is_f_temp_negative_n    =   is_f_temp_negative;
    s_intermediate_n        =   s_intermediate;
    e_intermediate_n        =   e_intermediate;
    f_intermediate_n        =   f_intermediate;
    valid_n                 =   valid;
    isOverflow              =   1'b0;                                                       //never goes to overflow
    isUnderflow             =   1'b0;                                                       //never goes to underflow

    case(ss)
        IDLE:
        begin
            if(doLog_i)
                ss_next = WORK;
        end
        WORK:
        begin
            compare_sqrt2 = (extF_op1_i > SQRT2) ? 1'b1 : 1'b0;                             //compare F with square root of 2
            

            if(compare_sqrt2)
            begin
                f_op_r  = (extF_op1_i >> 1);                                                //fractional part divided by 2
                e_op_r  = extE_op1_i - LAMP_FLOAT_E_BIAS + 1;                               //exponent - bias + 1
            end
            else
            begin
                f_op_r  = extF_op1_i;                                                       //fractional part
                e_op_r  = extE_op1_i - LAMP_FLOAT_E_BIAS;                                   //exponent - bias
            end
            
            f_temp = f_op_r - (128);                                                        // f_op_r - 1.0 
            lut_output = LUT_log(f_op_r);                                                   //f(x) = log(x)/(x-1)

            if(f_temp[(LAMP_FLOAT_F_DW+1)-1])                                               //if the first bit is 1 -> negative value so we make it positive
            begin
                f_temp  = (~f_temp) + 1;
                is_f_temp_negative_n = 1;
            end
            else
            begin
                is_f_temp_negative_n = 0;
            end

            s_intermediate_n = (|e_op_r) ? e_op_r[LAMP_FLOAT_E_DW] : compare_sqrt2;         //if E=0 sign=compare_sqrt2; if E!=0 sign=MSB of e_op_r

            
            
            f_intermediate_n = f_temp * lut_output;                                         //result in xxx.yyyyy(...) (3bit . 16bit)

            if(s_intermediate_n)                                                            //if the sign is positive, we have to complement the exponent 
            begin
                e_op_r         = (~e_op_r) + 1;
            end

            e_intermediate_n = e_op_r[LAMP_FLOAT_E_DW-1:0] * LOG2;                          //result in xxxxxxxxx.yyyyyyyyyy (8bit . 10bit)


            ss_next = OUT;
        end
        OUT:
        begin
            {isCheckNanInfValid, isCheckNanRes, isCheckInfRes, isCheckSignRes} = FUNC_calcInfNanResLog(isZ_op_i, isInf_op_i, isSNAN_op_i, isQNAN_op_i, s_op_i);         //function which calculate the result if the input is a special case
            
             /*we have e_int and f_int as positive numbers, always. So we have to subtract them in modulus 
              *when the result is negative (s_int = 1) or (XOR) the result is positive but the fract 
              *is negative (is_f_temp_negative = 1) otherwise we have to sum them in modulus
              *  f<0     res<0       sum/sub
              *   0        0            +   
              *   0        1            -
              *   1        0            -
              *   1        1            +
             */
            if(is_f_temp_negative ^ s_intermediate)       
            begin
                res_preNorm = {e_intermediate ,6'b0} - {5'b0, f_intermediate};          //result in xxxxxxxxx.yyyyyy(...) (8bit . 16bit); 24 bit, resPreNorm never overflows
            end
            else
            begin
                res_preNorm = {e_intermediate ,6'b0} + {5'b0, f_intermediate};          //24 bit, resPreNorm never overflows
            end



            unique if(isCheckNanRes)
                {s_res_r_n, e_res_r_n, f_res_r_n}     =   {isCheckSignRes, QNAN_E_F, 5'b0};
            else if(isCheckInfRes)
                {s_res_r_n, e_res_r_n, f_res_r_n}     =   {isCheckSignRes, INF_E_F, 5'b0};
            else
            begin
                {s_res_r_n, e_res_r_n, f_res_r_n}     =   {s_intermediate, FUNC_fix2float_log(res_preNorm), 2'b00};         //fixed point to floating point
                f_res_r_n                             =   {1'b0, 1'b1, f_res_r_n[11:2]};
            end


            valid_n = 1'b1;        
            isToRound = ~isCheckNanInfValid;                                            //result is to round if it is not a special case

            ss_next = IDLE;
        end
    endcase

    
    

end

endmodule
