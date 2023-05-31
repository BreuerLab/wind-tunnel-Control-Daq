% Ronan Gissler November 2023

%% Initalize the experiment
clc;
clear;
close all;

addpath ..\MPS\
addpath 'matlab scripts'
addpath 'galil scripts'

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