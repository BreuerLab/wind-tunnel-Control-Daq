clear
close all
clc

% This file can be used to test the force transducer.
% Begin by connecting the force transducer to the NI DAQ and the NI DAQ to
% your personal computer.

% Author: Ronan Gissler
% Date: 06/12/2023

addpath 'Calibration Files'

% Experiment Parameters
rate = 1000; % measurement rate of NI DAQ, in Hz
offset_duration = 2; % in seconds
session_duration = 4; % in seconds
case_name = "force_transducer_test";
calibration_filepath = "FT43243.cal"; 
voltage = 5; % 5 or 10 volts

% Parameters specifc to Gamma IP65 Force Transducer
force_limit = 1200; % Newton
torque_limit = 79; % Newton*meters

% Make force transducer object
FT_obj = ForceTransducer(rate, voltage, calibration_filepath, 0);

% Get the offsets before experiment
offsets_before = FT_obj.get_force_offsets(case_name + "_before", offset_duration);
offsets_before = offsets_before(1,:); % just taking means, no SDs

fig = uifigure;
fig.Position = [600 500 430 160];
movegui(fig,'center')
message = ["Offsets collected! Ready for experiment"];
title = "Experiment Setup Reminder";
uiconfirm(fig,message,title,'CloseFcn',@(h,e) close(fig));
uiwait(fig);

% Measure data during experiment
results = FT_obj.measure_force(case_name, session_duration, offsets_before);

% Get the offset after experiment
offsets_after = FT_obj.get_force_offsets(case_name + "_after", offset_duration);
offsets_after = offsets_after(1,:); % just taking means, no SDs

% Display preliminary data
drift = offsets_after - offsets_before;
FT_obj.plot_results(results, case_name, drift);

% Reaching torque or force limits?
if(max(abs(results(:,2:4))) > 0.7*force_limit)
    beep3;
    msgbox("Approaching Force Limit!!!","DANGER!","error");
end
if (max(abs(results(:,5:7))) > 0.7*torque_limit)
    beep3;
    msgbox("Approaching Torque Limit!!!","DANGER!","error");
end