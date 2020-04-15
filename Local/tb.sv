`timescale 1ns / 1ps


module tb;


    /*import DPI-C functions*/
    //import "DPI-C" function int unsigned DPI_C_log2(int unsigned sign, int unsigned exp, int unsigned frac);

    import lampFPU_pkg::*;

    parameter HALF_CLK_PERIOD_NS = 5;
//  parameter WAIT_CYCLE        = 20;       


    logic                       clk;
    logic                       rst;

    logic                                       doLog_i;
    logic           [LAMP_FLOAT_S_DW-1:0]       s_op_i;
    logic           [LAMP_FLOAT_E_DW-1:0]       e_op_i;
    logic           [LAMP_FLOAT_F_DW-1:0]       f_op_i;
    logic                                       isZ_op_i;
    logic                                       isInf_op_i;
    logic                                       isSNAN_op_i;
    logic                                       isQNAN_op_i;
    //outputs
    logic           [LAMP_FLOAT_S_DW-1:0]       s_res_o;
    logic           [LAMP_FLOAT_E_DW-1:0]       e_res_o;
    logic           [LAMP_FLOAT_F_DW-1:0]       f_res_o;
    logic                                       valid_o;
    logic                                       isOverflow_o;
    logic                                       isUnderflow_o;
    logic                                       isToRound_o;


    
    always #HALF_CLK_PERIOD_NS clk = ~clk;



    lampFPU_log
        lampFPU_log(
            .clk            (clk),
            .rst            (rst),
            .doLog_i        (doLog_i),
            .s_op_i         (s_op_i),
            .e_op_i         (e_op_i),
            .f_op_i         (f_op_i),
            .isZ_op_i       (isZ_op_i),
            .isInf_op_i     (isInf_op_i),
            .isSNAN_op_i    (isSNAN_op_i),
            .isQNAN_op_i    (isQNAN_op_i),
            .s_res_o        (s_res_o),
            .e_res_o        (e_res_o),
            .f_res_o        (f_res_o),
            .valid_o        (valid_o),
            .isOverflow_o   (isOverflow_o),
            .isUnderflow_o  (isUnderflow_o),
            .isToRound_o    (isToRound_o)
        );

    initial
    begin
        clk         <= 1;
        rst          = 1;
        doLog_i      = 0;
        
        
        repeat(2) @(posedge clk);
        rst         =  0;
        doLog_i = 1;
        @(posedge clk);
        /* ----TEST 1 ---- */
        s_op_i = 0;
        //e_op_i = 8'b10010101;   //149
        //e_op_i = 120;//8'b11111110;
        //e_op_i = 127;
        e_op_i = 126;
        f_op_i = 7'b1010101;    //85
        //f_op_i = 7'b0010101;    // 21



        wait(valid_o);

        $finish;
  
    end

endmodule