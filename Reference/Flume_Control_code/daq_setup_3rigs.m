
function daq_setup_3rigs

% ARPA-e Pitch Heave Device Session Based Data Aquisition Setup
%   rate: data scans per second
%EDITED 2016/04/27 for new computer and output device
global s last_out pitch_bias run_num piv_var chord span foil_shape Wall_distance_right Wall_distance_left...
    flume_height flume_hertz foil_separation foil_offset Temperature Number_of_foils pitch_axis fname exp_name filt_var
pitch_bias = [ 0 0 0];
%% Experimental Setup
% Warning box (comment to ignore in future)
h = msgbox('live vector/vectrino measurement currenlty commented out in run_cycle_3rigs, in favor of [umean,ustd] = find_latest_vel.  uncomment to have vector/vectrino measurements correlated for each measurement.','Warning','warn');
disp('feel free to comment or change this warning in daq_setup_3rigs')
uiwait(h)


prompt = {'Enter chord size (in meters): ','Enter span (in meters): ','Enter foil shapes (as string): ',...
    'Enter Mean wall distance (left, in meters): ','Enter Mean wall distance (right, in meters): ','Enter Flume water height(in meters): ',...
    'Enter anticipated flume frequency (Hz): ','Enter number of foils in experiment: ','Enter foil separation distance (m): ','Enter foil offset distance (m): ',...
    'Enter flume water temperature (from vectrino, in c):   ','Enter foil Pitch Axis','Using PIV? (enter 1 for yes)','Filter data at 60Hz? (0 or 1)','Enter Experiment name (folder Name):'};
name = 'Experiment Configuration';
num_lines = 1;
defaultanswer = {'0.1','0.45','rect_endplates','0.4','0.4','0.57','25','1','0','0','21.2','0.5','0','1','Enter descriptive name'};
answer = inputdlg(prompt,name,num_lines,defaultanswer);




