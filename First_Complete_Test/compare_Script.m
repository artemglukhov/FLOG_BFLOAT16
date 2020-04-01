%input:       0, 11110111, 0101011
%output_RTL:  0, 10000101, 1110000
close all;

C=readtable('/Users/glukosio/Documents/FLOG_BFLOAT16/First_Complete_Test/results2.txt', 'format', '%s %s %s');
matrix=table2array(C);
[x,y]=size(matrix);
log_input=zeros(x,1);
output_RTL=zeros(x,1);
diff=zeros(x/2,2);
j=1;
for i = 1 :2: x
    input1= (-1)^(bin2dec(matrix(i,1)))*2^(bin2dec(matrix(i,2))-127)*(1+bin2dec(matrix(i,3))*2^(-7));
    log_input(i) = log2(input1);
    output_RTL(i)=(-1)^(bin2dec(matrix(i+1,1)))*2^(bin2dec(matrix(i+1,2))-127)*(1+bin2dec(matrix(i+1,3))*2^(-7));
    
    if abs(log_input(i) - output_RTL(i))<1
        diff(j,1)=log_input(i);
        diff(j,2)=log_input(i) - output_RTL(i);
        j=j+1;
    end
end


%------- PLOTS -------%
histogram(diff(:,2), 100);
figure;
stem(diff(:,1),diff(:,2));
grid on;
