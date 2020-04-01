%input:       0, 11110111, 0101011
%output_RTL:  0, 10000101, 1110000

C=readtable('/Users/glukosio/Documents/FLOG_BFLOAT16/First_Complete_Test/result.csv', 'format', '%s %s %s');
matrix=table2array(C);
[x,y]=size(matrix);
log_input=zeros(1000,1);
output_RTL=zeros(1000,1);

for i = 1 : x
    if mod(i,2) == 1
        input1= (-1)^(bin2dec(matrix(i,1)))*2^(bin2dec(matrix(i,2))-127)*(1+bin2dec(matrix(i,3))*2^(-7));
        log_input(i) = log2(input1);
    else
        output_RTL(i-1)=(-1)^(bin2dec(matrix(i,1)))*2^(bin2dec(matrix(i,2))-127)*(1+bin2dec(matrix(i,3))*2^(-7));
    end
end