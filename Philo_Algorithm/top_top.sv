`timescale 1ns / 1ps
`include "philo.sv"

module top_top(
    clk, 
    rst,

	//	inputs
	sign,        
    exponent,        
    fractional,        
    input_valid,
	
	//	outputs
	s_res_o,           
    e_res_o,
    f_res_o,
    valid_o
    );

    parameter                       MAN         = 7; 
    parameter                       EXP         = 8; 
    parameter                       MAN_WIDTH   = 16;
    parameter                       OUT_WIDTH   = 7; 
    parameter                       BIAS        = 127; //(1<<7)-1

    input						    clk;
    input							rst;
    
    //	inputs
    input			                sign;
    input			[EXP-1:0]       exponent;
    input			[MAN-1:0]		fractional;
    input                           input_valid;

    //	outputs
    output	logic					s_res_o;
    output	logic	[EXP-1:0]		e_res_o;
    output	logic	[MAN-1:0]       f_res_o;
    output	logic					valid_o;

    
    logic   [MAN_WIDTH-1:0]         initial_value;
    logic                           start_philo;
    logic   [OUT_WIDTH-1:0]         output_philo;
    logic                           o_valid_philo;

    logic   [MAN_WIDTH-1:0]         initial_value_next;
    logic                           start_philo_next;

    logic   [EXP-1:0]               exp_biased;
    logic   [EXP-1:0]               exp_biased_next;
    

    typedef enum logic [1:0]            //stati per la FSM
    {
        START   = 'd0,      //start flog
        WAIT    = 'd1,      //wait for the result of philo
        OUT_RES = 'd2       //output the result, sum and done
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
        .in_valid       (start_philo),
        //outputs
        .output_value   (output_philo),                                                     //log2(man) -> (0).b7b6b5b4.. lo zero non Ã¨ dato dall'algoritmo, e' sottointeso (dovremo concatenarlo? servira'?)   
        .out_valid      (o_valid_philo)
    );

/*-------- SEQUENTIAL LOGIC --------*/
    always@(posedge clk)
    begin
        if(rst)begin
            initial_value   <=  0;
            start_philo     <=  0;
            s_res_o         <=  0;           
            e_res_o         <=  0;
            f_res_o         <=  0;
            valid_o         <=  0;
            exp_biased      <=  0;
            ss              <=  START;
        end
        else
        begin
            ss              <=  ss_next;
            initial_value   <=  initial_value_next;
            start_philo     <=  start_philo_next;
            exp_biased      <=  exp_biased_next;
        end
    end

/*-------- COMBINATORY LOGIC --------*/
    always_comb
    begin
        ss_next             = ss;
        initial_value_next  = initial_value;
        start_philo_next    = start_philo;
        exp_biased_next     = exp_biased;

        case(ss)
            START:
            begin
                valid_o             = 0;
                exp_biased_next     = exponent - BIAS;          // biases the exponent
                initial_value_next  = (1 << 15) | (fractional << 8);    
                if(input_valid == 1) 
                begin
                    start_philo_next    = 1;
                    ss_next             = WAIT;
                end
            end
            WAIT:
            begin
                if(o_valid_philo == 1) 
                begin
                    start_philo_next    = 0;
                    ss_next             = OUT_RES;
                end
            end
            OUT_RES:
            begin
                valid_o = 1;
                f_res_o = output_philo[OUT_WIDTH-1:OUT_WIDTH-7];
                e_res_o = exponent;
                s_res_o = sign;
                ss_next = START;
            end
        endcase
    end
endmodule