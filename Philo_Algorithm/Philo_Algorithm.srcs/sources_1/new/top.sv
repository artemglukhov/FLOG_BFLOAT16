`timescale 1ns / 1ps

module top(
    clk,
    rst,
    // inputs
    initial_value,
    //outputs
    output_value   
    );
    
    parameter               comp = 16'b1000_0000_0000_0000;
    
    input                   clk;
    input                   rst;
    input   logic [7:0]     initial_value;          //fixed point value between 1 and 2, 8 bit
    output  logic [7:0]     output_value;       
    
    logic   [15:0]          PowM, PowM_next;
    logic   [7:0]           man, man_next;
    logic   [2:0]           count, count_next;
    logic   [7:0]           out, out_next;
    
    typedef enum logic [1:0]
    {
        IDLE    = 'd0,
        EVAL    = 'd1,
        DONE    = 'd2
    }   ss_mul_div;
    
        ss_mul_div    ss, ss_next;
    
    always@(posedge clk)
    begin
        if(rst)
        begin
            ss              <=  IDLE;
            count           <= 'd7;                 //parte da 7 perchè la prima comparazione mi dà il msb della parte frazionaria 0.b7b6b5b4...
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
    
    
    always_comb
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
                count_next      = 'd7;          
                man_next        = initial_value;
                PowM_next       = initial_value*initial_value;
            end                                                             //end IDLE
            EVAL:
            begin
            
                if(PowM < comp)
                begin
                    out_next[count] = 0;
                end
                else
                begin
                    out_next[count] = 1;
                end
   
                if(PowM[15])
                begin
                    out_next[count] = 1;
                    man_next    =   PowM[15:8];
                    PowM_next   =   PowM[15:8]*PowM[15:8]; 
                end
                else
                begin
                    out_next[count] = 0;
                    man_next    =   PowM[14:7];
                    PowM_next   =   PowM[14:7]*PowM[14:7];
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
