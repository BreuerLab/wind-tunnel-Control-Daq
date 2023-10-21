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
clear;
close all;

% -----------------------------------------------------------------------
% ----------Parameters to Adjust for Your Specific Experiment------------
% -----------------------------------------------------------------------
wing_type = "inertial_damper";
freq = 1;

% -----------------------------------------------------------------------
% ---------------------------System Parameters---------------------------
% -----------------------------------------------------------------------
% Stepper Motor Parameters
galil_address = "192.168.1.20";
dmc_file_name = "benchtop_test_commented.dmc";
microsteps = 256; % fixed parameter of AMP-43547
steps_per_rev = 200; % fixed parameter of PH266-E1.2
rev_ticks = microsteps*steps_per_rev; % ticks per rev
acc = 3*rev_ticks; % ticks / sec^2
vel = freq*rev_ticks; % ticks / sec
measure_revs = 60; % we want 240 wingbeats of data
padding_revs = 1; % dropped from front and back during data processing
wait_time = 4000; % 8 seconds (data collected before and after flapping)
distance = -1; % ticks to travel this trial

% Force Transducer Parameters
voltage = 5;
calibration_filepath = "../Force Transducer/Calibration Files/FT43243.cal"; 
rate = 9000; % DAQ recording frequency (Hz)
offset_duration = 2; % Taring/Offset/Zeroing Time
session_duration = -1; % Measurement Time
case_name = wing_type + "_" + freq + "Hz";

estimate_params = {rev_ticks acc vel measure_revs padding_revs wait_time};
[distance, session_duration, trigger_pos] = estimate_duration(estimate_params{:});

%% Setup the Galil DMC

% Create the carraige return and linefeed variable from the .dmc file.
dmc = fileread(dmc_file_name);
dmc = string(dmc);

% Replace the place holders in the .dmc file with the values specified
% here. Other parameters can be changed directly in .dmc file.
dmc = strrep(dmc, "accel_placeholder", num2str(acc));
dmc = strrep(dmc, "speed_placeholder", num2str(vel));
dmc = strrep(dmc, "distance_placeholder", num2str(distance));
dmc = strrep(dmc, "wait_time_placeholder", num2str(wait_time - 2000));
dmc = strrep(dmc, "wait_ticks_placeholder", num2str(trigger_pos));

% Connect to the Galil device.
galil = actxserver("galil");

% Set the Galil's address.
galil.address = galil_address;

% Ensure Galil stops motor when the run_trial function completes
% (either on its own or termination by user)
cleanup = onCleanup(@()myCleanupFun(galil));

% Load the program described by the .dmc file to the Galil device.
galil.programDownload(dmc);

% Make a force transducer object (initializes DAQ)
FT_obj = ForceTransducer(rate, voltage, calibration_filepath, 1);

%% Get offset/tare data before flapping
offsets_before = FT_obj.get_force_offsets(case_name + "_before", offset_duration);
offsets_before = offsets_before(1,:); % just taking means, no SDs

disp("Initial offset data has been gathered");
beep2;

%% Get the experiment data during flapping
% Command the galil to execute the program
galil.command("XQ");

results = FT_obj.measure_force(case_name, session_duration, offsets_before);

disp("Experiment data has been gathered");
beep2; 

%% Get offset/tare data after flapping
offsets_after = FT_obj.get_force_offsets(case_name + "_after", offset_duration);
offsets_after = offsets_after(1,:); % just taking means, no SDs

disp("Final offset data has been gathered");
beep2;

%% Clean up
delete(cleanup);
delete(galil);
delete(FT_obj);

%% Display preliminary data
drift = offsets_after - offsets_before;
FT_obj.plot_results(results, case_name, drift);