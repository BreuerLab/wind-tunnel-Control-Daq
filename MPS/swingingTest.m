% For ATI-F/T Gamma IP65 in AFAM wind tunnel 
% Output the six axials force(torque)/ raw voltage measurements 
% into csv file

% Siyang Hao
% Brown,PVD
% Jan,12,2022


clear all;
%********************initialize ************************
CaseName = input('name this case \n','s');
angle = [0;0;0]; % identify the yaw pitch roll angle from the mps system, in deg
 trial = strcat(CaseName);
% load offset data 
offsetjudge = input('Do we have a taring for this case?[Y/N] \n','s');
if offsetjudge == 'Y'
% case 1: load offset data from file
offsetName = strcat('offsets_',CaseName);
offSetData = csvread(offsetName);
else
    if offsetjudge == 'N'
% case 2: start a new offset
disp('generating offset file, this will take 1 min...')
[offSetData] = offset(CaseName);
    end
end
offSets = offSetData(1,:);
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

load Gromit_Cal; % load calibration martix
matrixVals = Gromit_Cal;
timeLength = 5; % each session duration in seconds
s.Rate = 1000; % sample rate
s.DurationInSeconds = timeLength; 
%%%
%Get file info so it doesnt mess up
trial = strcat(trial,'_data');
% timefile = strcat(trial,'_time');
%*****************************preset MPS********************


pause('on');
P.ACC = 1000;   % rpm/s
P.DEC = 1000;   % rpm/s
P.V   = 100;    % rpm
Deg2Con = 29850.74;
i=1;
start_pos = input('input statr position');
end_pos = input('input end position');
step = input('input steps in deg');
SessionNumber = abs(end_pos-start_pos)/step+1;
step_counts =step* Deg2Con; % deg convert to counts
P1 = Pitch_Read;
P.P = start_pos* Deg2Con-(P1.POS+52238083)/16; % go to start pos from any initial pos
disp('move to start position, wait');
Pitch_Move(P);
pause(30);
%% Acquire Force data
t0=clock;
while  i <=SessionNumber %start scan for a period in seconds, approximately 
   
%     gogo = input('ready to collect? ','s'); 
%         disp('Read Commands')
        P1 = Pitch_Read;
        AOA = P1.POS;
              
disp('acquiring data...')
%**************************************************************************        
    [voltVals,time] = s.startForeground; % DATA ACQUIRING!! may take long time
%**************************************************************************
        P.P = step_counts;     
        disp('Load Move Commands')
        Pitch_Move(P);
        pause(10); % wait for servo
%   dlmwrite(trial,voltVals,'-append'); %directly write raw voltage data into file

% ********************live monitoring & plotting**************

% use directly write if time sensitive 
    
   %t(i)=etime(clock,t0);
    %Offset the data once finished and multiply by weights
    voltVals = voltVals(:,1:6) - ones(timeLength*s.Rate,1)*offSets; %wipe out the offset
    
    forceVals = matrixVals*voltVals';
    forceVals = forceVals';  
    %Writingfiles
    dlmwrite(trial,forceVals,'-append');
    %dlmwrite(trial,logdata,'-append');
% Plot: get one force data point averaged from each session
    avgVoltVals = mean(voltVals);
    avgForceVals = matrixVals*avgVoltVals';
    hold on;
     % transfer from loadcell CS to body CS
    theta =angle;
    dcm = angle2dcm(theta(1), theta(2), theta(3));
    F_body =dcm * avgForceVals(1:3);            
    plot(i,F_body(1),'+k');
    plot(i,F_body(2),'ob');
    plot(i,F_body(3),'*r');
    Save_avg(i,:)= [avgForceVals' AOA];
%     ylim([-2,4]);
     %xlim([0,SessionNumber+2]);
%     forceStdError = std(forceVals)/sqrt(length(forceVals))

%%
 i=i+1; 
end
info = [num2str(i),' sessions are collected with the sample rate of ', num2str(s.Rate), 'Hz'];
disp(info);
save(trial,'Save_avg');
