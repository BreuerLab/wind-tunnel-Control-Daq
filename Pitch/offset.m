function [offsets] = offset(case_name)
%Create daq session, 
s = daq.createSession('ni');
addAnalogInputChannel(s,'Dev1',0,'Voltage');
addAnalogInputChannel(s,'Dev1',1,'Voltage');
addAnalogInputChannel(s,'Dev1',2,'Voltage');
addAnalogInputChannel(s,'Dev1',3,'Voltage');
addAnalogInputChannel(s,'Dev1',4,'Voltage');
addAnalogInputChannel(s,'Dev1',5,'Voltage');

%Get offsets for current trial
%Select rate and duration for bias averaging
s.Rate = 1000;
s.DurationInSeconds = 5;
[bias,~] = s.startForeground;

% Preallocate an array to hold the offsets.
offsets = zeros(2, 6);

for i = 1:6
    offsets(1,i) = mean(bias(:,i));
    offsets(2,i) = std(bias(:,i))/sqrt(s.Rate*s.DurationInSeconds);    
end

%Write offsets to file,
trial = "offsets_" + case_name + ".csv";
csvwrite(trial,offsets);

end



