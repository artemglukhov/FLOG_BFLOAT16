module i2f(
    clk, 
    rst,
    
    //inputs
    
    valid_i2f_i,
    integer_i,
    log_f_i,
    
    //outputs
    fract_o,
    exp_o,
    sgn_o,
    valid_i2f_o
    );

    import flog_pkg::*;

    input                               clk;
    input                               rst;
    input                               valid_i2f_i;
    input  logic [EXP_WIDTH-1 : 0]      integer_i;
    input  logic [FRACT_WIDTH-1 : 0]    log_f_i;                    

    output logic [FRACT_WIDTH-1 : 0]    fract_o;
    output logic [EXP_WIDTH-1 : 0]      exp_o;
    output logic                        sgn_o; 
    output logic                        valid_i2f_o;

    logic        [DIM-1 : 0]            num_finale, num_finale_next;  
    logic                               sgn, sgn_next;


    typedef enum logic                
    { 
        IDLE        = 1'b0, 
        WORK        = 1'b1
    }ss_I2F;

    ss_I2F    ss, ss_next;

    always@(posedge clk, posedge rst)
        begin

            if (rst)
            begin            
                ss          <= IDLE;     
                num_finale  <= '0;
                sgn         <= 0;
                fract_o     <= '0;
                exp_o       <= '0;
                valid_i2f_o <=  0;          
            end
            else
            begin
                sgn         <= sgn_next;
                ss          <= ss_next;
                num_finale  <= num_finale_next;
            end
        end

    always_comb                 
        begin

            ss_next         = ss;
            num_finale_next = num_finale;
            sgn_next        = sgn;
            
            case(ss)
                IDLE: 
                begin
                    valid_i2f_o = 0;
                    if (valid_i2f_i)
                    begin                                 
                        if (~integer_i[EXP_WIDTH-1])
                        begin
                                sgn_next        = 0;
                                num_finale_next = {integer_i,log_f_i[6:0], 7'b0000000};
                        end
                        else
                        begin
                            sgn_next = 1;                          
                            // CPL2 of the integer part changing the sign (sgn_next)
                            num_finale_next = {~(integer_i+1)+1,~log_f_i[6:0], 7'b0000000};  
                        end
                        ss_next = WORK;           
                    end
                end
                WORK: 
                begin
                    //searching for the first 1 from the left in num_finale vector
                    //not considering the last 7 bits of 0-padding

                    casez(num_finale)
						22'b01?????????????????????: 
                        begin
                            exp_o   = 21 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[20:14];
                        end
						22'b001????????????????????: 
                        begin
                            exp_o   = 20 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[19:13];
                        end
						22'b0001???????????????????: 
                        begin
                            exp_o   = 19 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[18:12];
                        end
						22'b00001??????????????????: 
                        begin
                            exp_o   = 18 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[17:11];
                        end
						22'b000001?????????????????: 
                        begin
                            exp_o   = 17 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[16:10];
                        end
						22'b0000001????????????????: 
                        begin
                            exp_o   = 16 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[15:9];
                        end
						22'b00000001???????????????: 
                        begin
                            exp_o   = 15 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[14:8];
                        end
						22'b000000001??????????????: 
                        begin
                            exp_o   = 14 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[13:7];
                        end
						22'b0000000001?????????????: 
                        begin
                            exp_o   = 13 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[12:6];
                        end
						22'b00000000001????????????: 
                        begin
                            exp_o   = 12 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[11:5];
                        end
						22'b000000000001???????????: 
                        begin
                            exp_o   = 11 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[10:4];
                        end
						22'b0000000000001??????????: 
                        begin
                            exp_o   = 10 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[9:3];
                        end
						22'b00000000000001?????????: 
                        begin
                            exp_o   = 9 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[8:2];
                        end
						22'b000000000000001????????: 
                        begin
                            exp_o   = 8 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[7:1];
                        end
                        default: 
                        begin
                            exp_o   = 7 - COMMA_POS + BIAS; //- bias
                            fract_o = num_finale[6:0];
                        end
					endcase
                    sgn_o   = sgn;
                    ss_next = IDLE;
                    valid_i2f_o = 1;     
                end
            endcase        
        end
    endmodule