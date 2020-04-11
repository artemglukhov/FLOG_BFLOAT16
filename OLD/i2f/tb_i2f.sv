`timescale 1ns / 1ps

module tb_i2f;

    parameter   HALF_CLK_PERIOD_NS=20;
    parameter   WAIT_CYCLE = 20;
    parameter   MAN_WIDTH         = 7; 
    parameter   EXP_WIDTH         = 8;

    logic                       clk;
    logic                       rst; 
    logic                       valid_i;
    logic   [EXP_WIDTH-1 : 0]   parte_intera;
    logic   [MAN_WIDTH-1 : 0]   parte_frazionaria;
    logic   [MAN_WIDTH-1 : 0]   mantissa_o;
    logic   [EXP_WIDTH-1 : 0]   exp_o;
    logic                       sgn_o;
    logic                       valid_o; 

    always #HALF_CLK_PERIOD_NS clk = ~clk;

    i2f
        i2f0(
            .clk                     (clk),
            .rst                     (rst),
            .valid_i                 (valid_i),
            .parte_intera            (parte_intera),
            .parte_frazionaria       (parte_frazionaria),
            .mantissa_o              (mantissa_o),
            .exp_o                   (exp_o),
            .sgn_o                   (sgn_o),
            .valid_o                 (valid_o)

        );

    initial
    begin
        clk <= 1;
        rst  = 1;
        valid_i = 0;

        // --------------------- OK SIA EXP SIA MANTISSA ---------------
        //parte_intera      = 8'b0000_0001;               //1 signed
        //parte_frazionaria = 7'b101_1111;                //0.7421875
        //---------------------------------------------------------------

        // --------------------- OK SIA EXP SIA MANTISSA -----------
        //parte_intera      = 8'b1111_1110;               //-2 signed
        //parte_frazionaria = 7'b101_1111;                //0.7421875
        //---------------------------------------------------------------

        // --------------------- OK SIA EXP SIA MANTISSA, BRUTTA PRECISIONE: COLPA BF16 ---------------
       // parte_intera      = 8'b0111_1111;               //127 signed
       // parte_frazionaria = 7'b101_1111;                //0.7421875
        //---------------------------------------------------------------

        // --------------------- OK SIA EXP SIA MANTISSA ---------------
        //parte_intera      = 8'b1000_0001;               //-127 signed
         //parte_frazionaria = 7'b101_1111;                //0.7421875
        //---------------------------------------------------------------

        // --------------------- OK SIA EXP SIA MANTISSA ---------------
        //parte_intera      = 8'b0000_0010;               //2 signed
        //parte_frazionaria = 7'b101_1111;                //0.7421875
        //---------------------------------------------------------------

        // --------------------- OK SIA EXP SIA MANTISSA ---------------
        parte_intera      = 8'b0000_0000;               //2 signed
        parte_frazionaria = 7'b000_0001;                //0.7421875
        //---------------------------------------------------------------

        repeat(2) @(posedge clk);
        rst      <= 0;

        @(posedge clk);
        valid_i <= 1;

        repeat(2) @(posedge clk);
        valid_i <= 0;

        wait(valid_o);

        repeat(2) @(posedge clk);
        
        $finish;
  
    end
endmodule