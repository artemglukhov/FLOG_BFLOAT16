`timescale 1ns / 1ps

module philo(
    clk,
    rst,

    // inputs

    initial_value,         //mantissa -> 1.M     10101010 (da vedere come fixed point cioe' 1.0101010)
    valid_philo_i,

    //outputs

    output_value,          //log2(man) -> (0).b7b6b5b4.. lo zero non e' dato dall'algoritmo, e' sottointeso (dovremo concatenarlo? servira'?)   
    valid_philo_o
    );
                           
    import flog_pkg::*;

    input                                       clk;
    input                                       rst;
    input                                       valid_philo_i;
    input   logic   [(FRACT_WIDTH_PHILO-1):0]     initial_value;      //fixed point (GIA ESTESO con 0 come LSBs) value between 1 and 2, 8 bit
    output  logic                               valid_philo_o;
    output  logic   [(OUT_WIDTH_PHILO-1):0]     output_value;       
    
    logic           [(2*FRACT_WIDTH_PHILO-1):0]   PowM, PowM_next;     //pow 32 bit (16+16)
    logic           [(FRACT_WIDTH_PHILO-1):0]     man, man_next;
    logic           [(OUT_WIDTH_PHILO-1):0]     out, out_next;
    logic           [N_IT_PHILO:0]              count, count_next;   //a ogni iterazione riempio un bit di out quindi count deve essere parametrizzato a OUT_WIDTH_PHILO


    typedef enum logic [1:0]                                 //stati per la FSM
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
            count           <= (OUT_WIDTH_PHILO-1);             //parte da (OUT_WIDTH_PHILO-1) perche' la prima iterazione mi da' il msb della parte frazionaria 0.b7b6b5b4...
            man             <= '0;
            PowM            <= '0;
            out             <= '0;
            valid_philo_o   <=  0;
        end
        else
        begin
            ss              <=  ss_next;
            count           <=  count_next;
            man             <=  man_next;
            PowM            <=  PowM_next;
            out             <=  out_next;
        end
    end
    
/*-------- COMBINATORY LOGIC --------*/    
    always_comb 
    begin
        ss_next     =   ss;
        count_next  =   count;
        man_next    =   man;
        PowM_next   =   PowM;
        out_next    =   out;
        
        case(ss)
            IDLE:                                                       //IDLE                                                   
            begin
                valid_philo_o       = 0;

                if(valid_philo_i)
                begin
                    ss_next         = EVAL;
                    count_next      = (OUT_WIDTH_PHILO-1);          
                    man_next        = initial_value;
                    PowM_next       = initial_value*initial_value;
                    valid_philo_o   = 0;
                    out_next        = '0;
                end
            end                                                         //end IDLE
            EVAL:                                                       //EVAL
            begin
                if(PowM[(2*FRACT_WIDTH_PHILO-1)])
                begin
                    out_next[count] = 1;                                //pow >=2 quindi il bit e' 1
                    man_next        = PowM[(2*FRACT_WIDTH_PHILO-1):16];           //il prossimo operand e' la potenza diviso due (quindi prendo i 16 MSB di pow)     
                    PowM_next       = PowM[(2*FRACT_WIDTH_PHILO-1):16]*PowM[(2*FRACT_WIDTH_PHILO-1):16];          //la prossima potenza e' man_next*man_next 
                end
                else
                begin
                    out_next[count] = 0;                                //pow <2 quindi il bit e' 0
                    man_next        = PowM[(2*FRACT_WIDTH_PHILO-2):15];                                   //il prossimo operand e' la potenza stessa (quindi prendo i 16 bit dopo l'MSB che sara' 0 essendo <2)
                    PowM_next       = PowM[(2*FRACT_WIDTH_PHILO-2):15]*PowM[(2*FRACT_WIDTH_PHILO-2):15];          //la prossima potenza e' man_next * man_next
                end
                if(count == 0)                                          //se count == 0 abbiamo finito le iterazioni
                begin
                    ss_next = DONE;
                end
                else                                                    //altrimenti diminuiamo count
                begin
                    count_next = count - 1;
                end

            end                                                         //end EVAL
            DONE:                                                       //DONE
            begin
                valid_philo_o   = 1;
                ss_next         = IDLE;
                //servira'  un DONE? per cosa potremmo usarlo?
                //ss_next = IDLE;
                //si potrebbe aggiungere un valid in uscita che va a 1
            end                                                         //end DONE
        endcase
    end

    assign output_value = out;                                          //assegno out all'uscita

endmodule
