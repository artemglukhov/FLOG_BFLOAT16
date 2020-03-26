module special_case_detector (
    //inputs
    s_op_i, exp_op_i, man_op_i,
    //outputs
    isInf_o, isPosInf_o, isNegInf_o, isNaN_o, isQNaN_o, isSNaN_o, isZero_o, isPosZero_o, isNegZero_o,
    s_res_o, exp_res_o, man_res_o
);

    parameter INF				=	15'h7f80;					//Infinito nello standard IEEE754   11111111_0000000
    parameter ZERO				=	15'h0000;					//Zero nello standard IEEE754       00000000_0000000
    parameter SNAN				=	15'h7fbf;					//Signaling NaN nello standard 	    11111111_0111111
    parameter QNAN				=	15'h7fc0;					//Quiet NaN nello standard  	    11111111_1000000

    parameter PLUS_INF			=	16'h7f80;					//+inf 0_11111111_0000000
    parameter MINUS_INF			=	16'hff80;					//-inf 1_11111111_0000000
    parameter PLUS_ZERO			=	16'h0000;					//+0   0_00000000_0000000
    parameter MINUS_ZERO		=	16'h8000;					//-0   1_00000000_0000000

    /*  for future reference 
        (&exp_op_i) = 1         se tutti i bit sono 1
        ~(&exp_op_i) = 1        se almeno un bit è a 0
        (|man_op_i) = 1         se almeno un bit è a 1
        ~(|man_op_i) = 1        se tutti i bit sono a 0
    */
    isInf_o     = (&exp_op_i) & ~(|man_op_i);                   //l'operand è un inf se tutti i bit dell'exp sono uno e tutti quelli della man sono a 0
    isZero_o    = ~(|exp_op_i) & ~(|man_op_i);                  //l'op è uno zero se tutti i bit dell'exp e tutti i bit della man sono a 0     
    isNaN_o     = (&expo_op_i) & (|man_op_i);                   //l'op è un NaN se tutti i bit dell'exp sono a 1 e almeno uno della man è 1

    isPosInf_o  = ~(s_op_i) & (isInf_o);                //forse non posso leggere un uscita (isInf_o)?
    isNegInf_o  = (s_op_i) & (isInf_o;);

    isPosZero_o = ~(s_op_i) & (isZero_o);
    isNegZero_o = (s_op_i) & (isZero_o);

    /*isQNaN_o =            nel loro package ci sono delle definizioni specifiche di QNAN e SNAN che non mi tornano con lo standard 
      isSNaN_o =  
*/
endmodule