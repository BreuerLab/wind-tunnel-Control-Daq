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

case_name = "time_test";

% Stepper Motor Parameters
galil_address = "192.168.1.20";
dmc_file_name = "time_test.dmc";

% Force Transducer Parameters
rate = 40000; % DAQ recording frequency (Hz)
session_duration = 20; % Measurement Time

%% Setup the Galil DMC

% Create the carraige return and linefeed variable from the .dmc file.
dmc = fileread(dmc_file_name);
dmc = string(dmc);

% Connect to the Galil device.
galil = actxserver("galil");

% Set the Galil's address.
galil.address = galil_address;

% Load the program described by the .dmc file to the Galil device.
galil.programDownload(dmc);

%% Get offset data before flapping
FT_obj = ForceTransducer;
% Get the offsets at this angle.
offsets_before = FT_obj.get_force_offsets(case_name + "_before", rate, 2);
offsets_before = offsets_before(1,:); % just taking means, no SDs

disp("Initial offset data has been gathered");
beep2;

%% Set up the DAQ
% Command the galil to execute the program
galil.command("XQ");

results = FT_obj.measure_force(case_name, rate, session_duration, offsets_before);

disp("Experiment data has been gathered");
beep2; 

%% Clean up
delete(galil);

%% Display preliminary data
FT_obj.plot_results(results);

these_trigs = results(:, 8);
these_low_trigs_indices = find(these_trigs < 2);
trigger_start_frame = these_low_trigs_indices(1);
trigger_end_frame = these_low_trigs_indices(end);

galil_time = 10; % Galil waited 10 seconds
frames_elapsed = (trigger_end_frame - trigger_start_frame) + 1;
NI_time = (frames_elapsed / rate);
NI_time = vpa(NI_time, 10);

disp("Galil measured " + galil_time + " seconds");
disp("NI measured ");
disp(NI_time);
disp(" seconds");