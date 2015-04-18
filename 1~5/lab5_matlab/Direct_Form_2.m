clear all;
close all;
f=[280,470];
N=2;
Rp=0.5;
Rs=25;
fs=8000;
Wp=f/(fs/2);
[b,a] = ellip(N,Rp,Rs,Wp);
freqz(b,a,1024,8000);

[H1,W2]=freqz(b,a,1024,8000);%f and phase response
grid on;
H=tf(b,a,1/fs);
figure;
pzmap(H);%plot pole and zero map of filter
grid on;

%output filter coefficients
fileID = fopen('coefs.txt','w');
fprintf(fileID,'double b[]={');
for i = 1:length(b) 
    fprintf(fileID,'%f,',b(1,i));
end
fprintf(fileID,'};\n');

fprintf(fileID,'double a[]={');
for i = 1:length(a)
    fprintf(fileID,'%f,',a(1,i));
end
fprintf(fileID,'};\n');
fclose(fileID);

H2=20*log10(abs(H1));
P1=angle(H1);
P2=P1/(2*pi)*360;
figure;
plot(W1,P2);
grid on;
