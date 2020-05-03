%Questo script funziona per file .txt in cui abbiamo 
%INPUT        (bfloat-16 [s,exp,fract])
%OUTPUT_RTL   (bfloat-16 [s,exp,fract])
%In particolare riempie l'array log_input con i log2 degli input, calcolati
%da MatLab (e quindi il valore di riferimento che vorremmo raggiungere) e
%invece l'array output_RTL con la conversione dell'uscita del nostro RTL
%(ovvero il risultato del nostro log2).
%Successivamente lo script calcola in un array l'errore per ogni coppia e
%infine esegue diverse operazioni sui dati ottenuti e plotta alcuni grafici

close all;

[file_name] = uigetfile('*.txt');                   %apre finestra da cui puoi scegliere il file

inf_p = 3.402823669209385e+38;                      %+inf in bfloat16 convertito in dec
inf_n = -3.402823669209385e+38;                     %-inf in bfloat16 convertito in dec
zero_p = 5.877471754111438e-39;                     %0+ in bfloat16 convertito in dec
QNaN   = 5.104235503814077e+38;                     %QNaN in bfloat16 convertito in dec
SNaN   = 5.077650943898379e+38;                     %SNaN in bfloat16 convertito in dec

C=readtable(file_name, 'format', '%s %s %s');
matrix=table2array(C);
[x,y]=size(matrix);
input1=zeros(x,1);
log_input=zeros(x,1);
output_RTL=zeros(x,1);
diff=zeros(x/2,2);
j=1;
for i = 1 :2: x                              %CIOMA si può trovare un modo per riempire anche log_input e output_RTL senza zeri tra un numero e l'altro? pensiamoci 
    input1(i)= (-1)^(bin2dec(matrix(i,1)))*2^(bin2dec(matrix(i,2))-127)*(1+bin2dec(matrix(i,3))*2^(-7));
    if(input1(i) == inf_p)
        log_input(i) = inf_p;
    elseif(input1(i) <= 1.170902576014388e-38)
        log_input(i) = inf_n;
    elseif(input1(i) < 0)
        log_input(i) = QNaN;
    elseif(input1(i) == zero_p)
        log_input(i) = inf_n;
    elseif(input1(i) == QNaN)
        log_input(i) = QNaN;
    elseif(input1(i) == SNaN)
        log_input(i) = QNaN;
    elseif(input1(i) > inf_p)   % for cases that are generic NaNs
        log_input(i) = QNaN;
    else
        log_input(i) = log(input1(i));
    end
    output_RTL(i)=(-1)^(bin2dec(matrix(i+1,1)))*2^(bin2dec(matrix(i+1,2))-127)*(1+bin2dec(matrix(i+1,3))*2^(-7));
    
    %if abs(log_input(i) - output_RTL(i))<1
        diff(j,1)=log_input(i);
        diff(j,2)=log_input(i) - output_RTL(i);
        j=j+1;
    %end
end


%% ------ EVALUATION DATA OF INTEREST -----%
avg_error      = mean(diff(:,2));                           %errore medio
std_dev        = var(diff(:,2));                            %deviazione standard
for i = 1 : size(diff,1)
    if diff(i,1)==0
        perc_error(i)=0;
    else
        perc_error(i)     = abs((diff(i,2)./diff(i,1))*100);                %errore percentuale
    end
end

avg_perc_error = mean(perc_error(:));                  %errore percentuale medio HO FERMATO L'ARRAY PERC_ERROR A 1492 PERCHE GLI ULTIMI SONO NAN, IN QUANTO GLI ULTIMI DIFF SONO 0
                                    %questo 1492 dipende da caso a caso,
                                    %bisogna escludere gli ultimi elementi
                                    %della matrice che sono 0


%------- PLOTS -------%
histogram(diff(:,2), 100);                                      %plotta un istogramma degli errori con 100 bins
txt_std_dev = sprintf('std dev=%f', std_dev);
text(0.2, 30, txt_std_dev);
figure;

stem(diff(:,1),diff(:,2));                                      %asse X: log_input    asse Y: errore
txt_avg_error = sprintf('avg error=%f', avg_error);
text(30,-0.3, txt_avg_error);
axis([-150 150 -0.6 0.6]);
figure;

stem(diff(:,1), perc_error);                                    %asse X: log_input    asse Y: errore percentuale
txt_perc_error = sprintf('avg perc error=%f', avg_perc_error);
text(50,0.9, txt_perc_error);
axis([-150 150 0 1]);

grid on;
