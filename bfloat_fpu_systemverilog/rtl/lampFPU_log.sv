module lampFPU_log (
    clk,rst,
    //inputs
    doLog_i,
    s_op_i, e_op_i, f_op_i,
    isZ_op_i, isInf_op_i, isSNAN_op_i, isQNAN_op_i, isDN_op_i,

    //outputs
    s_res_o, e_res_o, f_res_o, valid_o,
    isOverflow_o, isUnderflow_o, isToRound_o
);

import lampFPU_pkg::*;
parameter SQRT2     =   7'b0110101; //1.4140625                         1.0110101       sqrt(2) in 8 bit  -> 181                                                            
                                    //                                  0.1011010       sqrt(2)/2 in 8 bit -> 90

parameter G0        =   1;          //guard bit for precision/rounding
parameter G1        =   3;          //guard bit for precision/rounding
parameter LOG2      =   10'b1011000101; //0.6931471806;

input                                       clk;
input                                       rst;
//inputs
input                                       doLog_i;
input           [LAMP_FLOAT_S_DW-1:0]       s_op_i;
input           [LAMP_FLOAT_E_DW-1:0]       e_op_i;
input           [LAMP_FLOAT_F_DW-1:0]       f_op_i;
input                                       isZ_op_i;
input                                       isInf_op_i;
input                                       isSNAN_op_i;
input                                       isQNAN_op_i;
input                                       isDN_op_i;
//outputs
output logic    [LAMP_FLOAT_S_DW-1:0]               s_res_o;
output logic    [LAMP_FLOAT_E_DW-1:0]               e_res_o;
output logic    [(1+1+LAMP_FLOAT_F_DW+3)-1:0]       f_res_o;        //to connect to post_norm
output logic							            valid_o;
output logic                                        isOverflow_o;
output logic                                        isUnderflow_o;
output logic                                        isToRound_o;

//////////////////////////////////////////////////
//              internal wires                  //
//////////////////////////////////////////////////



logic   [LAMP_FLOAT_E_DW  :0]               e_op_r; //register of the input exponent    - 1bit MSB padding for overflow correction
logic   [LAMP_FLOAT_F_DW  :0]               f_op_r; //register of the input fractional, padded for 1.f
logic   [LAMP_FLOAT_S_DW-1:0]               s_res_r;
logic   [LAMP_FLOAT_E_DW-1:0]               e_res_r;
logic   [(1+1+LAMP_FLOAT_F_DW+3)-1:0]       f_res_r;
logic									    valid;
logic									    isOverflow;
logic									    isUnderflow;
logic									    isToRound;

logic									    stickyBit;

logic									    isCheckNanInfValid;
logic									    isZeroRes;
logic									    isCheckInfRes;
logic									    isCheckNanRes;
logic									    isCheckSignRes;


logic                                                       compare_sqrt2;
logic   [(LAMP_FLOAT_F_DW + G0 + 2)-1 : 0]                  lut_output;                 //lut output wf+g0+2 bits
logic   [(LAMP_FLOAT_F_DW+1)-1 : 0]                         f_temp;                     //(M-1)*(+-1)= (1.F-1)*(+-1) -> wf+1 bits          
logic   [LAMP_FLOAT_S_DW-1:0]                               s_intermediate;
logic   [(LAMP_FLOAT_E_DW + LAMP_FLOAT_F_DW + G1)-1 : 0]    e_intermediate;             //X = result of log(2)*exp -> we+wf+g1 bits
logic   [(2*LAMP_FLOAT_F_DW+G0+3)-1 : 0]                    f_intermediate;             //Y = result of f_temp*lut_ouput -> 2wf+g0+3 bits
logic   [(LAMP_FLOAT_E_DW+2*LAMP_FLOAT_F_DW+G0+2)-1 : 0]    res_preNorm;                //Z = X + Y -> we+2wf+g0+2 bits
logic                                                       is_f_temp_negative;
//////////////////////////////////////////////////
//              sequential                      //
//////////////////////////////////////////////////

