module lampFPU_flog (
    clk,rst,
    //inputs
    doLog_i,
    s_op_i, e_op_i, f_op_i,
    isZ_op_i, isInf_op_i, isSNAN_op_i, isQNAN_op_i,

    //outputs
    s_res_o, e_res_o, f_res_o, valid_o,
    isOverflow_o, isUnderflow_o, isToRound_o
);

import lampFPU_pkg::*;

input                                       clk;
input                                       rst;
//inputs
input                                       doLog_i;
input           [LAMP_FLOAT_S_DW-1:0]       s_op_i;
input           [LAMP_FLOAT_E_DW-1:0]       e_op_i;
input           [LAMP_FLOAT_F_DW-1:0]       f_op_i;
input                                       isZ_op_i;
input                                       isInf_op_i;
input                                       isSNAN_op_i;
input                                       isQNAN_op_i;
//outputs
output logic    [LAMP_FLOAT_S_DW-1:0]       s_res_o;
output logic    [LAMP_FLOAT_E_DW-1:0]       e_res_o;
output logic    [LAMP_FLOAT_F_DW-1:0]       f_res_o;
output logic                                isOverflow_o;
output logic                                isUnderflow_o;
output logic                                isToRound_o;

//////////////////////////////////////////////////
//              internal wires                  //
//////////////////////////////////////////////////






//////////////////////////////////////////////////
//              sequential                      //
//////////////////////////////////////////////////

always@(posedge clk)
begin
    if(rst)
    begin
        s_res_o         <= '0;
        e_res_o         <= '0;
        f_res_o         <= '0;
        valid_o         <= '0;    
        isOverflow_o    <= '0;
        isUnderflow_o   <= '0;
        isToRound_o     <= '0;
    end
    else
    begin
        
    end
end


//////////////////////////////////////////////////
//          combinational logic                 //
//////////////////////////////////////////////////
always_comb
begin
    







end

endmodule
