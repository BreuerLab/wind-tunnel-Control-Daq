k = [1.256 1.5708 2.5133];
% k = wc/u
U = 0.25;
c = 0.1;
f = k*U/(2*pi*c);
f = 0.5:0.125:1;
k = 2*pi*f*c/U
p = 10:5:60;
h = 0.5:0.5:1.5;
phase = 80:10:100;
nn = 1;
for ii = 1:numel(f)
    for jj = 1: numel(p)
        for kk = 1:numel(h)
            for mm = 1:numel(phase)
                flume = run_cycle_3rigs(f(ii),0,0,0,0,p(jj),h(kk),0,0,10,phase(mm));
                params(nn,1:9) = [f(ii) k(ii) p(jj) h(kk) phase(mm) flume.foil3.CT flume.foil3.CP flume.foil3.thrust flume.foil3.power];
                nn = nn+1;
            end
        end
    end
end
          
p2 = 30:2:50;
n = 22;
for ii = 1:numel(p2)
    flume = run_cycle_3rigs(0.625,0,0,0,0,p2(ii),1,0,0,10,90);
    eff2(ii) = flume.foil3.CT./flume.foil3.CP;
    param(n,1:5) = [1.5708 p2(ii) eff2(ii) flume.foil3.CT flume.foil3.CP];
end


params

fnames = dir('C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\4D_optimization_09-Sep-2017_9_55_32\data\flume*');

dates = struct2cell(fnames);
[~,idx] = sort(-cell2mat(dates(6,:)));
fnames = fnames(idx);

for ii = 1:33
    load(['C:\Users\ControlSystem\Documents\vertfoil\Experiments\1foil\4D_optimization_09-Sep-2017_9_55_32\data\',fnames(ii).name]);
    
    param(ii,1:6) = [flume.foil3.freq*2*pi*.472/.25 flume.foil3.pitch_amp flume.foil3.heave_amp flume.foil3.CT*.472^2./(.25^2) flume.foil3.CP*.472^3./(.25^3) flume.foil3.CT*.472^2./(.25^2)./(flume.foil3.CP*.472^3./(.25^3))];
end
p2 = 10:5:70;
for ii = 1:numel(p2)
    flume = run_cycle_3rigs(1,0,0,0,0,p2(ii),1,0,0,10,90);
    param(ii,1:6) = [flume.foil3.freq*2*pi flume.foil3.pitch_amp flume.foil3.heave_amp flume.foil3.CT flume.foil3.CP flume.foil3.CT./(flume.foil3.CP)];
end



Anderson
U = 0.5;
c = 0.1;
St = 0.3 ;%= f*2*.75*c/U
St_us = .3/1.5;% = 0.2;
h = 0.75;%c
alpha_max = 20;
phi = 73*pi/180;
f = U*St_us/c;
T = 1/f;
t = 0:.01:T;
h0 = 0.075;
h = h0*sin(2*pi*f*t);
hdot = h0*2*pi*f*cos(2*pi*f*t);
for t0 = 1:60
theta = t0*sin(2*pi*f*t+phi);
%find theta from phi = 73 and amax = 20;
a = pi*1-theta+atan(hdot/U);
amax(t0) = max(a);
end




