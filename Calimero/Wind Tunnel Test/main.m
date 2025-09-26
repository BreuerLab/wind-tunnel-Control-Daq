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

% restoredefaultpath
addpath(genpath("../."))

% -----------------------------------------------------------------------
% ----------Parameters to Adjust for Your Specific Experiment------------
% -----------------------------------------------------------------------
AoA = [-16:2:16]; % angle of attack, set by MPS system
% AoA = flip(AoA);
AoA = ladder_sort(AoA); % rearrange in nonascending ladder order
% AoA = 0;
% [-16:1.5:-12 -12:1:-8 -8:0.5:8 8:1:12 12:1.5:16]
% freq = [0, 2, 4, 6, 8, 10]; % wingbeat frequency, set by motor RPM
freq = [10, 4, 8, 0, 2, 6]; % freq2 = freq(randperm(length(freq)))
% freq = [3, 5, 0, 2, 4];
measure_revs = 180; % number of wingbeats
hold_time = 15; % seconds for glide trials

speed = 4; % wind tunnel air speed
wing_type = "flexible"; % whatever name you'd like to use
% wing_type = "rigid";
automatic = true; % run through trials automatically?
debug = false; % testing on personal computer?

run_experiment(AoA, freq, speed, wing_type, measure_revs, hold_time, automatic, debug);