function [offsets] = offset(CaseName)
%Create daq session, 
s = daq('ni');
addinput(s,'cDAQ1Mod1',0,'Voltage');
addinput(s,'cDAQ1Mod1',1,'Voltage');
addinput(s,'cDAQ1Mod1',2,'Voltage');
addinput(s,'cDAQ1Mod1',3,'Voltage');
addinput(s,'cDAQ1Mod1',4,'Voltage');
addinput(s,'cDAQ1Mod1',5,'Voltage');

%Get offsets for current trial
%Select rate and duration for bias averaging
s.Rate = 1000;
s.DurationInSeconds = 10;
[bias,~] = s.startForeground;
for i = 1:6
    offsets(1,i) = mean(bias(:,i));
    offsets(2,i) = std(bias(:,i))/sqrt(60*1000);    
end

%Write offsets to file,
% CaseName = erase(date,'-'); name the case by time stamp
trial = strcat('offsets_',CaseName);
csvwrite(trial,offsets);

end






