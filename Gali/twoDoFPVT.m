clc
clear
close all

%% Set up connection to motor

g = actxserver('galil');
response = g.libraryVersion;
disp(response);%display GalilTools library version
g.address = '';%Open connections dialog box
response = g.command(strcat(char(18), char(22)));%Send ^R^V to query controller model number
disp(strcat('Connected to: ', response));%print response

%||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||%
%create carraige return and linefeed variable
CRLF=[char(13) char(10)];

DMC = ['MOAB' CRLF];
DMC = [DMC 'PVA=0,0,-1;' CRLF];
DMC = [DMC 'PVB=0,0,-1;' CRLF];
DMC = [DMC 'DA*,*[0]' CRLF];
DMC = [DMC 'TM1000;' CRLF];
DMC = [DMC 'f=1;' CRLF];
DMC = [DMC 'fO=25;' CRLF];
DMC = [DMC 'fAng=60;' CRLF];
DMC = [DMC 'foldSt=80;' CRLF];
DMC = [DMC 'foldEn=360;' CRLF];
DMC = [DMC 'N=32;' CRLF];
DMC = [DMC 'Ncycle=3;' CRLF];
DMC = [DMC 'enMotA=1;' CRLF];
DMC = [DMC 'enMotB=1;' CRLF];
DMC = [DMC 'enRelFol=1;' CRLF];
DMC = [DMC 'debugMsg=1;' CRLF];
DMC = [DMC 'gRA=2;' CRLF];
DMC = [DMC 'gRB=10.24;' CRLF];
DMC = [DMC 'res=8000;' CRLF];
DMC = [DMC 'pi=3.1415926535;' CRLF];
DMC = [DMC 'dt=1/f/N;' CRLF];
DMC = [DMC 'fOCntB=@INT[fO*gRB/360*res];' CRLF];
DMC = [DMC 'fCntB=@INT[fAng*gRB/360*res];' CRLF];
DMC = [DMC 'Np1=N+1;' CRLF];
DMC = [DMC 'DMtim[Np1]' CRLF];
DMC = [DMC 'DMangB0[Np1],velB0[Np1];' CRLF];
DMC = [DMC 'DMangBf[Np1],velBf[Np1];' CRLF];
DMC = [DMC 'DMangB[Np1];' CRLF];
DMC = [DMC 'DMrAngB[Np1],velB[Np1];' CRLF];
DMC = [DMC 'DMrAngA[Np1],velA[Np1];' CRLF];
DMC = [DMC 'DMcntA[10000];' CRLF];
DMC = [DMC 'DMcntB[10000];' CRLF];
DMC = [DMC 'DMtest[N];' CRLF];
DMC = [DMC 'JS#zeroAry("angBf",0);' CRLF];
DMC = [DMC 'JS#zeroAry("velBf",0);' CRLF];
DMC = [DMC 'i=0;' CRLF];
DMC = [DMC 't=0;' CRLF];
DMC = [DMC '#profMov' CRLF];
DMC = [DMC 'rAngA[i]=@INT[gRA*res/N];' CRLF];
DMC = [DMC 'velA[i]=@INT[gRA*res*f];' CRLF];
DMC = [DMC 'flapTx=i/N*360;' CRLF];
DMC = [DMC 'tmp1=fOCntB*(1-@COS[flapTx])/2;' CRLF];
DMC = [DMC 'tmp2=@INT[tmp1];' CRLF];
DMC = [DMC 'angB0[i]=tmp2;' CRLF];
DMC = [DMC 'tmp1=fOCntB*f*2*pi*@SIN[flapTx]/2;' CRLF];
DMC = [DMC 'tmp2=@INT[tmp1];' CRLF];
DMC = [DMC 'velB0[i]=tmp2;' CRLF];
DMC = [DMC 'IF((foldSt<=@INT[flapTx])&(@INT[flapTx]<=(foldEn+1))&enRelFol=1);' CRLF];
DMC = [DMC 'relCycle=(360/(foldEn-foldSt));' CRLF];
DMC = [DMC 'foldReTx=relCycle*(flapTx-foldSt);' CRLF];
DMC = [DMC 'tmp1=fCntB*(1-@COS[foldReTx])/2;' CRLF];
DMC = [DMC 'tmp2=@INT[tmp1];' CRLF];
DMC = [DMC 'angBf[i]=tmp2;' CRLF];
DMC = [DMC 'tmp1=fCntB*(relCycle*f*2*pi)*@SIN[foldReTx]/2;' CRLF];
DMC = [DMC 'tmp2=@INT[tmp1];' CRLF];
DMC = [DMC 'velBf[i]=tmp2;' CRLF];
DMC = [DMC 'ELSE' CRLF];
DMC = [DMC 'angBf[i]=0;' CRLF];
DMC = [DMC 'velBf[i]=0;' CRLF];
DMC = [DMC 'ENDIF' CRLF];
DMC = [DMC 'tmp1=_TM;' CRLF];
DMC = [DMC 'tim[i]=@INT[(1/f)*tmp1/N];' CRLF];
DMC = [DMC 't=t+dt' CRLF];
DMC = [DMC 'i=i+1' CRLF];
DMC = [DMC 'JP#profMov,i<=N' CRLF];
DMC = [DMC 'rAngA[N]=0;' CRLF];
DMC = [DMC 'velA[N]=0;' CRLF];
DMC = [DMC 'tim[N]=0;' CRLF];
DMC = [DMC 'i=0;' CRLF];
DMC = [DMC '#absBmov' CRLF];
DMC = [DMC 'j=i+1;' CRLF];
DMC = [DMC 'rAngB[i]=(angB0[j]+angBf[j])-(angB0[i]+angBf[i]);' CRLF];
DMC = [DMC 'velB[i]=velB0[j]+velBf[j];' CRLF];
DMC = [DMC 'i=i+1;' CRLF];
DMC = [DMC 'JP#absBmov,i<N' CRLF];
DMC = [DMC 'i=0' CRLF];
DMC = [DMC '#debug' CRLF];
DMC = [DMC 'MG"";' CRLF];
DMC = [DMC 'MG"ind=",i;' CRLF];
DMC = [DMC 'MG"rot=",i/N*360;' CRLF];
DMC = [DMC 'MG"rAngB=",rAngB[i]' CRLF];
DMC = [DMC 'MG"velB0=",velB0[i+1]' CRLF];
DMC = [DMC 'MG"velBf=",velBf[i+1]' CRLF];
DMC = [DMC 'MG"velB=",velB[i]' CRLF];
DMC = [DMC 'i=i+1;' CRLF];
DMC = [DMC 'JP#debug,(i<N)' CRLF];
DMC = [DMC 'SHB;' CRLF];
DMC = [DMC 'SHA;' CRLF];
DMC = [DMC 'DPA=0;' CRLF];
DMC = [DMC 'DPB=0;' CRLF];
DMC = [DMC 'RC0;' CRLF];
DMC = [DMC 'JS#record("cntA","cntB");' CRLF];
DMC = [DMC 'j=0;' CRLF];
DMC = [DMC '#main' CRLF];
DMC = [DMC 'i=0;' CRLF];
DMC = [DMC '#ptLoop' CRLF];
DMC = [DMC 'PVA=rAngA[i],velA[i],tim[i];' CRLF];
DMC = [DMC 'PVB=rAngB[i],velB[i],tim[i];' CRLF];
DMC = [DMC 'i=i+1;' CRLF];
DMC = [DMC 'JP#ptLoop,i<Np1;' CRLF];
DMC = [DMC 'BTA' CRLF];
DMC = [DMC 'BTB' CRLF];
DMC = [DMC 'AMAB;' CRLF];
DMC = [DMC 'j=j+1;' CRLF];
DMC = [DMC 'JP#main,(j<Ncycle)' CRLF];
DMC = [DMC '#waitB;' CRLF];
DMC = [DMC 'JP#waitB,(_PVB<>255);' CRLF];
DMC = [DMC 'EN;' CRLF];
DMC = [DMC '#waitA;' CRLF];
DMC = [DMC 'JP#waitA,(_PVA<>255);' CRLF];
DMC = [DMC 'EN;' CRLF];
DMC = [DMC '#record;' CRLF];
DMC = [DMC 'RAcntA[],cntB[]' CRLF];
DMC = [DMC 'RD_TPA,_TPB' CRLF];
DMC = [DMC 'RC1' CRLF];
DMC = [DMC 'EN' CRLF];
DMC = [DMC '#zeroAry;' CRLF];
DMC = [DMC '^a[^b]=0' CRLF];
DMC = [DMC '^b=(^b+1)' CRLF];
DMC = [DMC 'JP#zeroAry,(^b<^a[-1])' CRLF];
DMC = [DMC 'EN' CRLF];

