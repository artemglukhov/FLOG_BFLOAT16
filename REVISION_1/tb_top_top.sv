`timescale 1ns / 1ps


module tb_top_top;


    /*import DPI-C functions*/
    //import "DPI-C" function int unsigned DPI_C_log2(int unsigned sign, int unsigned exp, int unsigned frac);

    import flog_pkg::*;

    parameter HALF_CLK_PERIOD_NS = 20;
//  parameter WAIT_CYCLE        = 20;       


    logic                       clk;
    logic                       rst;

    logic			            sign;
    logic   [EXP_WIDTH-1:0]     exponent;
    logic	[FRACT_WIDTH-1:0]	fractional;
    logic                       valid_i;

    //	outputs
    logic				    	s_res_o;
    logic	[EXP_WIDTH-1:0]		e_res_o;
    logic	[FRACT_WIDTH-1:0]   f_res_o;
    logic						valid_o;



    int fd;                                                       //file descriptor
    logic   [EXP_WIDTH-1:0]     exp_rand;
    logic   [FRACT_WIDTH-1:0]   fract_rand;

    //logic	[31:0]	tb_res;                                       //for DPI-output


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
        fd = $fopen("C:/Xilinx/ZONI_FLOG/project_scd/results_scd.txt", "w");
        
        //-------- TEST 1 ------------------------------
        //sign        = 0;
        //exponent    = 'd143;
        //fractional  = 7'b111_1010;    //1,953125(in base dieci) -> log2(1,953125) = 0.9657842847 (con la calcolatrice) 
        //---------------------------------------------
        
        
//        TASK_doFLog(1'b1, 8'b1010_1010, 7'b1010_000);               //op <0
//        TASK_doFLog(1'b0, 8'b1111_1111, 7'b0000_000);               //op +inf
//        TASK_doFLog(1'b0, 8'b0000_0000, 7'b0000_000);               //op 0+
//        TASK_doFLog(1'b0, 8'b1111_1111, 7'b1000_000);               //op QNaN
//        TASK_doFLog(1'b0, 8'b1111_1111, 7'b0111_111);               //op SNaN
//        TASK_doFLog(1'b0, 8'b1111_1111, 7'b0001_101);               //op NaN generic
        
//        TASK_doFLog(1'b0, 8'b1111_1011, 7'b0101_011);               //op valid
        
        
        /*
        *     BRUTE FORCE APPROACH
        */
       for(int i=0;i <=255; i++)
       begin
            for(int j=0;j<=127; j++)
            begin
           //exp_rand    =    $urandom_range(0, 255);
           //fract_rand    =    $urandom_range(0,127); //(op1_exponent>=0 && op1_exponent<255) ? $random : $urandom_range(0,1)<<22 /*inf or qnan*/;
                TASK_doFLog('d0, i, j);
            end
        end
        
        
        repeat(2) @(posedge clk);
        $fclose(fd);
        
        $finish;
  
    end

    task TASK_doFLog (input logic [S_WIDTH -1 :0]  sign_task, input logic [EXP_WIDTH-1 : 0] exponent_task, input logic [FRACT_WIDTH-1 : 0] fractional_task );

        rst <= 1;
        // 0, 0x854c
        sign        = sign_task;
        exponent    = exponent_task;
        fractional  = fractional_task;    
        //----------------------------------------------   

        repeat(2) @(posedge clk);
        rst         <= 0;
        valid_i      = 1;

        wait(valid_o);

        @(posedge clk);
        
        valid_i     = 0;

        //tb_res  =   DPI_C_log2(sign_task, exponent_task, fractional_task); 
        $fdisplay(fd, "%b, %b, %b", sign, exponent, fractional);
        $fdisplay(fd, "%b, %b, %b", s_res_o, e_res_o, f_res_o);
        //$fdisplay(fd, "output_DPI:  %b, %b, %b", tb_res[31], tb_res[EXP_WIDTH-1+FRACT_WIDTH+16:FRACT_WIDTH+16], tb_res[FRACT_WIDTH-1+16:16]);
        //$fdisplay(fd, "operand: %b", operand);
        //$fdisplay(fd, "RTL-FPU: %b", output_value);
        //$fdisplay(fd, "DPI-FPU: %b", tb_res);
        $fdisplay(fd, " ");

        repeat(2) @(posedge clk);

	endtask


endmodule
