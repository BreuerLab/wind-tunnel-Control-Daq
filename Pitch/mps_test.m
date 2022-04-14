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
fprintf("Initalizing the experiment.\n");

fprintf("\tWaiting for confirmation on wind tunnel speed.\n");
uiwait(...
    msgbox(...
    "Set the tunnel to 0 m/s. Once it equilibrates, click okay" +...
    " to continue.", ...
    "Initalization"));

fprintf("\tHoming the pitch axis.\n");
Pitch_Home(0);

case_name = inputdlg("Enter the case name:", "Initalization", [1 50],...
    "trial");
case_name = string(case_name{1});

case_alpha = inputdlg( ...
    "Enter the desired angle of attack in degrees.",...
    "Initalization", ...
    [1 50] ...
    );
case_alpha = str2double(case_alpha{1});

fprintf("\tPitching to appropriate angle of attack.\n");
Pitch_Home(case_alpha);
pause(5);

taring = questdlg("Is there a taring file?", "Initalization", "Yes",...
    "No", "No");
taring = strcmp(taring, "Yes");

if taring
    [offset_filename, offset_file_path] = uigetfile("*.csv",...
        "Select the taring file");
    [offset_data] = csvread(offset_filename);
else
    fprintf("\tGenerating offset file.\n");
    offset_data = offset(case_name);
end

% Store the six average voltages from taring. 1x6. V.
offsets = offset_data(1,:); 

fprintf("\tWaiting for confirmation on wind tunnel speed.\n");
uiwait(...
    msgbox(...
    "Set the tunnel to the desired speed. Once it equilibrates, " +...
    "click okay to continue.",...
    "Initalization"));

fprintf("\tQuerying user for test conditions.\n");
trial_length = inputdlg( ...
    "Enter the duration of the experiment in seconds.",...
    "Initalization", ...
    [1 50], ...
    "5");
trial_length = str2double(trial_length{1});

euler_angles = [0, case_alpha, 0];

%% Set up the data acquisition
fprintf("Setting up the data acquisition.\n");

% Create daq session.
% TODO: Check with Siyang if this is correct.
session = daq.createSession("ni");
addAnalogInputChannel(session,"Dev1",0,"Voltage");
addAnalogInputChannel(session,"Dev1",1,"Voltage");
addAnalogInputChannel(session,"Dev1",2,"Voltage");
addAnalogInputChannel(session,"Dev1",3,"Voltage");
addAnalogInputChannel(session,"Dev1",4,"Voltage");
addAnalogInputChannel(session,"Dev1",5,"Voltage");

% Load the calibration matrix.
% TODO: Check with Siyang if this is correct.
load Wallance_Cal;

% Set the sampling rate. Hz.
session.Rate = 1000;

% Set the test duration. s.
session.DurationInSeconds = trial_length; 

% Set the file name for where the data will be stored info.
case_data_file = case_name + "_data.csv";


%% Acquire data
fprintf("Acquiring data.\n");

[all_raw_volts, times] = session.startForeground;

raw_volts = all_raw_volts(:, 1:6);
volts = raw_volts - ones(trial_length * session.Rate, 1) * offsets;

results_sensor_frame = (matrixVals * volts')';
avg_results_sensor_frame = mean(results_sensor_frame);

dcm = angle2dcm(euler_angles(1), euler_angles(2), euler_angles(3));
avg_forces_sensor_frame = avg_results_sensor_frame(1:3);
avg_torques_sensor_frame = avg_results_sensor_frame(4:6);

avg_forces_body_frame = (dcm * avg_forces_sensor_frame')';
avg_torques_body_frame = (dcm * avg_torques_sensor_frame')';

% Display the results to the console.
fprintf("\tAverage Forces Body Frame:\n");
fprintf("\t\tx: %.2f N\n", avg_forces_body_frame(1));
fprintf("\t\ty: %.2f N\n", avg_forces_body_frame(2));
fprintf("\t\tz: %.2f N\n", avg_forces_body_frame(3));
fprintf("\tAverage Torques Body Frame:\n");
fprintf("\t\tx: %.2f N*m\n", avg_torques_body_frame(1));
fprintf("\t\ty: %.2f N*m\n", avg_torques_body_frame(2));
fprintf("\t\tz: %.2f N*m\n", avg_torques_body_frame(3));

% Record results in the data file and then save it.
writematrix(avg_forces_body_frame, case_data_file);
writematrix(avg_torques_body_frame, case_data_file, "WriteMode", "append");

fprintf("Experiment complete.\n");