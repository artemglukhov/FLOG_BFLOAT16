`timescale 1ns / 1ps
`include "philo.sv"
`include "i2f.sv"

module top_top(
    clk, 
    rst,

	//	inputs
	sign,        
    exponent,        
    fractional,        
    valid_i,
	
	//	outputs
	s_res_o,           
    e_res_o,
    f_res_o,
    valid_o
    );

    import flog_pkg::*;

    input						            clk;
    input							        rst;
    
    //	inputs
    input			                        sign;
    input			[EXP_WIDTH-1:0]         exponent;
    input			[FRACT_WIDTH-1:0]		fractional;
    input                                   valid_i;

    //	outputs
    output	logic					        s_res_o;
    output	logic	[EXP_WIDTH-1:0]		    e_res_o;
    output	logic	[FRACT_WIDTH-1:0]       f_res_o;
    output	logic					        valid_o;

    
    logic                                   s_res_r, s_res_next;
    logic           [EXP_WIDTH-1:0]         e_res_r, e_res_next;
    logic           [FRACT_WIDTH-1:0]       f_res_r, f_res_next;
    
    logic                                   s_res_i2f;
    logic           [EXP_WIDTH-1:0]         e_res_i2f;
    logic           [FRACT_WIDTH-1:0]       f_res_i2f;
    
    logic           [FRACT_WIDTH_PHILO-1:0] input_philo;
    logic                                   valid_philo_i;
    logic           [OUT_WIDTH_PHILO-1:0]   output_philo;
    logic                                   valid_philo_o;

    logic           [FRACT_WIDTH_PHILO-1:0] input_philo_next;
    logic                                   valid_philo_i_next;     

    logic           [EXP_WIDTH-1:0]         exp_biased;
    logic           [EXP_WIDTH-1:0]         exp_biased_next;

    logic                                   valid_i2f_i;
    logic           [EXP_WIDTH-1:0]         integer_i;
    logic           [FRACT_WIDTH-1:0]       log_f_i;
    logic                                   valid_i2f_o;

    logic                                   isNeg, isNeg_next;
    logic                                   isPosInf, isPosInf_next;
    logic                                   isPosZero, isPosZero_next;
    logic                                   isQNaN, isQNaN_next;
    logic                                   isSNaN, isSNaN_next;
    logic                                   isNaN, isNaN_next;
    logic                                   isOpValid, isOpValid_next;

    typedef enum logic [2:0]                //stati per la FSM
    {
        START         = 'd0,                //start flog
        CHECK_OP      = 'd1,                //check operand
        WAIT_PHILO    = 'd2,                //wait for the result of philo
        WAIT_I2F      = 'd3,
        OUT_RES       = 'd4                 //output the result, sum and done
    }ss_top;

    ss_top    ss, ss_next;

    /*
     *      Instantiation of philo algorithm
     */
    philo my_philo(
        .clk            (clk),
        .rst            (rst),
        //inputs
        .fract_i        (input_philo),                                                      //mantissa -> 1.M     10101010 (da vedere come fixed point cioe' 1.0101010)
        .valid_philo_i  (valid_philo_i),
        //outputs
        .result_o       (output_philo),                                                     //log2(man) -> (0).b7b6b5b4.. lo zero non e' dato dall'algoritmo, e' sottointeso (dovremo concatenarlo? servira'?)   
        .valid_philo_o  (valid_philo_o)
    );

    /*
     *      Instantiation of i2f
     */
     i2f my_i2f(
         .clk               (clk),
         .rst               (rst),
         .valid_i2f_i       (valid_i2f_i),
         .integer_i         (integer_i),
         .log_f_i           (log_f_i),
         .fract_o           (f_res_i2f),
         .exp_o             (e_res_i2f),
         .sgn_o             (s_res_i2f),
         .valid_i2f_o       (valid_i2f_o)
     );

/*-------- SEQUENTIAL LOGIC --------*/
    always@(posedge clk)
    begin
        if(rst)begin
            ss              <=  START;
            input_philo     <=  0;
            valid_philo_i   <=  0;
            s_res_r         <=  0;           
            e_res_r         <=  0;
            f_res_r         <=  0;
            valid_o         <=  0;
            exp_biased      <=  0;
            isNeg           <=  0;
            isPosInf        <=  0;
            isPosZero       <=  0;
            isQNaN          <=  0;
            isSNaN          <=  0;
            isNaN          <=  0;
            isOpValid       <=  0;
        end
        else
        begin
            ss              <=  ss_next;
            input_philo     <=  input_philo_next;
            valid_philo_i   <=  valid_philo_i_next;
            s_res_r         <=  s_res_next;
            e_res_r         <=  e_res_next;
            f_res_r         <=  f_res_next;
            exp_biased      <=  exp_biased_next;
            isNeg           <=  isNeg_next;
            isPosInf        <=  isPosInf_next;
            isPosZero       <=  isPosZero_next;
            isQNaN          <=  isQNaN_next;
            isSNaN          <=  isSNaN_next;
            isNaN          <=  isNaN_next;
            isOpValid       <=  isOpValid_next;
        end
    end

/*-------- COMBINATORY LOGIC --------*/
    always_comb
    begin
        ss_next             = ss;
        input_philo_next    = input_philo;
        valid_philo_i_next  = valid_philo_i;
        s_res_next          = s_res_r;
        e_res_next          = e_res_r;
        f_res_next          = f_res_r;
        exp_biased_next     = exp_biased;
        isNeg_next          = isNeg;
        isPosInf_next       = isPosInf;
        isPosZero_next      = isPosZero;
        isQNaN_next         = isQNaN;
        isSNaN_next         = isSNaN;    
        isNaN_next         = isNaN;    
        isOpValid_next      = isOpValid;

        case(ss)
            START:
            begin
                valid_o                 = 0;
                exp_biased_next         = exponent - BIAS;                  // biases the exponent (CPL2 notation)
                input_philo_next        = (1 << 15) | (fractional << 8);    
                if(valid_i == 1) 
                begin
                    {isNeg_next, isPosInf_next, isPosZero_next, isQNaN_next, isSNaN_next,isNaN_next,isOpValid_next} = FUNC_SpecialCaseDetector(sign, exponent, fractional);
                    ss_next = CHECK_OP;
                    // if(isOpValid_next)
                    //     valid_philo_i_next  = 1;
                    //     ss_next             = WAIT_PHILO;
                end
            end
            CHECK_OP:
            begin
                if(isOpValid)                                                                       //if op is valid go ahead with algorithm
                begin
                    valid_philo_i_next  = 1;
                    ss_next             = WAIT_PHILO;
                end
                else if(isNeg)                                                                      //if op is <0
                begin
                    {s_res_next, e_res_next, f_res_next} = {1'b0, 8'b1111_1111, 7'b1000_000};       //return QNaN (sign = 0, anche se in realta e don't care) (decidere se Q o S)
                    ss_next = OUT_RES;
                end
                else if(isPosInf)                                                                   //if op is +inf
                begin
                    {s_res_next, e_res_next, f_res_next} = {1'b0, 8'b1111_1111, 7'b0000_000};       //return +inf
                    ss_next = OUT_RES;
                end
                else if(isPosZero)                                                                  //if op is 0+
                begin
                    {s_res_next, e_res_next, f_res_next} = {1'b1, 8'b1111_1111, 7'b0000_000};       //return -inf
                    ss_next = OUT_RES;
                end
                else if(isQNaN)                                                                     //if op is QNaN
                begin
                    {s_res_next, e_res_next, f_res_next} = {1'b0, 8'b1111_1111, 7'b1000_000};       //return QNaN
                    ss_next = OUT_RES;
                end
                else if(isSNaN)                                                                     //if op is SNaN             
                begin
                    {s_res_next, e_res_next, f_res_next} = {1'b0, 8'b1111_1111, 7'b0111_111};       //return SNaN
                    ss_next = OUT_RES;
                end
                else if(isNaN)
                begin
                    {s_res_next, e_res_next, f_res_next} = {1'b0, 8'b1111_1111, 7'b1000_000};       //return QNaN
                    ss_next = OUT_RES;
                end

            end
            WAIT_PHILO:
            begin
                if(valid_philo_o == 1) 
                begin
                    valid_philo_i_next  = 0;
                    ss_next             = WAIT_I2F;
                end
            end
            WAIT_I2F:
            begin
                log_f_i             =   output_philo;
                integer_i           =   exp_biased;
                //s_res_o           = sign;
                valid_i2f_i         = 1;
                if(valid_i2f_o)
                begin
                    ss_next         = OUT_RES;
                end
            end
            OUT_RES:
            begin
                    valid_i2f_i = 0;
                    valid_o     = 1;
                    if(isOpValid)                           //MUX to select output
                    begin                                   //out if op is valid
                        s_res_o = s_res_i2f;
                        e_res_o = e_res_i2f;
                        f_res_o = f_res_i2f;
                    end
                    else
                    begin                                   //out if op is a special case
                        s_res_o = s_res_r;
                        e_res_o = e_res_r;
                        f_res_o = f_res_r;
                    end
                    ss_next     = START;
            end
        endcase
    end
    
    
endmodule