close all;
clear all;

f1=240;f2=440;f3=2000;f4=2300;% frequency boundary
f=[f1,f2,f3,f4];%make array of frequencies

rp=0.4;% ripple in dB
sa=48;% minimum stop band attenuation in dB
dev1=(10^(rp/20)-1)/(10^(rp/20)+1);%calculate pass band deviation
dev2=10^(-sa/20);%calculate stop band deviation
dev=[dev2,dev1,dev2];%make array of deviations

Fs=8000;%specify sampling rate
a=[0,1,0];%specify amplitude

[N,Fo,Ao,W] = firpmord(f,a,dev,Fs);%function to approximate filter 
coefs = firpm(N,Fo,Ao,W);%function to calculate frequency coefficients.

freqz(coefs,1,1024,8000)%Plot frequency and phase response
H = tf(coefs,1);%derive transfer function
figure;
pzmap(H);%plot pole and zero map of filter
grid on;

%The following code store filter coefficients in format readable for c.
fileID = fopen('fir_coef.txt','w');
fprintf(fileID,'double coefs[]={');
for i = 1:length(coefs) 
    fprintf(fileID,'%f,',coefs(1,i));
end
fprintf(fileID,'};\n');
fclose(fileID);

figure;
stem(coefs);
grid on;
