% Select your parameters below and then run this file to begin the
% experiment.
%
% Note: The wind tunnel control GUI should be open and active.
% Additionally you should place it in the top right corner of the
% screen as that is the portion of the screen the code will screenshot
% at the end of each trial.
% 
% Ronan Gissler June 2023

clc;
clear;
close all;

addpath ..\MPS\ % controls model positioning arms
addpath ..\MPS\Enable_Disable\ % controls model positioning arms
addpath ..\VFD\ % controls wind tunnel motor
addpath 'matlab scripts'
addpath 'galil scripts'

% -----------------------------------------------------------------------
% ----------Parameters to Adjust for Your Specific Experiment------------
% -----------------------------------------------------------------------
% AoA = [-16:1.5:-12 -12:1:-8 -8:0.5:8 8:1:12 12:1.5:16]; % angle of attack, set by MPS system
AoA = [-8:0.5:8]; % angle of attack, set by MPS system
% freq = [0, 0.1, 2, 2.5, 3, 3.5, 3.75, 4, 4.5, 5]; % wingbeat frequency, set by motor RPM
freq = [3.5, 4, 3.75, 2, 3, 0, 0.1, 2.5, 4.5, 5, 2, 4]; % freq2 = freq(randperm(length(freq)))
measure_revs = 180; % number of wingbeats

speed = 4; % wind tunnel air speed
wing_type = "test"; % whatever name you'd like to use
automatic = false; % run through trials automatically?
debug = false; % testing on personal computer?

run_trials(AoA, freq, speed, wing_type, measure_revs, automatic, debug);

% run_trials_gravity(AoA, wing_type, automatic, debug)