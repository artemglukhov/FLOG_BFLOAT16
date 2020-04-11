`timescale 1ns / 1ps

module tb_scd();

    parameter S_WIDTH           = 1;                                        //sign width
    parameter FRACT_WIDTH       = 7;                                      //nominal width of the mantissa
    parameter EXP_WIDTH         = 8;

    parameter DELAY             = 10;

    logic s_op_i;
    logic [EXP_WIDTH-1:0]   exp_op_i;
    logic [FRACT_WIDTH-1:0]  fract_op_i;
    logic isInf_o, isPosInf_o, isNegInf_o, isNaN_o, isQNaN_o, isSNaN_o, isZero_o, isPosZero_o, isNegZero_o, isOpValid_o;
    
    
    
    special_case_detector
        my_scd(
            .s_op_i(s_op_i),
            .exp_op_i(exp_op_i),
            .fract_op_i(fract_op_i),
            .isInf_o(isInf_o),
            .isPosInf_o(isPosInf_o),
            .isNegInf_o(isNegInf_o),
            .isNaN_o(isNaN_o),
            .isQNaN_o(isQNaN_o),
            .isSNaN_o(isSNaN_o),
            .isZero_o(isZero_o),
            .isPosZero_o(isPosZero_o),
            .isNegZero_o(isNegZero_o),
            .isOpValid_o(isOpValid_o)
        );
        
      initial
      begin
      
          s_op_i          = 1'bx;
          exp_op_i        = 'x;
          fract_op_i      = 'x;
//          isInf_o         = 0; 
//          isPosInf_o      = 0;
//          isNegInf_o      = 0;
//          isNaN_o         = 0;
//          isQNaN_o        = 0;
//          isSNaN_o        = 0;
//          isZero_o        = 0;
//          isPosZero_o     = 0;
//          isNegZero_o     = 0;
          
        #(DELAY);
        //valid data
        s_op_i = 0;
        exp_op_i = 8'b1001_1111;
        fract_op_i = 7'b1111_000;
        
        #(DELAY);
        //+inf 0_11111111_0000000
        s_op_i = 0;
        exp_op_i = 8'b1111_1111;
        fract_op_i = 7'b0000_000;

        #(DELAY);

        //-inf 1_11111111_0000000
        s_op_i = 1;
        exp_op_i = 8'b1111_1111;
        fract_op_i = 7'b0000_000;

        #(DELAY);

        //+0   0_00000000_0000000
        s_op_i = 0;
        exp_op_i = 8'b0000_0000;
        fract_op_i = 7'b0000_000;

        #(DELAY);

        //-0   1_00000000_0000000
        s_op_i = 1;
        exp_op_i = 8'b0000_0000;
        fract_op_i = 7'b_0000_0000;

        #(DELAY);

        //SNaN X_11111111_0111111
        s_op_i = 1;   //potrebbe anche essere 0
        exp_op_i = 8'b1111_1111;
        fract_op_i = 7'b0111_111;

        #(DELAY);

        //QNaN X_11111111_1000000
        s_op_i = 1;   //potrebbe anche essere 0
        exp_op_i = 8'b1111_1111;
        fract_op_i = 7'b1000_000;

        #(DELAY);
        
        $finish;

      end
endmodule
