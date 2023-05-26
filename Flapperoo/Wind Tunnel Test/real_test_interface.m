% Ronan Gissler November 2023

%% Initalize the experiment
clc;
clear;
close all;

% -----------------------------------------------------------------------
% ----------Parameters to Adjust for Your Specific Experiment------------
% -----------------------------------------------------------------------
% Parameter Space - What variable ranges are you testing?
% AoA = -14:2:14;
AoA = 0;
freq = [0, 2, 3, 3.5, 4, 4.5, 5];
speed = 0; % 0, 2, 4
wing_type = "elastosil";

real_test(AoA, freq, speed, wing_type, true);