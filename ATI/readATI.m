function [matVals] = readATI(timeLength,sample_rate, SessionNumber)
% read 6 channel ATI load cell voltage
%
if nargin<3
    SessionNumber =1;
    if nargin<2
      sample_rate = 1000;
      if nargin<1
         timeLength = 10; % each session duration in seconds
      end
    end
end
%% ****************************Set Up DAQ****************************
% Create daq session, 
s = daq.createSession('ni');
addAnalogInputChannel(s,'Dev1',0,'Voltage');
addAnalogInputChannel(s,'Dev1',1,'Voltage');
addAnalogInputChannel(s,'Dev1',2,'Voltage');
addAnalogInputChannel(s,'Dev1',3,'Voltage');
addAnalogInputChannel(s,'Dev1',4,'Voltage');
addAnalogInputChannel(s,'Dev1',5,'Voltage');
% addAnalogInputChannel(s,'Dev1',6,'Voltage');
% addTriggerConnection(s,'Dev1/PFI0','startTrigger');


s.Rate = sample_rate; % sample rate
s.DurationInSeconds = timeLength; 
% timefile = strcat(trial,'_time');
%*****************************Read in measurment values********************
i=0;

    while  i <SessionNumber %start scan for a period in seconds, approximately 
           i=i+1;
           [voltVals,time] = s.startForeground; % get the six axis output of loadcell
            %   dlmwrite(trial,voltVals,'-append'); %directly write raw voltage data into file
           matVals(:,:,i) = [voltVals time];
    end
end    
    

