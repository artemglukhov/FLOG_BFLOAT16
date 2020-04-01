%Questo script funziona per file .txt in cui abbiamo 
%INPUT        (bfloat-16)
%OUTPUT_RTL   (bfloat-16)
%In particolare riempie l'array log_input con i log2 degli input, calcolati
%da MatLab (e quindi il valore di riferimento che vorremmo raggiungere) e
%invece l'array output_RTL con la conversione dell'uscita del nostro RTL
%(ovvero il risultato del nostro log2).
%Successivamente lo script calcola in un array l'errore per ogni coppia e
%infine esegue diverse operazioni sui dati ottenuti e plotta alcuni grafici

close all;

[file_name] = uigetfile('*.txt');                   %apre finestra da cui puoi scegliere il file

C=readtable(file_name, 'format', '%s %s %s');
matrix=table2array(C);
[x,y]=size(matrix);
log_input=zeros(x,1);
output_RTL=zeros(x,1);
diff=zeros(x/2,2);
j=1;
for i = 1 :2: x                              %CIOMA si pu� trovare un modo per riempire anche log_input e output_RTL senza zeri tra un numero e l'altro? pensiamoci 
    input1= (-1)^(bin2dec(matrix(i,1)))*2^(bin2dec(matrix(i,2))-127)*(1+bin2dec(matrix(i,3))*2^(-7));
    log_input(i) = log2(input1);
    output_RTL(i)=(-1)^(bin2dec(matrix(i+1,1)))*2^(bin2dec(matrix(i+1,2))-127)*(1+bin2dec(matrix(i+1,3))*2^(-7));
    
    if abs(log_input(i) - output_RTL(i))<1
        diff(j,1)=log_input(i);
        diff(j,2)=log_input(i) - output_RTL(i);
        j=j+1;
    end
end


%------ EVALUATION DATA OF INTEREST -----%
avg_error      = mean(diff(:,2));                           %errore medio
std_dev        = var(diff(:,2));                            %deviazione standard
perc_error     = (diff(:,2)./diff(:,1))*100;                %errore percentuale 
avg_perc_error = mean(perc_error(1:1492));                  %errore percentuale medio HO FERMATO L'ARRAY PERC_ERROR A 1492 PERCHE GLI ULTIMI SONO NAN, IN QUANTO GLI ULTIMI DIFF SONO 0

%------- PLOTS -------%
histogram(diff(:,2), 100);                                      %plotta un istogramma degli errori con 100 bins
figure;

stem(diff(:,1),diff(:,2));                                      %asse X: log_input    asse Y: errore
txt_avg_error = sprintf('avg error=%f', avg_error);
text(30,-0.3, txt_avg_error);
figure;

stem(diff(:,1), perc_error);                                    %asse X: log_input    asse Y: errore percentuale
txt_perc_error = sprintf('avg perc error=%f', avg_perc_error);
text(30,1.5, txt_perc_error);

grid on;