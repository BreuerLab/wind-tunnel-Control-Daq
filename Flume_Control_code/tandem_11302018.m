% 
U_inf = 0.4;
c = 0.0762;

theta = 65;
H0 = 1;

rfreq = 0.18;%0.02:0.01:0.17;
freq = rfreq*U_inf/c;
phase12 = -50;

num_of_cycle = 15;

for i = 1:numel(freq)
    f = freq(i)
    [flume,out,dat,Prof2,Prof_out] = run_cycle_3rigs_20181130(f,0,0,theta,H0,theta,H0,phase12,0,num_of_cycle,90);
    save(sprintf('1130_rfreq%2.2f_H01_P65_U04_c3in_Sx6c.mat',rfreq(i)));
    pause(5);
end