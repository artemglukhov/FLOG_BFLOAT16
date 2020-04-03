package flog_pkg;

    //per importarlo inserire nel file sotto la dichiarazione del modulo 'import flog_pkg::*'

    parameter S_WIDTH           = 1;                                        //sign width
    parameter FRACT_WIDTH       = 7;                                      //nominal width of the mantissa
    parameter EXP_WIDTH         = 8;                                        //nominal width of the exponent

    parameter FRACT_WIDTH_PHILO = 16;                                     //width of the mantissa for philo algorithm
    parameter OUT_WIDTH_PHILO   = 7;                                        //width for the output vector of the philo algorithm
    parameter N_IT_PHILO        = ($clog2(OUT_WIDTH_PHILO)-1);              //number of iterations in philo algorithm

    parameter BIAS              = 127;                                      //(1<<7)-1                                      //exponent bias

    parameter DIM               = 22;                                       //?? definizione??
    parameter COMMA_POS         = 14;                                       //comma position


    /*  for future reference 
        (&_op_i) = 1         se tutti i bit sono 1
        ~(&_op_i) = 1        se almeno un bit � a 0
        (|_op_i) = 1         se almeno un bit � a 1
        ~(|_op_i) = 1        se tutti i bit sono a 0
    */

    function automatic logic [6-1:0] FUNC_SpecialCaseDetector(input s_op_i, input [EXP_WIDTH-1:0] exp_op_i, input [FRACT_WIDTH-1:0] fract_op_i);

    logic isNeg_o, isPosInf_o, isPosZero_o, isQNaN_o, isSNaN_o, isOpValid_o;

    isNeg_o     = (s_op_i);                                                                     //if s=1 the op is negative
    isPosInf_o  = ~(s_op_i) & (&exp_op_i) & ~(|fract_op_i);                                     //+inf 0_11111111_0000000   0xff00 
    isPosZero_o = ~(s_op_i) & ~(|exp_op_i) & ~(|fract_op_i);                                    //+0   0_00000000_0000000   0x0000 
    isQNaN_o    = (&exp_op_i) & (fract_op_i[FRACT_WIDTH-1]) & ~(|fract_op_i[FRACT_WIDTH-2:0]);  //QNaN 11111111_1000000     0xff40
    isSNaN_o    = (&exp_op_i) & (~fract_op_i[FRACT_WIDTH-1]) & (&fract_op_i[FRACT_WIDTH-2:0]);  //SNaN 11111111_0111111     0xff7f 
   
    isOpValid_o = ~(isNeg_o|isPosInf_o|isPosZero_o|isQNaN_o|isSNaN_o);                          //the operand is valid
   
    return {isNeg_o, isPosInf_o, isPosZero_o, isQNaN_o, isSNaN_o,isOpValid_o};
    endfunction









    /*          SPECIAL CASES
        parameter INF				=	15'h7f80;							//Infinito nello standard IEEE754   11111111_0000000
        parameter ZERO				=	15'h0000;							//Zero nello standard IEEE754       00000000_0000000
        parameter SNAN				=	15'h7fbf;							//Signaling NaN nello standard 	    11111111_0111111
        parameter QNAN				=	15'h7fc0;							//Quiet NaN nello standard  	    11111111_1000000

        parameter PLUS_INF			=	16'h7f80;							//+inf 0_11111111_0000000
        parameter MINUS_INF			=	16'hff80;							//-inf 1_11111111_0000000
        parameter PLUS_ZERO			=	16'h0000;							//+0   0_00000000_0000000
        parameter MINUS_ZERO		=	16'h8000;							//-0   1_00000000_0000000

    */
endpackage