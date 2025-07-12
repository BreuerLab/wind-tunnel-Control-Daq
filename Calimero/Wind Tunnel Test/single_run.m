% restoredefaultpath
clear
close all

addpath(genpath("../."))

% DAQ Parameters
rate = 9000; % measurement rate of NI DAQ, in Hz
offset_duration = 2; % in seconds
calibration_filepath = "../DAQ/Calibration Files/Mini40/FT52907.cal"; 
voltage = 5; % 5 or 10 volts for load cell

% Flapper Parameters
freq = 150;
speed = 0;
AoA = 0;
wing_type = "test";

measure_revs = 180;
hold_time = 10; % sec

% Set case name and wingbeat frequency for this trial
case_name = wing_type + "_" + speed + "m.s_" + AoA + "deg_" + freq + "Hz";

% Make Calimero data collection object
flapper_obj = Calimero(rate, voltage);

% Get calibration matrix from calibration file
cal_matrix = obtain_cal(calibration_filepath);

% wingbeat frequency is used to calculate session duration
padding_revs = 4;

% Get offset data before flapping at this angle and windspeed
offsets = flapper_obj.get_force_offsets(case_name + "_before", offset_duration);
offsets = offsets(1,:); % just taking means, no SDs
disp("Initial offset data has been gathered");
beep2;

esp32 = "";
force = run_trial(flapper_obj, esp32, cal_matrix, case_name, offset_duration, offsets, freq, measure_revs, padding_revs, hold_time);