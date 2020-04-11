`timescale 1ns / 1ps


module tb_top;

    parameter HALF_CLK_PERIOD_NS=20;

    logic           clk;
    logic           rst;
    logic [7:0]     initial_value;
    logic [7:0]     output_value;


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
        repeat(3) @(posedge clk);
        rst  = 0;
        repeat(3) @(posedge clk);
        initial_value = 8'b10101010;
        repeat(5) @(posedge clk);
        
        initial_value = 8'b00000000;
        repeat(5) @(posedge clk);
        
        initial_value = 8'b11111111;
        repeat(5) @(posedge clk);
        
        initial_value = 8'b01010101;
        repeat(5) @(posedge clk);
        
        initial_value = 8'b00000001;
        repeat(5) @(posedge clk);
        
        $finish;
    
    end


endmodule