DMC = string(DMC);
g.programDownload(DMC);

%% preproc of daq port
% For ATI-F/T Gamma IP65 in AFAM wind tunnel 
% Output the six axials force(torque)/ raw voltage measurements 
% into csv file

% Siyang Hao
% Brown,PVD
% Jan,12,2022



%********************initialize ************************
CaseName = input('name this case \n','s');
angle = [45;0;0]; % identify the yaw pitch roll angle from the mps system, in deg
 trial = strcat(CaseName);
% load offset data 
offsetjudge = input('Do we have a proper tare for this case?[Y/N] \n','s');
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
timeLength = 10; % each session duration in seconds
s.Rate = 1000; % sample rate
s.DurationInSeconds = timeLength; 
%%%
%Get file info so it doesnt mess up
trial = strcat(trial,'_data');
% timefile = strcat(trial,'_time');
%*****************************Read in measurment values********************
t0=clock;
i=0;
% SessionNumber = input(' How many seesions do we want? \n');
SessionNumber = 1;
while  i <SessionNumber %start scan for a period in seconds, approximately 
       i=i+1;
    g.command('XQ');
    disp('XQ sent, acquiring dada')
    [voltVals,time] = s.startForeground; % get the six axis output of loadcell
%   dlmwrite(trial,voltVals,'-append'); %directly write raw voltage data into file
%% live monitoring & plotting 
% use directly write if time sensitive 
    
    t(i)=etime(clock,t0);
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
    plot(t(i),F_body(1),'+k');
    plot(t(i),F_body(2),'ob');
    plot(t(i),F_body(3),'*r');
 
%     ylim([-2,4]);
     xlim([0,SessionNumber+2]);
%     forceStdError = std(forceVals)/sqrt(length(forceVals))

end
info = [num2str(i),' sessions are collected with the sample rate of ', num2str(s.Rate), 'Hz'];
disp(info);






%%



%delete all resources for the Galil DMCShell object
%delete(g);

%% acquire force data









