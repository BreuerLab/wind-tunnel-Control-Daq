Forcedata=csvread('drifttest_data');
%Forcedata=csvread('winddrift_data');
SDuration = 60;
Snumber =30;
for i = 1:Snumber
    Forceavg(i,:)= mean(Forcedata((i-1)*SDuration+1:i*SDuration,:));
    Forcestd(i,:)= std(Forcedata((i-1)*SDuration+1:i*SDuration,:));
end
figure
errorbar(Forceavg,Forcestd);
xlabel('time,min');
ylabel('force,N/Nm');
legend('x','y','z','r','p','y');