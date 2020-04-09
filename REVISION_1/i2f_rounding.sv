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
    logic        [6   : 0]              i, i_next;
    logic        [3   : 0]              j, j_next;
    logic                               sgn, sgn_next;

    logic       [FRACT_WIDTH-1 : 0]    fract_temp, fract_temp_next;    

    typedef enum logic [1:0]                
    { 
        IDLE        = 2'b00, 
        WORK        = 2'b01, 
        EXP_CALC    = 2'b10, 
        FRACT_CALC  = 2'b11
    }ss_I2F;

    ss_I2F    ss, ss_next;

    always@(posedge clk, posedge rst)
        begin

            if (rst)
            begin
                i           <= (DIM-1)-1;               
                ss          <= IDLE;     
                num_finale  <= '0;
                sgn         <= 0;
                j           <= FRACT_WIDTH+1;           //this is the LSB position of fractional part in the num_finale vector 
                fract_o     <= '0;
                exp_o       <= '0;
                valid_i2f_o <=  0;
                fract_temp  <= '0;                
            end
            else
            begin
                sgn         <= sgn_next;
                i           <= i_next;
                j           <= j_next;
                ss          <= ss_next;
                num_finale  <= num_finale_next;
                fract_temp  <= fract_temp_next;
            end
        end

    always_comb                 
        begin

            j_next          = j;
            i_next          = i;
            ss_next         = ss;
            num_finale_next = num_finale;
            sgn_next        = sgn;
            fract_temp_next = fract_temp;
            
            case(ss)
                IDLE: 
                begin
                    valid_i2f_o = 0;
                    if (valid_i2f_i)
                    begin
                        i_next = DIM-1;                                 
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
                    if (num_finale[i] || i <= (EXP_WIDTH-1))              //warning! it was just '<' but in the case of log(1) it went out of range
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
                    exp_o   = i - COMMA_POS + BIAS; //- bias
                    sgn_o   = sgn;
                    ss_next = FRACT_CALC; 
                end                      
                FRACT_CALC: 
                begin
                    if(j >= 1)
                    begin
                        fract_temp_next[j-1]    = num_finale[i-1-7 +j];       
                        j_next                  = j-1;
                    end
                    else
                    begin 
                        if(num_finale[i-1-7])       //Rounding: add 1 to fract if the first discarded bit is 1. If &(fract_temp) = 1, add 1 to exp                      
                        begin     
                                fract_o     = fract_temp + 1;                      
                                if(&(fract_temp))
                                    exp_o   = i - COMMA_POS + BIAS + 1;
                        end
                        else                                                
                                fract_o = fract_temp;     
                        j_next  = 8;
                        ss_next = IDLE;
                        valid_i2f_o = 1;                 
                    end
                end    
            endcase        
        end
    endmodule