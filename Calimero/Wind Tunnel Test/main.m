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

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
% 'restoredefaultpath' also an option, but caused some bugs in the past

% ensure all helper functions are made accessible
addpath(genpath("../."))

% -----------------------------------------------------------------------
% ----------Parameters to Adjust for Your Specific Experiment------------
% -----------------------------------------------------------------------
% AoA = [6 6 6:1:8 8.5:0.5:11.5 12:1:14]; % angle of attack, set by MPS system
% AoA = [8 8.5:0.5:11.5]; % angle of attack, set by MPS system
% AoA = flip(AoA);
% AoA = ladder_sort(AoA); % rearrange in nonascending ladder order
AoA = 10*ones(1,5);
% [-16:1.5:-12 -12:1:-8 -8:0.5:8 8:1:12 12:1.5:16]
% freq = [4, 0, 2, 0.1, 8, 6]; % freq2 = freq(randperm(length(freq)))
% freq = [4, 0, 2, 0.1, 6]; % freq2 = freq(randperm(length(freq)))
freq = [0];
measure_revs = 200; % number of wingbeats
hold_time = 20; % seconds for glide trials

speed = 4; % wind tunnel air speed
wing_type = "NACA"; % whatever name you'd like to use
amp = 20; % degrees from midstroke to top of upstroke (or bottom of downstroke)
automatic = true; % run through trials automatically?
debug = false; % testing on personal computer?
galil_bool = false;

run_experiment(AoA, freq, speed, wing_type, amp, measure_revs, hold_time, automatic, galil_bool, debug);