always@(posedge clk)
begin
    if(rst)
    begin
        //output registers
        s_res_o         <= '0;
        e_res_o         <= '0;
        f_res_o         <= '0;
        valid_o         <= '0;    
        isOverflow_o    <= '0;
        isUnderflow_o   <= '0;
        isToRound_o     <= '0;
    end
    else
    begin
        //output registers
        s_res_o         <= s_res_r;
        e_res_o         <= e_res_r;
        f_res_o         <= f_res_r;
        valid_o         <= valid;
        isOverflow_o	<= isOverflow;
        isUnderflow_o	<= isUnderflow;
        isToRound_o		<= isToRound;
    end
end


//////////////////////////////////////////////////
//          combinational logic                 //
//////////////////////////////////////////////////
always_comb
begin
    e_op_r =  {1'b0,e_op_i} - LAMP_FLOAT_E_BIAS;    //biased input exponent - padded for overflow detection
    f_op_r = {1'b1,f_op_i};                    // M=1.F

    compare_sqrt2 = (f_op_r[LAMP_FLOAT_F_DW-1:0] > SQRT2) ? 1'b1 : 1'b0;    //compare if the F is bigger than square root of 2

    if(compare_sqrt2)
    begin
        f_op_r  = (f_op_r >> 1); //divide by 2
        e_op_r  = e_op_r + 1;
    end

    s_intermediate = (|e_op_r) ? e_op_r[LAMP_FLOAT_E_DW] : compare_sqrt2;        //!!WARNING: on the paper it is an AND, but it writes that if E=0 or E!=0, so it should be an OR (?)

    f_temp = f_op_r - (128);   // f_op_r=1.X -> f_temp = 0.X 
    
    if(f_temp[(LAMP_FLOAT_F_DW+1)-1])   //if the first bit is 1 -> aka negative value
    begin
        f_temp  = (~f_temp) + 1;
        is_f_temp_negative = 1;
    end
    else
    begin
        is_f_temp_negative = 0;
    end
   

    if(s_intermediate)     //if the sign is positive, we have to complement and the exponent 
    begin
        e_op_r         = (~e_op_r) + 1;
        //f_temp  = (~f_temp) + 1;
    end

    e_intermediate = e_op_r[LAMP_FLOAT_E_DW-1:0] * LOG2;       //result in xxxxxxxxx.yyyyyyyyyy (8bit . 10bit)

    lut_output = LUT_log(f_op_r);

    f_intermediate = f_temp * lut_output;   //result in xx.yyyy(...) (2bit . 16bit)
    if(is_f_temp_negative ^ s_intermediate)       // A xor B
    begin
        res_preNorm = {e_intermediate ,6'b0} - {6'b0, f_intermediate};  //result in xxxxxxxxx.yyyyyy(...) (9bit . 16bit)
    end
    else
    begin
        res_preNorm = {e_intermediate ,6'b0} + {6'b0, f_intermediate};
    end

    //{e_res_r,f_res_r} = FUNC_fix2float_log(res_preNorm);

    {isCheckNanInfValid, isCheckNanRes, isCheckInfRes, isCheckSignRes} = FUNC_calcInfNanResLog(isZ_op_i, isInf_op_i, isSNAN_op_i, isQNAN_op_i, isDN_op_i, s_op_i);

    unique if(isCheckNanRes)
        {s_res_r, e_res_r, f_res_r}     =   {isCheckSignRes, QNAN_E_F, 5'b0};
    else if(isCheckInfRes)
        {s_res_r, e_res_r, f_res_r}     =   {isCheckSignRes, INF_E_F, 5'b0};
    else
    begin
        {s_res_r, e_res_r, f_res_r}     =   {s_intermediate, FUNC_fix2float_log(res_preNorm), 2'b00};
        f_res_r                         =   {1'b0, 1'b1, f_res_r[11:2]};
    end

    
    valid = doLog_i;        //at the end!
    isToRound = ~isCheckNanInfValid;        //result is to round if it is not a special case

end

endmodule
