`timescale 1ns / 1ps

module top(
    clk,
    rst,
    // inputs
    initial_value,
    output_value   
    );
    
    
    input                   clk;
    input                   rst;
    input   logic [7:0]     initial_value;          //fixed point value between 1 and 2, 8 bit
    output  logic [7:0]     output_value;       
    
    logic   [15:0]          PowM;
    logic   [7:0]           out, out_next;
    
    typedef enum logic [1:0]
    {
        IDLE    = 'd0,
        EVAL    = 'd1
    }   ss_mul_div;
    
        ss_mul_div    ss, ss_next;
    
    always@(posedge clk)
    begin
        if(rst)
        begin
            ss              <=  IDLE;
            output_value    <= '0;
        end
        else
        begin
            ss              <=  ss_next;
            output_value    <=  out_next;
        end
    end
    
    
    always_comb
    begin
        ss_next     =   ss;
        PowM        =   initial_value*initial_value;
        out_next    =   out;
        
        case(ss)
            IDLE:
            begin
                ss_next =   EVAL;
            end
            EVAL:
            begin
                if(PowM[15])
                begin
                    out_next    =   PowM[15:8];
                end
                else
                begin
                    out_next    =   PowM[14:7];
                end
                ss_next =   IDLE;
            end
        endcase
    end



endmodule
