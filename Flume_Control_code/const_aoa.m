function [t,h1] = single_cycle_aoa(redfreq,aoa,U)
% takes in reduced frequency, freestream velocity, and desired aoa, outputs
% single cycle of pitch and heave (degrees and meters)
global chord 
rate = 100;
n = 1/rate;
c = chord;%m
h0 = 1*c;
redfreq = 0.15;
St = redfreq*2*h0/c;
% U = 0.5; %m/s
f = redfreq*U/c;
x = 0:n:1/f;
omega = 2*pi*f;
t0 = 60:1:90;
t0 = t0*pi/180;
a0 = aoa*pi/180;
a = a0*sin(omega*x);
for ii = 1:numel(t0)

t = t0(ii)*sin(omega*x);


%St = f A /U = f (2ho)/U

%0.2 = 1.5*f c/U;

%h omega/U = int_0^s tan(t(s)-a(s)) ds
h = c/(2*pi*redfreq)*cumtrapz(omega*x,tan(t-a));

hm(ii,1) = max(h)-min(h);



end


h1 = h-mean(h);
% plot(x,(h-mean(h))./cos(omega*x))
t0 = t0*180/pi;
% disp([t0' hm/2])
% hdot = diff([h1(1) h1])/n;
% 
% % ap = t
% plot(x,t,x,a,x,h1,x,hdot)
% ylim([-1 1]*2)


afit = polyfit(hm,t0',2);
t1 = afit(1)*(h0*2)^2+afit(2)*(h0*2)+afit(3);
plot(t0',hm,afit(1)*hm.^2+afit(2)*hm+afit(3),hm)

%check
t = t1*pi/180*sin(omega*x);
h = c/(2*pi*redfreq)*cumtrapz(omega*x,tan(t-a));
h1 = h-mean(h);
hdot = diff([h1(1) h1])/n;
% acheck = t - atan(hdot/U);
% plot(x,a*180/pi,x,acheck*180/pi)
% plot(x,a,x,h1,'--',x,hdot,'.-',x,acheck,'k')
end
