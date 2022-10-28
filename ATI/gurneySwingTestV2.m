% For ATI-F/T Delta IP65 in AFAM wind tunnel 
% Output the six axials force(torque)/ raw voltage measurements 
% into csv file

% Siyang Hao
% Brown,PVD
% V1.2 for Gurney sweep testing
% Mar,9,2022


clear all;
close all;
pitchAngle = input('input angle of attack for wing (upside down, so e.g. type -15 to go up to 15 deg aerodynamic angle');
Pitch_Home(pitchAngle);
%********************initialize ************************
CaseName = input('name this case \n','s');
angle =[-pi/4;0;0]; %identify the yaw pitch roll angle from the mps system, radians
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
offSets = offSetData(1,:); %1x6, average voltages from taring measurement
disp('turn on wind, then press any key to continue!')
pause;
%% ****************************Set Up DAQ****************************
% Create daq session, 
s = daq.createSession('ni');
addAnalogInputChannel(s,'Dev1',0,'Voltage');
addAnalogInputChannel(s,'Dev1',1,'Voltage');
addAnalogInputChannel(s,'Dev1',2,'Voltage');
addAnalogInputChannel(s,'Dev1',3,'Voltage');
addAnalogInputChannel(s,'Dev1',4,'Voltage');
addAnalogInputChannel(s,'Dev1',5,'Voltage');


load Wallance_Cal; % load calibration martix
% matrixVals = Gromit_Cal;
timeLength = 30; % each session duration in seconds
s.Rate = 1000; % sample rate
s.DurationInSeconds = timeLength; 
%%%
    
    %load limitations for SI-165-15 load cell from ATI:
 sensingLimit = [165, 165, 495, 15, 15, 15]'; %Fx, Fy, Fz, Tx, Ty, Tz [N or Nm]
 overloadLimit = [3700, 3700, 10000, 280, 280, 400]';%Fx, Fy, Fz, Tx, Ty, Tz [N or Nm]
%Get file info so it doesnt mess up
trial = strcat(trial,'_data');
%*****************************preset MPS********************


pause('on');
P.ACC = 1000;   % rpm/s
P.DEC = 1000;   % rpm/s
P.V   = 100;    % rpm
Deg2Con = 29850.74;
i=1;

start_pos = pitchAngle;
end_pos =   pitchAngle;
step = 0;

step_counts =step* Deg2Con; % deg convert to counts
P1 = Pitch_Read;
P.P = start_pos* Deg2Con-(P1.POS+52238083)/16; % go to start pos from any initial pos
disp('move to start position, wait');
Pitch_Move(P);
pause(5);
AOAdeg = -start_pos;


gurney_start_angle = input('input gurney start angle (default is 0 degrees)');
gurney_end_angle = input('input gurney end angle (default is 135 degrees)');
gurney_step = input('input gurney angle step (default is 9 degrees)');
gurney_angle = gurney_start_angle;

SessionNumber = abs(gurney_end_angle-gurney_start_angle)/gurney_step+1; %need to modify if doing multiple AOA

%% Acquire Force data
t0=clock;
while  i <=SessionNumber %start scan for a period in seconds, approximately 
   
    
    
    disp('make sure gurney angle is at ' + string(gurney_angle) + 'deg (' + string(gurney_angle/1.8) + ' on Pololu) , then press any key to continue!')
    pause;

        P1 = Pitch_Read;
        AOA = P1.POS;
              
disp('acquiring data...')
%**************************************************************************        
    [voltVals,time] = s.startForeground; % DATA ACQUIRING!! may take long time
%**************************************************************************

%   dlmwrite(trial,voltVals,'-append'); %directly write raw voltage data into file

% ********************live monitoring & plotting**************

% use directly write if time sensitive 
    voltValsRaw = voltVals(:,1:6);  %untared
    stdVoltValsRaw = std(voltVals); %standard deviation
    avgVoltValsRaw = mean(voltVals); %untared
    avgForceValsRaw = matrixVals*avgVoltValsRaw'; %untared
    
    %Offset the data once finished and multiply by weights
    voltVals = voltVals(:,1:6) - ones(timeLength*s.Rate,1)*offSets; %wipe out the offset

    forceVals = matrixVals*voltVals';
    forceVals = forceVals';  
    %Writingfiles
    dlmwrite(trial,forceVals,'-append');
    matForce(:,:,i) = [forceVals time];

% Plot: get one force data point averaged from each session
    avgVoltVals = mean(voltVals);
    avgForceVals = matrixVals*avgVoltVals';
    hold on;
    
    
    %Printing force values in load cell coordinates, warning if nearing
    %limits: 
    
    percentageOfSensingLimit = avgForceValsRaw./sensingLimit*100;
    percentageOfOverloadLimit = avgForceValsRaw./overloadLimit*100;
    
    disp('Force values measured (tared) (Fx, Fy, Fz, Tx, Ty, Tz) [N or Nm]:')
    disp(avgForceVals')
    
    disp('Raw Force values measured (untared (Fx, Fy, Fz, Tx, Ty, Tz) [N or Nm]:')
    disp(avgForceValsRaw')
    
    disp('Percentage of sensing range limit:')
    disp(percentageOfSensingLimit')
    
    disp('Percentage of overload limit:')
    disp(percentageOfOverloadLimit')
    
    if max(percentageOfSensingLimit) > 80
        disp('warning, nearing sensing range limit')
    end
    
    if max(percentageOfOverloadLimit) > 60
        disp('WARNING, nearing overload limit (load cell failure)')
    end
    
    
     % transfer from loadcell CS to body CS
    theta =angle;
    dcm = angle2dcm(theta(1), theta(2), theta(3));
    F_body =dcm * avgForceVals(1:3);            
    plot(AOAdeg,F_body(1),'+k');
    plot(AOAdeg,F_body(2),'ob');
    plot(AOAdeg,F_body(3),'*r');
    xlabel('AOA [deg]')
    ylabel('Forces [N] (body coordinates)')
    legend('Fx','Fy','Fz')
    Save_avg(i,:)= [avgForceVals' AOA gurney_angle];
    Save_raw(i,:)= [avgVoltVals stdVoltValsRaw AOA AOAdeg gurney_angle]; %avg voltages, standard deviations, and angles of attack
     
   %updating gurney angle
   gurney_angle = gurney_angle + gurney_step;

%%
 i=i+1; 
end
info = [num2str(i),' sessions are collected with the sample rate of ', num2str(s.Rate), 'Hz'];
disp(info);
save(trial);