chord = str2num(answer{1});
span = str2num(answer{2});
foil_shape = answer(3);
Wall_distance_left = str2num(answer{4});
Wall_distance_right = str2num(answer{5});
flume_height = str2num(answer{6});
flume_hertz = str2num(answer{7});
Number_of_foils = str2num(answer{8});
foil_separation = str2num(answer{9});
foil_offset = str2num(answer{10});
Temperature = str2num(answer{11});
pitch_axis = str2num(answer{12});
piv_var = str2num(answer{13});
filt_var = str2num(answer{14});
fname = ['C:\Users\ControlSystem\Documents\vertfoil\Experiments\',num2str(Number_of_foils),'foil\',answer{15}];
exp_name = answer{15};
Date  = date;
Time = clock;
% if isdir(fname)
%     disp('Warning: experiment name already exists.  Apppending date and time')
    fname = [fname,'_',Date,'_',num2str(Time(4)),'_',num2str(Time(5)),'_',num2str(round(Time(6)))];
%     if isdir(fname)
%         disp('Warning: folder name still taken. Appending time')
%         fname = [fname,'_',num2str(Time(4)),'_',num2str(Time(5)),'_',num2str(Time(6))];
%     end
% end

mkdir(fname)
mkdir([fname,'\code'])
mkdir([fname,'\data'])
mkdir([fname,'\analysis'])

copyfile('C:\Users\ControlSystem\Documents\vertfoil\Control_code\', [fname,'\code'])



disp(['Initialized folder:',fname])
disp('Checking velocimeters')
V(1) = system('tasklist /FI "IMAGENAME eq vectrino.exe" 2>NUL | find /I /N "vectrino.exe">NUL','-echo');
V(2) = system('tasklist /FI "IMAGENAME eq vector.exe" 2>NUL | find /I /N "vector.exe">NUL','-echo');

if V(1)
%     system('C:\Nortek\Vectrino\Vectrino.exe')
    disp('Open Vectrino.exe. Start Vectrino in software.  Start data recording as well.')
end
if V(2)
%     system('C:\Nortek\Vector\Vector.exe')
    disp('Open Vector.exe. Start Vector in software.  Start data recording as well.')
else
    disp('ensure Vectrino and Vector are collecting data and recording to file')
end



disp('Inititializing NI DAQs')

% Channels in s are as follows:
% 
% Data acquisition session using National Instruments hardware:
%    No data queued.  Will run at 1000 scans/second.
%    Number of channels: 28
%       index Type Device Channel   MeasurementType        Range         Name   
%       ----- ---- ------ ------- ------------------- ---------------- ---------
%       1     ci   Dev1   ctr3    Position            n/a              Pitch 1
%       2     ci   Dev1   ctr2    Position            n/a              Heave 1
%       3     ci   Dev1   ctr1    Position            n/a              Pitch 2
%       4     ci   Dev1   ctr0    Position            n/a              Heave 2
%       5     ci   Dev2   ctr0    Position            n/a              Pitch 3
%       6     ci   Dev2   ctr1    Position            n/a              Heave 3
%       7     ai   Dev1   ai0     Voltage (Diff)      -10 to +10 Volts Wallace 1
%       8     ai   Dev1   ai1     Voltage (Diff)      -10 to +10 Volts Wallace 2
%       9     ai   Dev1   ai2     Voltage (Diff)      -10 to +10 Volts Wallace 3
%       10    ai   Dev1   ai3     Voltage (Diff)      -10 to +10 Volts Wallace 4
%       11    ai   Dev1   ai4     Voltage (Diff)      -10 to +10 Volts Wallace 5
%       12    ai   Dev1   ai5     Voltage (Diff)      -10 to +10 Volts Wallace 6
%       13    ai   Dev1   ai6     Voltage (SingleEnd) -10 to +10 Volts Vel_x
%       14    ai   Dev1   ai14    Voltage (SingleEnd) -10 to +10 Volts Vel_y
%       15    ai   Dev1   ai7     Voltage (SingleEnd) -10 to +10 Volts Vel_z1
%       16    ai   Dev1   ai15    Voltage (SingleEnd) -10 to +10 Volts Vel_z2
%       17    ai   Dev1   ai16    Voltage (Diff)      -10 to +10 Volts Gromit 1
%       18    ai   Dev1   ai17    Voltage (Diff)      -10 to +10 Volts Gromit 2
%       19    ai   Dev1   ai18    Voltage (Diff)      -10 to +10 Volts Gromit 3
%       20    ai   Dev1   ai19    Voltage (Diff)      -10 to +10 Volts Gromit 4
%       21    ai   Dev1   ai20    Voltage (Diff)      -10 to +10 Volts Gromit 5
%       22    ai   Dev1   ai21    Voltage (Diff)      -10 to +10 Volts Gromit 6
%       23    ao   Dev1   ao2     Voltage (SingleEnd) -10 to +10 Volts Pitch 1
%       24    ao   Dev1   ao0     Voltage (SingleEnd) -10 to +10 Volts Heave 1
%       25    ao   Dev1   ao3     Voltage (SingleEnd) -10 to +10 Volts Pitch 2
%       26    ao   Dev1   ao1     Voltage (SingleEnd) -10 to +10 Volts Heave 2
%       27    ao   Dev2   ao0     Voltage (SingleEnd) -10 to +10 Volts Pitch 3
%       28    ao   Dev2   ao1     Voltage (SingleEnd) -10 to +10 Volts Heave 3

s=daq.createSession('ni');
s.Rate=1000;

pitch_axis = 0.5;

%% counters
global ch1
ch1=s.addCounterInputChannel('dev3','ctr0','Position');
% ch1.EncoderType='X4';
ch1.EncoderType='X4';
ch1.ZResetEnable=0;
ch1.Name = 'Pitch rig1 Shawn';
ch1.ZResetCondition = 'BothLow';
% ch1.TerminalA
% ch1.TerminalB
% ch1.TerminalZ
ch1.ZResetValue = -65;
global ch2
ch2=s.addCounterInputChannel('dev3','ctr1','Position');
ch2.EncoderType='X4';
ch2.ZResetEnable=0;
ch2.ZResetCondition = 'BothLow';
ch2.ZResetValue = 0;
ch2.Name = 'Heave rig1 Shawn';
% ch2.TerminalA
% ch2.TerminalB
% ch2.TerminalZ
global ch3
ch3=s.addCounterInputChannel('Dev2','ctr3','Position');
ch3.EncoderType='X4';
ch3.ZResetEnable=0;
ch3.ZResetCondition = 'BothLow';
ch3.Name = 'Pitch Gromit mid';
% ch3.TerminalA
% ch3.TerminalB
% ch3.TerminalZ
ch3.ZResetValue = -795;
global ch4
ch4=s.addCounterInputChannel('dev2','ctr2','Position');
ch4.EncoderType='X4';
ch4.ZResetEnable=0;
ch4.ZResetCondition = 'BothLow';
ch4.ZResetValue = 0;
ch4.Name = 'Heave Gromitmid';
% ch4.TerminalA
% ch4.TerminalB
% ch4.TerminalZ
global ch5
ch5=s.addCounterInputChannel('Dev2','ctr1','Position');
ch5.EncoderType='X4';
ch5.ZResetEnable=0;
ch5.ZResetCondition = 'BothLow';
ch5.Name = 'Pitch Gromit last';
% ch5.ZResetValue = -104;
ch5.ZResetValue = 338;
global ch6
ch6=s.addCounterInputChannel('Dev2','ctr0','Position');
ch6.EncoderType='X4';
ch6.ZResetEnable=0;
ch6.ZResetCondition = 'BothLow';
ch6.ZResetValue = 0;
ch6.Name = 'Heave Gromit last';

% 
% s.addTriggerConnection('Dev1/PFI12','Dev4/PFI0','StartTrigger');
% s.addClockConnection('Dev1/PFI14','Dev4/PFI14', 'ScanClock');

% ch1.TerminalA
% ch1.TerminalB
% ch1.TerminalZ
% ch2.TerminalA
% ch2.TerminalB
% % ch2.TerminalZ
% ch3.TerminalA
% ch3.TerminalB
% ch3.TerminalZ
% % ch4.TerminalA
% ch4.TerminalB
% ch4.TerminalZ
disp('Counters done.')

%% Inputs
global chins1 chins2 chins3
chins1=s.addAnalogInputChannel('dev2',[0 1 2 3 4 5 ],'Voltage');
chins2=s.addAnalogInputChannel('dev3',[0 8 1 9],'Voltage');
chins3=s.addAnalogInputChannel('dev2',[16 17 18 19 20 21],'Voltage');
chins4 = s.addAnalogInputChannel('dev3',[2],'Voltage');
chins1(1).Name = 'Wallace 1';
chins1(2).Name = 'Wallace 2';
chins1(3).Name = 'Wallace 3';
chins1(4).Name = 'Wallace 4';
chins1(5).Name = 'Wallace 5';
chins1(6).Name = 'Wallace 6';


chins2(1).TerminalConfig='SingleEnded';

chins2(1).Name = 'Vel_x';
chins2(2).TerminalConfig='SingleEnded';
chins2(2).Name = 'Vel_y';
chins2(3).TerminalConfig='SingleEnded';
chins2(3).Name = 'Vel_z1';
chins2(4).TerminalConfig='SingleEnded';
chins2(4).Name = 'Vel_z2';


chins3(1).Name = 'Gromit 1';
chins3(2).Name = 'Gromit 2';
chins3(3).Name = 'Gromit 3';
chins3(4).Name = 'Gromit 4';
chins3(5).Name = 'Gromit 5';
chins3(6).Name = 'Gromit 6';

chins4(1).Name = 'Wallace Pitch position';
% chindev3 = s.addAnalogInputChannel('Dev3',[0 1 2],'Voltage');
% chindev3(1).TerminalConfig='SingleEnded';
% chindev3(1).Name = 'for_timing_not_used';
% 
% chindev3(2).TerminalConfig='SingleEnded';
% chindev3(2).Name = 'for_timing_not_used';
% 
% chindev3(3).TerminalConfig='SingleEnded';
% chindev3(3).Name = 'for_timing_not_used';


% ch23=s.addDigitalChannel('dev2','Port0/line6','InputOnly');
disp('Analog inputs done.')


%% Outputs 
% global chout
global chout1 chout2 chout3 chout4 chout5 chout6 %chout7 chout8
chout1 = s.addAnalogOutputChannel('dev3','ao0','Voltage');  % Pitch 1   Shawn
chout2 = s.addAnalogOutputChannel('dev3','ao1','Voltage');  % Heave 1   Shawn
chout3 = s.addAnalogOutputChannel('dev2','ao2','Voltage');  % Pitch    Gromit
chout4 = s.addAnalogOutputChannel('dev2','ao3','Voltage');  % Heave   Gromit
chout5 = s.addAnalogOutputChannel('dev2','ao0','Voltage');  % Pitch  Wallace
chout6 = s.addAnalogOutputChannel('dev2','ao1','Voltage');  % Heave  Wallace
% chout7 = s.addAnalogOutputChannel('dev2','ao0','Voltage');  % 
% chout8 = s.addAnalogOutputChannel('dev3','ao0','Voltage');  % 


% chout1.TerminalConfig = 'Differential';
chout1.Name = 'Pitch 1 Shawn';
chout2.Name = 'Heave 1 Shawn';
chout3.Name = 'Pitch 2 Gromit';
chout4.Name = 'Heave 2 Gromit'; 
chout5.Name = 'Pitch 3 Wallace';
chout6.Name = 'Heave 3 Wallace';
disp('Analog outputs done. Syncing and Zeroing output...')

% addTriggerConnection(s,'Dev1/PFI4','Dev4/PFI0','StartTrigger');
% 
% s.addClockConnection('Dev1/PFI5','Dev4/PFI1','ScanClock');

% addTriggerConnection(s,'/Dev2/RTSI0','/Dev1/RTSI0','StartTrigger');
% addTriggerConnection(s,'/Dev2/RTSI0','/Dev3/RTSI0','StartTrigger');
% addClockConnection(s,'/Dev2/RTSI1','/Dev1/RTSI1','ScanClock');
% addClockConnection(s,'/Dev2/RTSI1','/Dev3/RTSI1','ScanClock');
% % 
% addTriggerConnection(s,'/Dev3/20MHzTimebase','/Dev1/PFI6','StartTrigger');
% addTriggerConnection(s,'/Dev3/PFI14','/Dev2/PFI14','StartTrigger');
% addClockConnection(s,'/Dev3/PFI15','/Dev1/PFI5','ScanClock');
% addClockConnection(s,'/Dev3/PFI15','/Dev2/PFI15','ScanClock');
% % 
% t1 = addTriggerConnection(s,'/Dev3/PFI14','/Dev1/PFI6','StartTrigger');
% t2 = addTriggerConnection(s,'/Dev3/PFI14','/Dev2/PFI14','StartTrigger');
% c1 = addClockConnection(s,'/Dev1/PFI5','/Dev2/PFI15','ScanClock');
% c2 = addClockConnection(s,'/Dev1/PFI5','/Dev3/PFI15','ScanClock');

s.queueOutputData([0 0 0 0 0 0])
dat = s.startForeground;
last_out = [0 0 0 0 0 0];
pitch_bias = [0 0 0];
run_num = 0;



% chord = input('Enter chord size (in meters):   ');
% span = input('Enter span (in meters):   ');
% foil_shape = input('Enter foil shapes (as string):   ');
% Wall_distance_left = input('Enter Mean wall distance (in meters):   ');
% Wall_distance_right = input('Enter Mean wall distance (in meters):   ');
% flume_height = input('Enter Flume water height(in meters):   ');
% flume_hertz = input('Enter anticipated flume frequency (Hz):  ');
% foil_separation = input('Enter foil separation distance (m):   ');
% foil_offset = input('Enter foil offset distance (m):   ');
% Temperature = input('Enter flume water temperature (from vectrino, in c):   ');



% d = datevec(date);
% DIR = sprintf('C:\\Users\\Control Systems\\Documents\\vert_foil\\Data\\3rigs\\%02i_%02i\\',d(2),d(3));
% if exist(DIR,'dir')==7
%     run_num = numel(dir([DIR,'run*']))+1;
% else
% mkdir(DIR);
% end
save([fname,'\Exp_config'],'answer');
disp('All set. Turn on motor power. Press any key to run find_bias_3rigs');
find_bias_3rigs;

disp('Run flume.  Click <a href="matlab: find_zero_pitch">find_zero_pitch</a> when at full speed.')
end
