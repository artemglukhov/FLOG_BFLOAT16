
x = [2^-7 : 2^-7 : sqrt(2)+2^-7];
%y = [2^-7 : 2^-7 : sqrt(2)/2];

x_bin = dec2bin(x * 2^7);
%y_bin = dec2bin(y * 2^7);

f_x = transpose(log(x)./(x-1));
%f_y = transpose(log(y)./(y-3));
%% sistemare  f_x NaN a manina e runnare qui
f_x_bin = dec2bin(f_x*2^9);
%f_y_bin = dec2bin(f_y*2^9);

t_in = table(x_bin);
t_f = table(f_x);
t_bin = table(f_x_bin);

%t2_in = table(y_bin);
%t2_f = table(f_y);
%t2_bin = table(f_y_bin);

Z = [t_in t_f t_bin];
%Z2 = [t2_in t2_f t2_bin]; 

%for i = 1:90                    %'b0000	:	return 'b1111;
    
 %   fprintf("8'b0%s :    return 10'b%s; \n", table2array(Z2(i,1)), table2array(Z2(i,3)));
    
%end

for i = 1:182                    %'b0000	:	return 'b1111;
    
    fprintf("8'b%s :    return 10'b%s; \n", table2array(Z(i,1)), table2array(Z(i,3)));
    
end
