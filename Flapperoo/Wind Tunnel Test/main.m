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
addpath ..\VFD\ % controls wind tunnel motor
addpath 'matlab scripts'
addpath 'galil scripts'

% -----------------------------------------------------------------------
% ----------Parameters to Adjust for Your Specific Experiment------------
% -----------------------------------------------------------------------
AoA = [0]; % angle of attack, set by MPS system
freq = [5]; % wingbeat frequency, set by motor RPM
speed = 4; % wind tunnel air speed
wing_type = "big_blue_me_inside"; % whatever name you'd like to use
automatic = true; % run through trials automatically?
debug = false; % testing on personal computer?

run_trials(AoA, freq, speed, wing_type, automatic, debug);