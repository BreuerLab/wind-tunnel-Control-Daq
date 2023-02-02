clear
close all

% Ronan Gissler February 2023

% This file is used to analyze the data from the experiments Sakthi
% and I ran with the 1 DOF flapper robot without wings, with
% Polydimethylsiloxane (PDMS) wings, and with Carbon Black (CB) wings
% on February 2nd 2023. We test flapping speeds between 1 Hz and 3 Hz
% with no wings attached, 6 Hz had been the failure point before. We
% tested flapping speeds between 1 Hz and 4 Hz with the PDMS wings, at
% 4 Hz the gears started to skip and the wings moved erratically so we
% ended the test abruptly. We tested flapping speeds between 1 Hz and
% 3 Hz with the CB wings, at 3 Hz the gears started to skip and the
% wings moved erratically so we ended the test abruptly.

% Changes made since the test on January 19th:
% - Galil sends a digital output when motors have finished
%   accelerating at the beginning of a wingbeat period and just before
%   motors begin decelerating at the beginning of a wingbeat period
% - New 3D printed base holds flapper more snugly to table 
% - Recording at a framerate that is a factor of the number of ticks
%   per revolution so that each wingbeat has a consistent number of
%   frames

% Adjustments to make for next test:
% - Use measurement period that's divisible by each speed, here we
% have the issue: 
% ((100 cycles) / (3 cycles / sec)) * (1280 frames / sec) = 42666.666
% - Why are there extra frames recorded?
% ((100 cycles) / (1 cycles / sec)) * (1280 frames / sec) = 128000
% while instead we got 128018, 128018, 128019
% Is it possible that the Galil misses counting some ticks increasing
% the measurement period as its still try to reach the prescribed
% number of ticks

%%

% ----------------------------------------------------------------
% ------------------------Plot All Data---------------------------
% ----------------------------------------------------------------

files = ["..\Experiment Data\1Hz_body_experiment_020223.csv"
         "..\Experiment Data\2Hz_body_experiment_020223.csv"
         "..\Experiment Data\3Hz_body_experiment_020223.csv"
         "..\Experiment Data\1Hz_PDMS_experiment_020223.csv"
         "..\Experiment Data\2Hz_PDMS_experiment_020223.csv"
         "..\Experiment Data\3Hz_PDMS_experiment_020223.csv"
         "..\Experiment Data\1Hz_CB_experiment_020223.csv"
         "..\Experiment Data\2Hz_CB_experiment_020223.csv"];

for i = 1:length(files)
    % Get case name from file name
    case_name = erase(files(i), ["_experiment_020223.csv", "..\Experiment Data\"]);
    case_name = strrep(case_name,'_',' ');
    
    % Get data from file
    data = readmatrix(files(i));
    

    trigger_start_frame = -1;
    trigger_end_frame = -1;

    these_raw_trigger_vals = data(:, 8);
    
    for i = 1:length(these_raw_trigger_vals)
        if (trigger_start_frame == -1) % unassigned?
            if (these_raw_trigger_vals(i) < 1) % pulled low?
                trigger_start_frame = i;
            end
        elseif (trigger_end_frame == -1) % unassigned?
            if (these_raw_trigger_vals(i) > 1) % pulled high?
                trigger_end_frame = i - 1;
            end
        end
    end

    trimmed_data = data(trigger_start_frame:trigger_end_frame, :);
    display(case_name + ": " + length(trimmed_data))

    times = data(1:end,1);
    force_vals = data(1:end,2:7);

    force_means = round(mean(force_vals), 3);
    force_SDs = round(std(force_vals), 3);
    
    % Open a new figure.
    f = figure;
    f.Position = [200 50 900 560];

    % Create three subplots to show the force time histories. 
    subplot(2, 3, 1);
    plot(times, force_vals(:, 1));
    title(["F_x" ("avg: " + force_means(1) + " SD: " + force_SDs(1))]);
    xlabel("Time (s)");
    ylabel("Force (N)");
    subplot(2, 3, 2);
    plot(times, force_vals(:, 2));
    title(["F_y" ("avg: " + force_means(2) + " SD: " + force_SDs(2))]);
    xlabel("Time (s)");
    ylabel("Force (N)");
    subplot(2, 3, 3);
    plot(times, force_vals(:, 3));
    title(["F_z" ("avg: " + force_means(3) + " SD: " + force_SDs(3))]);
    xlabel("Time (s)");
    ylabel("Force (N)");

    % Create three subplots to show the moment time histories.
    subplot(2, 3, 4);
    plot(times, force_vals(:, 4));
    title(["M_x" ("avg: " + force_means(4) + " SD: " + force_SDs(4))]);
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    subplot(2, 3, 5);
    plot(times, force_vals(:, 5));
    title(["M_y" ("avg: " + force_means(5) + " SD: " + force_SDs(5))]);
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    subplot(2, 3, 6);
    plot(times, force_vals(:, 6));
    title(["M_z" ("avg: " + force_means(6) + " SD: " + force_SDs(6))]);
    xlabel("Time (s)");
    ylabel("Torque (N m)");
    
    % Label the whole figure.
    sgtitle("Force Transducer Measurement for " + case_name);
    
    case_parts = char(split(case_name));
    save([case_parts(2,:),'_',case_parts(1,1:end-1),'.mat'], 'data')
end