%single pole IIR verification
clear all;
close all;
b=[1/17,1/17];
a=[1,-15/17];
freqz(b,a,987,8000)
[H1,W1]=freqz(b,a,987,8000);%Plot frequency and phase response
H = tf(b,a);%derive transfer function
figure;

zplane(b,a)
grid on;

H2=20*log10(abs(H1));
P1=angle(H1);
P2=P1/(2*pi)*360;
figure;
plot(W1,P2);
grid on;

