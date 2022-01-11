function daq_setup_3rigs

% ARPA-e Pitch Heave Device Session Based Data Aquisition Setup
%   rate: data scans per second
%EDITED 2016/04/27 for new computer and output device
global s last_out pitch_offset1 pitch_offset2 pitch_offset3 pitch_bias run_num piv_var chord span foil_shape Wall_distance_right Wall_distance_left flume_height flume_hertz foil_separation foil_offset Temperature Number_of_foils pitch_axis fname
pitch_bias = [ 0 0 0];
%% Experimental Setup
% 
prompt = {'Enter chord size (in meters): ','Enter span (in meters): ','Enter foil shapes (as string): ',...
    'Enter Mean wall distance (left, in meters): ','Enter Mean wall distance (right, in meters): ','Enter Flume water height(in meters): ',...
    'Enter anticipated flume frequency (Hz): ','Enter number of foils in experiment: ','Enter foil separation distance (m): ','Enter foil offset distance (m): ',...
    'Enter flume water temperature (from vectrino, in c):   ','Enter foil Pitch Axis','Using PIV? (enter 1 for yes)','Enter Experiment name (folder Name):'};
name = 'Experiment Configuration';
num_lines = 1;
defaultanswer = {'0.1','0.45','ellipse','0.4','0.4','0.57','30','1','0','0','21.2','0.5','0','Enter descriptive name'};
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
fname = ['C:\Users\ControlSystem\Documents\vertfoil\Experiments\',num2str(Number_of_foils),'foil\',answer{14}];

mkdir(fname)
mkdir([fname,'\code'])
mkdir([fname,'\data'])
mkdir([fname,'\analysis'])

copyfile('C:\Users\ControlSystem\Documents\vertfoil\Control_code\', [fname,'\code'])
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
ch3.Name = 'Pitch rig2 Gromit';
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
ch4.Name = 'Heave rig2 Gromit';
% ch4.TerminalA
% ch4.TerminalB
% ch4.TerminalZ
global ch5
ch5=s.addCounterInputChannel('Dev2','ctr1','Position');
ch5.EncoderType='X4';
ch5.ZResetEnable=0;
ch5.ZResetCondition = 'BothLow';
ch5.Name = 'Pitch rig3 Wallace';
% ch5.ZResetValue = -104;
ch5.ZResetValue = 338;
global ch6
ch6=s.addCounterInputChannel('Dev2','ctr0','Position');
ch6.EncoderType='X4';
ch6.ZResetEnable=0;
ch6.ZResetCondition = 'BothLow';
ch6.ZResetValue = 0;
ch6.Name = 'Heave rig3 Wallace';

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


%% Inputs
global chins
chins=s.addAnalogInputChannel('dev2',[0 1 2 3 4 5 6 14 7 15 16 17 18 19 20 21],'Voltage');

chins(1).Name = 'Wallace 1';
chins(2).Name = 'Wallace 2';
chins(3).Name = 'Wallace 3';
chins(4).Name = 'Wallace 4';
chins(5).Name = 'Wallace 5';
chins(6).Name = 'Wallace 6';
chins(7).TerminalConfig='SingleEnded';

chins(7).Name = 'Vel_x';
chins(8).TerminalConfig='SingleEnded';
chins(8).Name = 'Vel_y';
chins(9).TerminalConfig='SingleEnded';
chins(9).Name = 'Vel_z1';
chins(10).TerminalConfig='SingleEnded';
chins(10).Name = 'Vel_z2';
chins(11).Name = 'Gromit 1';
chins(12).Name = 'Gromit 2';
chins(13).Name = 'Gromit 3';
chins(14).Name = 'Gromit 4';
chins(15).Name = 'Gromit 5';
chins(16).Name = 'Gromit 6';

% ch23=s.addDigitalChannel('dev2','Port0/line6','InputOnly');

%% Outputs 
% global chout
chout1 = s.addAnalogOutputChannel('dev1','ao0','Voltage');  % Pitch 1   Shawn
chout2 = s.addAnalogOutputChannel('dev1','ao1','Voltage');  % Heave 1   Shawn
chout3 = s.addAnalogOutputChannel('dev1','ao2','Voltage');  % Pitch 2   Gromit
chout4 = s.addAnalogOutputChannel('dev1','ao3','Voltage');  % Heave 2   Gromit
chout5 = s.addAnalogOutputChannel('dev1','ao4','Voltage');  % Pitch 3   Wallace
chout6 = s.addAnalogOutputChannel('dev1','ao5','Voltage');  % Heave 3   Wallace


% chout1.TerminalConfig = 'Differential';
chout1.Name = 'Pitch 1 Shawn';
chout2.Name = 'Heave 1 Shawn';
chout3.Name = 'Pitch 2 Gromit';
chout4.Name = 'Heave 2 Gromit';
chout5.Name = 'Pitch 3 Wallace';
chout6.Name = 'Heave 3 Wallace';

% addTriggerConnection(s,'Dev1/PFI4','Dev4/PFI0','StartTrigger');
% 
% s.addClockConnection('Dev1/PFI5','Dev4/PFI1','ScanClock');

s.queueOutputData([0 0 0 0 0 0])
dat = s.startForeground;
last_out = [0 0 0 0 0 0];
pitch_offset1 = 0;
pitch_offset2 = 0;
pitch_offset3 = 0;
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



d = datevec(date);
DIR = sprintf('C:\\Users\\Control Systems\\Documents\\vert_foil\\Data\\3rigs\\%02i_%02i\\',d(2),d(3));
if exist(DIR,'dir')==7
    run_num = numel(dir([DIR,'run*']))+1;
else
mkdir(DIR);
end
save([DIR,'Exp_config'],'answer');
disp('Run find_bias_3rigs');
end
