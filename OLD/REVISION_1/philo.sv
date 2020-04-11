`timescale 1ns / 1ps

module philo(
    clk,
    rst,

    // inputs

    fract_i,         
    valid_philo_i,

    //outputs

    result_o,           
    valid_philo_o
    );
                           
    import flog_pkg::*;

    input                                       clk;
    input                                       rst;
    input                                       valid_philo_i;
    input   logic   [(FRACT_WIDTH_PHILO-1):0]   fract_i;           
    output  logic                               valid_philo_o;
    output  logic   [(OUT_WIDTH_PHILO-1):0]     result_o;       
    
    logic           [(2*FRACT_WIDTH_PHILO-1):0] PowF, PowF_next;     //pow 32 bit (16+16)
    logic           [(FRACT_WIDTH_PHILO-1):0]   fract, fract_next;
    logic           [(OUT_WIDTH_PHILO-1):0]     out, out_next;
    logic           [N_IT_PHILO:0]              count, count_next;   


    typedef enum logic [1:0]                             
    {
        IDLE    = 'd0,
        EVAL    = 'd1,
        DONE    = 'd2
    }ss_philo;
    
    ss_philo    ss, ss_next;

/*-------- SEQUENTIAL LOGIC --------*/    
    always@(posedge clk)
    begin
        if(rst)
        begin
            ss              <=  IDLE;
            count           <= (OUT_WIDTH_PHILO-1);             //count starts from (OUT_WIDTH_PHILO-1) because the first iteraction gives me the MSB of the fractional part
            fract           <= '0;
            PowF            <= '0;
            out             <= '0;
            valid_philo_o   <=  0;
        end
        else
        begin
            ss              <=  ss_next;
            count           <=  count_next;
            fract           <=  fract_next;
            PowF            <=  PowF_next;
            out             <=  out_next;
        end
    end
    
/*-------- COMBINATORY LOGIC --------*/    
    always_comb 
    begin
        ss_next     =   ss;
        count_next  =   count;
        fract_next  =   fract;
        PowF_next   =   PowF;
        out_next    =   out;
        
        case(ss)
            IDLE:                                                                                                        
            begin
                valid_philo_o       = 0;

                if(valid_philo_i)
                begin
                    ss_next         = EVAL;
                    count_next      = (OUT_WIDTH_PHILO-1);          
                    fract_next      = fract_i;
                    PowF_next       = fract_i*fract_i;
                    valid_philo_o   = 0;
                    out_next        = '0;
                end
            end                                                         
            EVAL:                                                       
            begin
                if(PowF[(2*FRACT_WIDTH_PHILO-1)])
                begin
                    out_next[count] = 1;                                                                            //pow >=2 so the bit is 1
                    fract_next      = PowF[(2*FRACT_WIDTH_PHILO-1):16];                                             //next operand is pow/2     
                    PowF_next       = PowF[(2*FRACT_WIDTH_PHILO-1):16]*PowF[(2*FRACT_WIDTH_PHILO-1):16];            //next pow is fract_next*fract_next 
                end
                else
                begin
                    out_next[count] = 0;                                                                            //pow <2 so the bit is 0
                    fract_next      = PowF[(2*FRACT_WIDTH_PHILO-2):15];                                             //next operand is pow 
                    PowF_next       = PowF[(2*FRACT_WIDTH_PHILO-2):15]*PowF[(2*FRACT_WIDTH_PHILO-2):15];            //next pow is fract_next*fract_next 
                end
                if(count == 0)                                                                                      //if count == 0 => DONE
                begin
                    ss_next = DONE;
                end
                else                                                    
                begin
                    count_next = count - 1;
                end

            end                                                        
            DONE:                                                       
            begin
                valid_philo_o   = 1;
                ss_next         = IDLE;
            end                                                         
        endcase
    end

    assign result_o = out;                                                                                          //assigne out to result_o

endmodule
