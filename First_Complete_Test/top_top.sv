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
    input			[FRACT_WIDTH-1:0]		    fractional;
    input                                   valid_i;

    //	outputs
    output	logic					        s_res_o;
    output	logic	[EXP_WIDTH-1:0]		    e_res_o;
    output	logic	[FRACT_WIDTH-1:0]         f_res_o;
    output	logic					        valid_o;

    
    logic           [FRACT_WIDTH_PHILO-1:0]   initial_value;
    logic                                   valid_philo_i;
    logic           [OUT_WIDTH_PHILO-1:0]   output_philo;
    logic                                   valid_philo_o;

    logic           [FRACT_WIDTH_PHILO-1:0]   initial_value_next;
    logic                                   valid_philo_i_next;     

    logic           [EXP_WIDTH-1:0]         exp_biased;
    logic           [EXP_WIDTH-1:0]         exp_biased_next;

    logic                                   valid_i2f_i;
    logic           [EXP_WIDTH-1 : 0]       parte_intera;
    logic           [FRACT_WIDTH-1 : 0]       parte_frazionaria;
    logic                                   valid_i2f_o;

    typedef enum logic [1:0]                //stati per la FSM
    {
        START         = 'd0,                //start flog
        WAIT_PHILO    = 'd1,                //wait for the result of philo
        WAIT_I2F      = 'd2,
        OUT_RES       = 'd3                 //output the result, sum and done
    }ss_top;

    ss_top    ss, ss_next;

    /*
     *      Instantiation of philo algorithm
     */
    philo my_philo(
        .clk            (clk),
        .rst            (rst),
        //inputs
        .initial_value  (initial_value),                                                      //mantissa -> 1.M     10101010 (da vedere come fixed point cioe' 1.0101010)
        .valid_philo_i  (valid_philo_i),
        //outputs
        .output_value   (output_philo),                                                     //log2(man) -> (0).b7b6b5b4.. lo zero non Ã¨ dato dall'algoritmo, e' sottointeso (dovremo concatenarlo? servira'?)   
        .valid_philo_o  (valid_philo_o)
    );

    /*
     *      Instantiation of philo algorithm
     */
     i2f my_i2f(
         .clk               (clk),
         .rst               (rst),
         .valid_i2f_i       (valid_i2f_i),
         .parte_intera      (parte_intera),
         .parte_frazionaria (parte_frazionaria),
         .mantissa_o        (f_res_o),
         .exp_o             (e_res_o),
         .sgn_o             (s_res_o),
         .valid_i2f_o       (valid_i2f_o)
     );

/*-------- SEQUENTIAL LOGIC --------*/
    always@(posedge clk)
    begin
        if(rst)begin
            initial_value   <=  0;
            valid_philo_i   <=  0;
            //s_res_o         <=  0;           
            //e_res_o         <=  0;
            //f_res_o         <=  0;
            valid_o         <=  0;
            exp_biased      <=  0;
            ss              <=  START;
        end
        else
        begin
            ss              <=  ss_next;
            initial_value   <=  initial_value_next;
            valid_philo_i   <=  valid_philo_i_next;
            exp_biased      <=  exp_biased_next;
        end
    end

/*-------- COMBINATORY LOGIC --------*/
    always_comb
    begin
        ss_next             = ss;
        initial_value_next  = initial_value;
        valid_philo_i_next  = valid_philo_i;
        exp_biased_next     = exp_biased;

        case(ss)
            START:
            begin
                valid_o                 = 0;
                exp_biased_next         = exponent - BIAS;                  // biases the exponent (CPL2 notation)
                initial_value_next      = (1 << 15) | (fractional << 8);    
                if(valid_i == 1) 
                begin
                    valid_philo_i_next  = 1;
                    ss_next             = WAIT_PHILO;
                end
            end
            WAIT_PHILO:
            begin
                if(valid_philo_o == 1) 
                begin
                    valid_philo_i_next    = 0;
                    ss_next             = WAIT_I2F;
                end
            end
            WAIT_I2F:
            begin
                parte_frazionaria   = output_philo[OUT_WIDTH_PHILO-1:OUT_WIDTH_PHILO-7];
                parte_intera        = exp_biased;
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
                    ss_next     = START;
            end
        endcase
    end
endmodule