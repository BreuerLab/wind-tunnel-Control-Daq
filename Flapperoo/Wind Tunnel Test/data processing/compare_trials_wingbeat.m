% Ronan Gissler June 2023
clear
close all

restoredefaultpath
addpath general
addpath process_trial
addpath process_trial\functions
addpath plotting
addpath plotting\general\
addpath robot_parameters\

% -----------------------------------------------------------------
% The parameter combinations for which you'd like to see the data
% -----------------------------------------------------------------
wing_freq_sel = [2,3,4,5];
AoA_sel = [0];
wind_speed_sel = [4];
type_sel = "blue wings";

% path to folder where all processed data (.mat files) are stored
processed_data_path = "../processed data/";

% -----------------------------------------------------------------

% Put all our selected variables into a struct called selected_vars
selected_vars.AoA = AoA_sel;
selected_vars.freq = wing_freq_sel;
selected_vars.wind = wind_speed_sel;
selected_vars.type = type_sel;

% subtraction_string = "blue wings with tail 0deg";
sub_strings = ["no wings"];

norm_bool = true;
shift_bool = true;
forceIndex = 0;

% Produce overlay plots comparing the different cases
% main_title = "Force Transducer Measurement for " + wind_speed_sel + " m/s " + AoA_sel + " deg " + wing_freq_sel + " Hz ";
main_title = "Force Transducer Measurement for " + type_sel;
sub_title = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged";
% plot_forces_mult(processed_data_path, cases, main_title, sub_title);

[frames_padded, avg_forces, err_forces, names, sub_title, norm_factors_arr] = ...
    get_data_wingbeat(selected_vars, processed_data_path, norm_bool, sub_strings, shift_bool);

plot_data_wingbeat(selected_vars, frames_padded, avg_forces, err_forces,...
    names, sub_title, norm_bool, forceIndex, shift_bool)

% plot_forces_mult_subset(processed_data_path, cases, main_title, sub_title, sub_strings);