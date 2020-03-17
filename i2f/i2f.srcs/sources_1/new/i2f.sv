`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.03.2020 15:29:14
// Design Name: 
// Module Name: i2f
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i2f(valid_i ,parte_intera, parte_frazionaria, clk, rst, mantissa_o, exp_o, sgn_o );

parameter DIM = 20; 
// posizione subito a sinistra della virgola
parameter comma_position = 13;

input clk;
input rst;

input valid_i;
input logic [7 : 0] parte_intera;
input logic[7:0] parte_frazionaria;

output logic [6 : 0] mantissa_o;
output logic [7 : 0] exp_o;
output logic sgn_o; 


logic [20 : 0] num_finale, num_finale_next ;
logic [6:0] i, i_next;
logic [2 : 0] j, j_next;
logic [3:0]ss, ss_next;
logic sgn, sgn_next;


localparam IDLE = 2'b00, WORK =2'b01, EXP_CALC = 2'b10, MANT_CALC = 2'b11;


always@(posedge clk, posedge rst)
    begin
        if (rst)
            begin
                i <= 20;
                ss <= IDLE;     
                num_finale <= '0;
                sgn <= 0;
                j <= 7;
              
            end
        else
            begin
                sgn <= sgn_next;
                i <= i_next;
                j <= j_next;
                ss <= ss_next;
                num_finale <= num_finale_next;
            end
    end


always@(*)
    begin
    	j_next = j;
    	i_next = i;
        ss_next = ss;
        num_finale_next = num_finale;
        sgn_next = sgn;
        //exp_o = '0;
        //mantissa_o = '0;
        //sgn_o = 0;
        
        case(ss)
            IDLE : begin
                    if (valid_i)
                    begin

                       i_next = DIM;            
                       
            	       if (~parte_intera[7])
            	           begin
            	               sgn_next = 0;
                               num_finale_next = {parte_intera,parte_frazionaria[6:0], 6'b000000};
                       end
                       else
                        begin
                            sgn_next = 1;                          
                           // complemento per avere il numero positivo, però cambiando segno
                            num_finale_next = {~parte_intera+1,parte_frazionaria[6:0], 6'b000000};
                        end
                    
                        ss_next = WORK;           
                        end
                   end
        // FINO A QUA FUNZIONA TUTTO
    
            WORK : begin
// scorro il vettore concatenato fino a che non trovo un 1, non devo prendere gli ultimi 6 bit lsb che li ho messi apposta a 0
                    if (num_finale[i] || i < 6)    
                       begin
                       ss_next = EXP_CALC;
                       end
                    else
                        begin
                        i_next = i-1;
                           
                        end
         // FINO A QUA FUNZIONA TUTTO             
                                
                end
            
            EXP_CALC : begin
                      

                            exp_o = i - comma_position; //- polarizzazione 
                            sgn_o = sgn;
                            ss_next = MANT_CALC;
                            
                        end
                        
        // FINO A QUA FUNZIONA TUTTO                
                        
            MANT_CALC : begin

//devo prendere i primi 7 bit a destra della virgola, sarebbe mantissa = num_finale[i-1 : i-7], ma questa notazione non va bene                      

                        if(j >= 1)
                            begin
                                mantissa_o[j-1] = num_finale[i-1-7 +j];     
                                j_next = j-1;
                                
                            end
                        else
                            begin
                                j_next = 7;
                                ss_next = IDLE;
                                
                            end
            
                    end    
                
        endcase;        
    end
endmodule