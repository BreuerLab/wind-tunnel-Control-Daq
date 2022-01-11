function [eff,eff_std,fs_vel,fs_std,pitch_vel,heave_vel,p_inst_power,h_inst_power,t_inst_power,eff_inst,pp_cycle,hp_cycle,tp_cycle,Yp,eta]=calc_eff_single_foil(dat,pitch_axis,span,chord,rate,freq)

%dat is of form [pitch, heave, Lift, Torque, velocity(1:4)]

% rate=1000; % sampling rate
rho=1000;
%% Find cycle locations (pks), shorten dataset

% [~,p_inds]=findpeaks(smooth(dat(:,1),40),'MINPEAKDISTANCE',250,'MINPEAKHEIGHT',0.1);
% [~,h_inds]=findpeaks(smooth(dat(:,2),40),'MINPEAKDISTANCE',250,'MINPEAKHEIGHT',0.02);
% 
% p_inds=p_inds(p_inds>100&p_inds<(length(dat(:,1))-100));
% h_inds=h_inds(h_inds>100&h_inds<(length(dat(:,2))-100));
% 
% if length(p_inds)<length(h_inds)
%     inds=p_inds;
% else
%     inds=h_inds;
% end
% 
% dat=dat(inds(2):inds(end),:);
% 
% num_cycles=length(inds)-1;

%free stream velocity
v = dat(:,5:6);
v(:,3)=(abs(dat(:,7))+abs(dat(:,8)))/2;
for ii = 1:3
%     st=std(v(:,ii));
    V(ii) = trimmean(v(:,ii),10);%2*std(v(:,ii))),ii));
    S(ii) = std(v((abs(v(:,ii)-mean(v(:,ii)))<2*std(v(:,ii))),ii));
   
end
fs_vel = sqrt(V(1)^2+V(2)^2+V(3)^2);%Velocity magnitude
fs_std=S(2);
% fs_std = sqrt(S(1)^2+S(2)^2+S(3)^2); %Velocity standard deviation
if fs_vel >0.9
    fs_vel = 1;
    fs_std = 1;
end

%% Calculate power

smooth1=1;
smooth2=1;

% dat(:,1) = smooth(dat(:,1),smooth1);
% dat(:,2) = smooth(dat(:,2),smooth1);
% dat(:,9) = smooth(dat(:,9),smooth1);
% dat(:,10) = smooth(dat(:,10),smooth1);

p_vel=diff(smooth(dat(:,1),smooth2)).*rate;
h_vel=diff(smooth(dat(:,2),smooth2)).*rate;

pitch_vel = [p_vel];
heave_vel = [h_vel];

p_for=smooth(dat(1:end-1,3),10);
h_for=smooth(dat(1:end-1,4),10);


p_inst_power=p_vel.*p_for;
h_inst_power=h_vel.*h_for;

t_inst_power = p_inst_power + h_inst_power;

p_power=trapz(p_inst_power)./length(p_inst_power);
h_power=trapz(h_inst_power)./length(h_inst_power);


t_power=p_power+h_power;

%% finding the standard deviation across the cycles
num=floor(length(p_inst_power)/(1/freq(1)*rate));
T=floor(1/freq(1)*rate);
for i=1:num
    p_a(i)=mean(p_inst_power(1+(i-1)*T:T*i));
    h_a(i)=mean(h_inst_power(1+(i-1)*T:T*i));
   
end
t_a=p_a+h_a;
p_a_std=std(p_a);
h_a_std=std(h_a);
t_a_std=std(t_a);




tp_cycle = [t_a];
pp_cycle = [p_a];
hp_cycle = [h_a];
%% Calculate Efficiency
% get max swept area
pitch_amp=smooth(dat(:,1),4);
heave_amp=smooth(dat(:,2),4);

% Maximum swept area calculation 
max_y_le=max(2.*heave_amp+2*pitch_axis*chord.*sin(pitch_amp)); 
max_y_te=max(2.*heave_amp-2*(1-pitch_axis)*chord.*sin(pitch_amp));
max_y=max([max_y_le max_y_te]);

%swept_area=span*max_y;


Yp = [max_y ]/chord;
swept_area = [max_y]*span;

% approximate version,efficiency of power extraction
w_power=0.5*rho*fs_vel^3*swept_area(1);

% power extraction ability of the foil
w_foil=0.5*rho*fs_vel^3*chord*span;

%efficiency
eff_inst = t_inst_power./w_power;

eta(:,1) = t_a/w_power;
eff=t_power/w_power;
p_eff=p_power./w_power;
h_eff=h_power./w_power;


eff_std=t_a_std/w_power;
p_eff_std=p_a_std/w_power;
h_eff_std=h_a_std/w_power;


%coefficient
coeff=t_power/w_foil;
p_coeff=p_power./w_foil;
h_coeff=h_power./w_foil;


% maxmum effective angle of attack
% [aoa_le]=eff_aoa_new(dat(:,1:2),fs_vel,rate);
% max_eaoa=max(abs(aoa_le));
% [aoa_le2]=eff_aoa_new(dat(:,9:10),fs_vel,rate);
% max_eaoa2=max(abs(aoa_le2));
max_eaoa2=0;
max_eaoa=0;
%reduced frequency
refreq=freq(1)*chord/fs_vel;

end