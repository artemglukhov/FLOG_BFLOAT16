
x = [sqrt(2)/2 : 2^-7 : sqrt(2)+2^-7];

x_bin = dec2bin(x * 2^7);

f_x = transpose(log(x)./(x-1));

f_x_bin = dec2bin(f_x*2^9);

t_in = table(x_bin);
t_f = table(f_x);
t_bin = table(f_x_bin);

Z = [t_in t_f t_bin];

for i = 1:92                    %'b0000	:	return 'b1111;
    
    fprintf("8'b%s :    return 10'b%s; \n", table2array(Z(i,1)), table2array(Z(i,3)));
    
end