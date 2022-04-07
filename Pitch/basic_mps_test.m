% This script is designed to set the MPS at some angle of attack, and then
% acquire and save the forces and moment data for a some amount of time.
% This script is adapted from gurneySwingTest.m by Siyang Hao.

% basic_mps_test.m
% Cameron Urban
% 04/06/2022

clc;
clear variables;
close all;

%% Initalize the experiment
fprintf('Initalizing the experiment.\n');

% fprintf('\tHoming the pitch axis.\n');
% Pitch_Home(0);

case_name = inputdlg('Enter the case name:', 'Initalization', [1 50],...
    {'trial'});
case_name = strcat(case_name);

taring = questdlg('Is there a taring file?', 'Initalization', 'Yes',...
    'No', 'No');
taring = strcmp(taring, 'Yes');

if taring
    [offset_filename, offset_file_path] = uigetfile('*.csv',...
        'Select the taring file');
    [offset_data] = csvread(offset_filename);
else
    fprintf('\tGenerating offset file. This will take one minute.\n');
    [offset_data] = offset(case_name);
end

% Store the six average voltages from taring. 1x6. V.
offsets = offset_data(1,:); 

fprintf('\tWaiting for confirmation on wind tunnel speed.\n');
uiwait(msgbox( ...
    ['Set the tunnel to the desired speed.' ...
    +' Then click okay to continue.'], ...
    'Initalization') ...
    );

fprintf('\tQuerying user for test conditions.\n');
trial_length = inputdlg( ...
    'Enter the duration of the experiment in seconds.',...
    'Initalization', ...
    [1 50] ...
    );
trial_length = str2double(trial_length{1});

% case_alpha = inputdlg( ...
%     'Enter the desired angle of attack in degrees.',...
%     'Initalization', ...
%     [1 50] ...
%     );
% case_alpha = str2double(case_alpha{1});
% 
% Pitch_Home(case_alpha);

euler_angles = [0, case_alpha, 0];

%% Set up the data acquisition
fprintf('Setting up the data acquisition.\n')

% Create daq session, 
session = daq('ni');
addinput(session,'cDAQ1Mod1',0,'Voltage');
addAnalogInputChannel(session,'cDAQ1Mod1',1,'Voltage');
addAnalogInputChannel(session,'cDAQ1Mod1',2,'Voltage');
addAnalogInputChannel(session,'cDAQ1Mod1',3,'Voltage');
addAnalogInputChannel(session,'cDAQ1Mod1',4,'Voltage');
addAnalogInputChannel(session,'cDAQ1Mod1',5,'Voltage');

% Load the calibration matrix.
load Gromit_Cal;

% Set the sampling rate. Hz.
session.Rate = 1000;

% Set the test duration. s.
session.DurationInSeconds = trial_length; 

% Set the file name for where the data will be stored info.
case_data_file = strcat(case_name, '_data');

% Pause for 15 seconds to insure that the flow has become steady.
fprintf('\tWaiting for equilibration.\n')
pause(15);

%% Acquire data
fprintf('Acquiring data.\n')

% Record the start time of data aquisition. [yr, mon, day, hr, min, s].
start_time = clock;

[all_raw_volts, times] = session.startForeground;

raw_volts = all_raw_volts(:, 1:6);
volts = raw_volts - ones(trial_length * session.Rate, 1) * offsets;

results_sensor_frame = (Gromit_Cal * volts')';
avg_results_sensor_frame = mean(results_sensor_frame);

dcm = angle2dcm(euler_angles(1), euler_angles(2), euler_angles(3));
avg_results_body_frame = dcm * avg_results_sensor_frame;

% Record results in the data file and then save it.
writematrix(avg_results_body_frame, case_data_file, '-append');
save(case_data_file);

fprintf('Experiment complete.\n')