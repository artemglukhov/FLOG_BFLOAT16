`timescale 1ns / 1ps

module top(
    clk,
    rst,
    // inputs
    initial_value,                                              //mantissa -> 1.M     10101010 (che e da vedere come 1.0101010)
    //outputs
    output_value                                                //log2(man) -> 0.b7b6b5b4..   
    );
    
    //parameter               comp = 16'b1000_0000_0000_0000;           non serve usare il 2, basta l'MSB
    
    parameter               MAN_WIDTH = 16;
    parameter               OUT_WIDTH = 12;                             
                                                                      
    input                   clk;
    input                   rst;
    input   logic [(MAN_WIDTH-1):0]     initial_value;          //fixed point (GIA ESTESO con 0 come LSBs) value between 1 and 2, 8 bit
    output  logic [(OUT_WIDTH-1):0]     output_value;       
    
    logic   [(2*MAN_WIDTH-1):0]          PowM, PowM_next;       //pow 32 bit (16+16)
    logic   [(MAN_WIDTH-1):0]           man, man_next;
    logic   [(OUT_WIDTH-1):0]           out, out_next;
    logic   [($clog2(OUT_WIDTH)-1):0]           count, count_next;      //a ogni iterazione riempio un bit di out quindi count deve essere parametrizzato a OUT_WIDTH
    
    typedef enum logic [1:0]                        //stati per la FSM
    {
        IDLE    = 'd0,
        EVAL    = 'd1,
        DONE    = 'd2
    }   ss_mul_div;
    
        ss_mul_div    ss, ss_next;
    
    always@(posedge clk)                            //SEQUENZIALE
    begin
        if(rst)
        begin
            ss              <=  IDLE;
            count           <= (OUT_WIDTH-1);                 //parte da (OUT_WIDTH-1) perche la prima comparazione mi da il msb della parte frazionaria 0.b7b6b5b4...
            man             <= '0;
            PowM            <= '0;
            out             <= '0;
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
    
    
    always_comb                                 //COMBINATORIA
    begin
        ss_next     =   ss;
        count_next  =   count;
        man_next    =   man;
        PowM_next   =   PowM;
        out_next    =   out;
        
        case(ss)
            IDLE:
            begin
                ss_next         = EVAL;
                count_next      = (OUT_WIDTH-1);          
                man_next        = initial_value;
                PowM_next       = initial_value*initial_value;
            end                                                             //end IDLE
            EVAL:
            begin

                if(PowM[(2*MAN_WIDTH-1)])
                begin
                    out_next[count] = 1;                            //pow <=2 quindi il bit e' 1
                    man_next    =   PowM[(2*MAN_WIDTH-1):16];       //il prossimo operand e' la potenza diviso due (quindi prendo i 16 MSB di pow)     
                    PowM_next   =   PowM[(2*MAN_WIDTH-1):16]*PowM[(2*MAN_WIDTH-1):16];          //la prossima potenza e' man_next*man_next 
                end
                else
                begin
                    out_next[count] = 0;
                    man_next    =   PowM[(2*MAN_WIDTH-2):15];                           //il prossimo operand e' la potenza stessa (quindi prendo i 16 bit dopo l'MSB che sara' 0 essendo <2)
                    PowM_next   =   PowM[(2*MAN_WIDTH-2):15]*PowM[(2*MAN_WIDTH-2):15];  //la prossima potenza e' man_next * man_next
                end
                
                if(count == 0)
                begin
                    ss_next = DONE;
                end
                else
                begin
                    count_next = count - 1;
                end

            end                                                 //end EVAL

            DONE:
            begin
                //ss_next = IDLE;
                //si potrebbe aggiungere un valid in uscita che va a 1
            end                                                 //end DONE
        endcase
    end

    assign output_value = out;

endmodule
