`timescale 1ns / 1ps


module tb_top_top;


    /*importa funzioni DPI-C*/
    //import "DPI-C" function int unsigned DPI_C_log2(int unsigned op);

    import flog_pkg::*;

    parameter HALF_CLK_PERIOD_NS = 20;
//  parameter WAIT_CYCLE        = 20;       //inutilizzato al momento


    logic                       clk;
    logic                       rst;

    logic			            sign;
    logic   [EXP_WIDTH-1:0]     exponent;
    logic	[MAN_WIDTH-1:0]		fractional;
    logic                       valid_i;

    //	outputs
    logic				    	s_res_o;
    logic	[EXP_WIDTH-1:0]		e_res_o;
    logic	[MAN_WIDTH-1:0]     f_res_o;
    logic						valid_o;



    //int fd;

    //logic	[OUT_WIDTH-1:0]	tb_res;     //for DPI-output


    always #HALF_CLK_PERIOD_NS clk = ~clk;



    top_top
        top_top(
            .clk            (clk),
            .rst            (rst),
            .sign           (sign),
            .exponent       (exponent),
            .fractional     (fractional),
            .valid_i        (valid_i),
            .s_res_o        (s_res_o),
            .e_res_o        (e_res_o),
            .f_res_o        (f_res_o),
            .valid_o        (valid_o)
        );

    initial
    begin
        clk         <= 1;
        rst          = 1;
        valid_i      = 0;

        //valid_i = 0;
        //initial_value = 16'b1000_0000_0000_0000;    
        //fd = $fopen("C:/Xilinx/ZONI_FLOG/prova_tb/results.txt", "w");
        
        //-------- TEST 1 ------------------------------
        //sign        = 0;
        //exponent    = 'd143;
        //fractional  = 7'b111_1010;    //1,953125(in base dieci) -> log2(1,953125) = 0.9657842847 (con la calcolatrice) 
        //----------------------------------------------

        //-------- TEST 2 numero decimale in ingresso = 6,85...+e30  ------------------------------
        sign        = 0;
        exponent    = 8'b1110_0101;
        fractional  = 7'b010_1101;    //1,953125(in base dieci) -> log2(1,953125) = 0.9657842847 (con la calcolatrice) 
        //----------------------------------------------   

        repeat(2) @(posedge clk);
        rst         <= 0;
        valid_i      = 1;

        wait(valid_o);

        @(posedge clk);


        repeat(2) @(posedge clk);

        
        $finish;
  
    end

endmodule
