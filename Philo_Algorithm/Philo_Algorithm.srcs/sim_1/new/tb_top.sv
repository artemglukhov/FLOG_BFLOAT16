`timescale 1ns / 1ps


module tb_top;

    parameter HALF_CLK_PERIOD_NS=20;
    parameter WAIT_CYCLE = 20;
    
    parameter               MAN_WIDTH = 16;
    parameter               OUT_WIDTH = 12;

    logic           clk;
    logic           rst;
    logic [(MAN_WIDTH-1):0]     initial_value;
    logic [( OUT_WIDTH-1):0]     output_value;


    always #HALF_CLK_PERIOD_NS clk = ~clk;



    top
        top(
            .clk            (clk),
            .rst            (rst),
            .initial_value  (initial_value),
            .output_value   (output_value)
        );

    initial
    begin
        clk <= 1;
        rst  = 1;
        initial_value = 16'b1111_1010_0000_0000;    //1,953125(in base dieci) -> log2(1,953125) = 0.9657842847 (con la calcolatrice)
        repeat(3) @(posedge clk);
        rst  = 0;
        
        repeat(WAIT_CYCLE) @(posedge(clk));
        
        $finish;
  
    end
endmodule
