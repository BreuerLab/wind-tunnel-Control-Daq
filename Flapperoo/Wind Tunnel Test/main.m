% Ronan Gissler November 2023

%% Initalize the experiment
clc;
clear;
close all;

% For this code to work, you need to add the flapperoo code from the
% github to the downloads folder
addpath C:\Users\rgissler\Downloads\wind-tunnel-Control-Daq-Flapperoo\MPS
addpath C:\Users\rgissler\Downloads\wind-tunnel-Control-Daq-Flapperoo\Flapperoo\'Wind Tunnel Test'\'matlab scripts'\
addpath C:\Users\rgissler\Downloads\wind-tunnel-Control-Daq-Flapperoo\Flapperoo\'Wind Tunnel Test'\'galil scripts'\

% -----------------------------------------------------------------------
% ----------Parameters to Adjust for Your Specific Experiment------------
% -----------------------------------------------------------------------
% Parameter Space - What variable ranges are you testing?
% AoA = -14:2:14;
AoA = [0, 2];
freq = [1, 1.2];
speed = 0; % 0, 2, 4
wing_type = "test";
automatic = true;
debug = false;

run_trial(AoA, freq, speed, wing_type, automatic, debug);