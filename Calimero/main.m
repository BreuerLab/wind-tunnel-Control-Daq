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

addpath(genpath("."))

% -----------------------------------------------------------------------
% ----------Parameters to Adjust for Your Specific Experiment------------
% -----------------------------------------------------------------------
AoA = [-16:2:16]; % angle of attack, set by MPS system
AoA = ladder_sort(AoA); % rearrange in nonascending ladder order
% [-16:1.5:-12 -12:1:-8 -8:0.5:8 8:1:12 12:1.5:16]
% freq = [0, 4, 6, 8, 10]; % wingbeat frequency, set by motor RPM
freq = [6, 10, 0, 4, 8]; % freq2 = freq(randperm(length(freq)))
measure_revs = 180; % number of wingbeats

speed = 4; % wind tunnel air speed
wing_type = "test"; % whatever name you'd like to use
automatic = false; % run through trials automatically?
load_cell = false; % running without loadcell attached
debug = false; % testing on personal computer?

run_trials(AoA, freq, speed, wing_type, measure_revs, automatic, load_cell, debug);