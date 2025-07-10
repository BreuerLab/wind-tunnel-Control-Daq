clear
close all

addpath(genpath("."))

% Experiment Parameters
rate = 10000; % measurement rate of NI DAQ, in Hz
offset_duration = 2; % in seconds
session_duration = 120; % in seconds
case_name = "force_transducer_test";
calibration_filepath = "FT52906.cal"; 
voltage = 10; % 5 or 10 volts

% Make Calimero data collection object
flapper_obj = Calimero(rate, voltage);

% Get calibration matrix from calibration file
cal_matrix = obtain_cal(calibration_filepath);

% Get the offsets before experiment
offsets_before = flapper_obj.get_force_offsets(case_name + "_before", offset_duration);
offsets_before = offsets_before(1,:); % just taking means, no SDs

fig = uifigure;
fig.Position = [600 500 430 160];
movegui(fig,'center')
message = ["Offsets collected! Ready for experiment"];
title = "Experiment Setup Reminder";
uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
uiwait(fig);

% Measure data during experiment
results = flapper_obj.measure_force(case_name, session_duration);

% Are we approaching limits of load cell?
checkLimits(results);

% Translate data from raw values into meaningful values
[time, force, voltAdj, theta, Z] = process_data(results, offsets_before, cal_matrix);

% Get the offset after experiment
offsets_after = flapper_obj.get_force_offsets(case_name + "_after", offset_duration);
offsets_after = offsets_after(1,:); % just taking means, no SDs

drift = offsets_after - offsets_before; % over one trial
% Convert drift from voltages into forces and moments
drift = cal_matrix * drift';

fc = 100;  % cutoff frequency in Hz for filter

% Display preliminary data
raw_plot(time, force, voltAdj, theta, case_name, drift, rate, fc);