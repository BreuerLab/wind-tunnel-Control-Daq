function [out,t]=output_conv_3rigs(dat)
global filt_var
% Define conversions
pitch_conv=-2*pi/10000; % rad/cnt
heave_conv=-0.0254/8000; % m/cnt
% torque_conv=1/5.5980; % N-m/V
% force_conv=1/0.380424; % N/V
% save('dat1.mat','dat');
% % Unwrap:
dat(dat(:,1:6)>1e6)=dat(dat(:,1:6)>1e6)-2^32; % EXPLAIN!!!!!
% save('dat2.mat','dat');

% dat(dat(:,1)>0.5,1)=dat(dat(:,1)>0.5,1)-1;
% dat(:,1) = detrend(dat(:,1));
% dat(:,2) = detrend(dat(:,2));
% Convert Positions
% out(:,1)=(dat(:,1)-(max(dat(:,1))+min(dat(:,1)))/2).*heave_conv;
%Shawn (first)
out(:,1)=-(dat(:,1)).*pitch_conv/5;%-(max(dat(:,1))+min(dat(:,1)))/2).*pitch_conv;
out(:,2)=(dat(:,2)).*heave_conv;
%Wallace (Last)
out(:,5)=(dat(:,5)).*pitch_conv;%-(max(dat(:,3))+min(dat(:,3)))/2).*pitch_conv;
out(:,6)=-(dat(:,6)).*heave_conv;
%Gromit (Middle)
out(:,3)=-(dat(:,3)).*pitch_conv/5;%-(max(dat(:,5))+min(dat(:,5)))/2).*pitch_conv;
out(:,4)=-(dat(:,4)).*heave_conv;
% out(:,2)=(dat(:,2)).*pitch_conv;
% out(:,1) = out(:,1)+.0003258*t-.008941;
% for ii = [7:12]
% dat(:,ii) = medfilt1(dat(:,ii),10);
% end

% for ii = [17:22]
% dat(:,ii) = medfilt1(dat(:,ii),10);
% end
% Convert Forces
% out(:,7:12) = Wallace_conv(medfilt1(dat(:,7:12),10));
% out(:,17:22) = Gromit_conv(medfilt1(dat(:,17:22),10));
if filt_var
    out(:,7:12) = Wallace_conv(low_pass_filtfilt(dat(:,7:12)));
    out(:,17:22) = Gromit_conv(low_pass_filtfilt(dat(:,17:22)));
else
    out(:,7:12) = Wallace_conv(dat(:,7:12));
    out(:,17:22) = Gromit_conv(dat(:,17:22));
end

% phase = abs(asind(dat(1,9)/.05602+.05158/.05602));
% if dat(4,9)<dat(1,9)
%     phase = phase+90;
% end
% 
%     
% out(:,9) = .03*(dat(:,9));%-(-.05158));%+.05602*sin(.2704*2*pi*(0:.001:(numel(dat(:,9))-1)/1000)'+(phase)*pi/180)));
% Convert Vectrino velocity
out(:,13:16)=(dat(:,13:16)-2.5)*2/5;

out(:,23) = dat(:,23);

t = (0:numel(out(:,1))-1)/1000;
t = t';

% out(:,23)=dat(:,23);
% out(:,24)=dat(:,24);
end