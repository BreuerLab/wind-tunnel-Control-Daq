clear
close all
% This program runs the motor and collects data from the force transducer
% for a single benchtop test.

% Load Cell: ATI Gamma IP65
% DAQ: NI USB-6341
% DMC: Galil DMC-4143
% Motor: VEXTA PH266-E1.2 stepper motor

% Modified by: Ronan Gissler November 2022
% Original by: Cameron Urban July 2022

%% Initalize the experiment
clc;
clear variables;
close all;

% -----------------------------------------------------------------------
% ----------Parameters to Adjust for Your Specific Experiment------------
% -----------------------------------------------------------------------
% Data Logging Parameters
case_name = "6Hz_body";

% Stepper Motor Parameters
galil_address = "192.168.1.20";
dmc_file_name = "benchtop_test_commented.dmc";
rev = 51200; % should be 3200 instead
accel = 150000;
speed = 6*rev;
distance = 113*rev;

% Force Transducer Parameters
rate = 1000; % DAQ recording frequency (Hz)
offset_duration = 2; % Taring/Offset/Zeroing Time
session_duration = 25; % Measurement Time

%% Setup the Galil DMC

% Create the carraige return and linefeed variable from the .dmc file.
dmc = fileread(dmc_file_name);
dmc = string(dmc);

% Replace the place holders in the .dmc file with the values specified
% here. Other parameters can be changed directly in .dmc file.
dmc = strrep(dmc, "accel_placeholder", num2str(accel));
dmc = strrep(dmc, "speed_placeholder", num2str(speed));
dmc = strrep(dmc, "distance_placeholder", num2str(distance));

% Connect to the Galil device.
galil = actxserver("galil");

% Set the Galil's address.
galil.address = galil_address;

% Load the program described by the .dmc file to the Galil device.
galil.programDownload(dmc);

%% Get offset data for this experiment
FT_obj = ForceTransducer;
% Get the offsets at this angle.
offsets = FT_obj.get_force_offsets(case_name, rate, offset_duration);
offsets = offsets(1,:); % just taking means, no SDs

% Beep to signal that the offset data has been gathered.
beep;

%% Set up the DAQ
% Command the galil to execute the program
galil.command("XQ");

results = FT_obj.measure_force(case_name, rate, session_duration, offsets);

beep; 

%% Clean up
delete(galil);

%% Display preliminary data
FT_obj.plot_results(results);

% Beep to signal the experiment is finished.
beep;