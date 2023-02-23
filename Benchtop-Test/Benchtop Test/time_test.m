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

% Stepper Motor Parameters
galil_address = "192.168.1.20";
dmc_file_name = "time_test.dmc";

% Force Transducer Parameters
rate = 15000; % DAQ recording frequency (Hz)
session_duration = 20000; % Measurement Time

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

drift = offsets_after - offsets_before;
disp("Over the course of the experiment, the force transducer drifted ");
disp('     F_x       F_y       F_z       M_x       M_y       M_z');
disp(drift);