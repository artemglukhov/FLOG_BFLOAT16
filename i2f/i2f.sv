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


module i2f(clk, rst, valid_i, parte_intera, parte_frazionaria, mantissa_o, exp_o, sgn_o, valid_o);

parameter   DIM               = 21; 
parameter   COMMA_POSITION    = 14;          // posizione subito a sinistra della virgola
parameter   MAN_WIDTH         = 7; 
parameter   EXP_WIDTH         = 8;

input                           clk;
input                           rst;
input                           valid_i;
input  logic  [EXP_WIDTH-1 : 0] parte_intera;
input  logic  [MAN_WIDTH-1 : 0] parte_frazionaria;

output logic [MAN_WIDTH-1 : 0]  mantissa_o;
output logic [EXP_WIDTH-1 : 0]  exp_o;
output logic                    sgn_o; 
output logic                    valid_o;

logic        [DIM : 0]          num_finale, num_finale_next;
logic        [6   : 0]          i, i_next;
logic        [3   : 0]          j, j_next;
logic        [3   : 0]          ss, ss_next;
logic                           sgn, sgn_next;

localparam IDLE = 2'b00, WORK =2'b01, EXP_CALC = 2'b10, MANT_CALC = 2'b11;

always@(posedge clk, posedge rst)
    begin

        if (rst)
        begin
            i           <= DIM-1;
            ss          <= IDLE;     
            num_finale  <= '0;
            sgn         <= 0;
            j           <= MAN_WIDTH+1;           //sarebbe la posizione del LSB della mantissa nel vettore num_finale
        end
        else
        begin
            sgn         <= sgn_next;
            i           <= i_next;
            j           <= j_next;
            ss          <= ss_next;
            num_finale  <= num_finale_next;
        end
    end

always_comb
    begin

    	j_next          = j;
    	i_next          = i;
        ss_next         = ss;
        num_finale_next = num_finale;
        sgn_next        = sgn;
        
        case(ss)
            IDLE: 
            begin
                valid_o = 0;
                if (valid_i)
                begin
                    i_next = DIM;            
                    if (~parte_intera[7])
                    begin
                            sgn_next        = 0;
                            num_finale_next = {parte_intera,parte_frazionaria[6:0], 7'b0000000};
                    end
                    else
                    begin
                        sgn_next = 1;                          
                        // complemento per avere il numero positivo, pero' cambiando segno
                        num_finale_next = {~parte_intera+1,parte_frazionaria[6:0], 7'b0000000};
                    end
                    ss_next = WORK;           
                end
            end
            WORK: 
            begin
                // scorro il vettore concatenato fino a che non trovo un 1, 
                //non devo prendere gli ultimi 6 bit lsb che li ho messi apposta a 0
                if (num_finale[i] || i < 7)    
                begin
                    ss_next = EXP_CALC;
                end
                else
                begin
                    i_next  = i-1;        
                end                        
            end
            EXP_CALC: 
            begin
                exp_o   = i - COMMA_POSITION + 127; //- polarizzazione 
                sgn_o   = sgn;
                ss_next = MANT_CALC; 
            end                      
            MANT_CALC: 
            begin
                if(j >= 1)
                begin
                    mantissa_o[j-1] = num_finale[i-1-7 +j];     
                    j_next          = j-1;
                end
                else
                begin
                    j_next  = 8;
                    ss_next = IDLE;
                    valid_o = 1;                 
                end
            end    
        endcase        
    end
endmodule