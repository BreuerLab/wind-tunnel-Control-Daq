% Author: Ronan Gissler
% Last updated: October 2023
clear
close all
addpath 'process trial'
addpath 'process trial/functions'
addpath 'plotting'

% -----------------------------------------------------------------
% ----The parameter combinations you want to see the data for------
% -----------------------------------------------------------------
type_sel = ["mechanism pause 25"];
AoA_sel = -14:2:14;

% With the experiments that were run on 10_12_2023 these are the options:
% wing_freq_sel - 0, 3, 5, 6
% wind_speed_sel - 0, 4, 8
% type_sel - "small blue", "small blue flap", "big blue"
% AoA_sel = [-10, -4, 0, 4, 10] or [-14, -10, -6, -2, 0, 2, 6, 10, 14]
% Note that not all combination of these variables were recorded, examine
% the raw data folder to see what data is actually available.

% To see the high speed static aerodynamics, try this:
% wing_freq_sel = [0];
% wind_speed_sel = [8];
% type_sel = ["small blue"];
% AoA_sel = [-14, -10, -6, -2, 0, 2, 6, 10, 14];

% path to folder where all processed data (.mat files) are stored
processed_data_path = "../taring_v3/processed data/";

% Put all our selected variables into a struct called selected_vars
selected_vars.AoA = AoA_sel;
selected_vars.type = type_sel;

[avg_forces, err_forces, names, sub_title] = get_data_AoA_tare(selected_vars, processed_data_path);

plot_forces_AoA_tare(AoA_sel, avg_forces, err_forces, names, sub_title);