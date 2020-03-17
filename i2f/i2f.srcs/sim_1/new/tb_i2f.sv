`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.03.2020 17:17:35
// Design Name: 
// Module Name: tb_i2f
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


module tb_i2f();

parameter DIM = 20; 
// posizione subito a sinistra della virgola
parameter comma_position = 13;


logic valid_i;
logic clk;
logic rst;

logic [7 : 0] parte_intera;
logic[7:0] parte_frazionaria;

logic [6 : 0] mantissa_o;
logic [7 : 0] exp_o;
logic sgn_o; 

always #5 clk =~clk;

initial
    begin
        clk <= 0;
        rst = 1;
        valid_i = 0;
        repeat(2)
            @(posedge clk);
            
        @(posedge clk)
        begin
            rst <= 0;
            valid_i <= 1;
            parte_intera <= -13;
            parte_frazionaria <= 6;
        end
        @(posedge clk)
            valid_i <= 0;
    
        repeat(40)
            @(posedge clk);
    end













i2f #(.DIM(DIM))
    dut0(
        .clk(clk),
        .rst(rst),
        .parte_intera(parte_intera),
        .parte_frazionaria(parte_frazionaria),
        .mantissa_o(mantissa_o),
        .sgn_o(sgn_o),
        .exp_o(exp_o),
        .valid_i(valid_i)   
    );
endmodule