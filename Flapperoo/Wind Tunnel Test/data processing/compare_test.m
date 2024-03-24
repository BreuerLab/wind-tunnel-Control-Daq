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
wing_freq_sel = [0,3,5];
wind_speed_sel = [4];
type_sel = ["blue wings with tail"];
AoA_sel = -10:1:10;
% AoA_sel = -2:2:2;

% path to folder where all processed data (.mat files) are stored
processed_data_path = "../processed data/";

% select_type_UI(processed_data_path)

bool.norm = false;
bool.body_sub = true;

% Put all our selected variables into a struct called selected_vars
selected_vars.AoA = AoA_sel;

for n = 1:length(type_sel)
for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
    selected_vars.freq = wing_freq_sel(j);
    selected_vars.wind = wind_speed_sel(m);
    selected_vars.type = type_sel(n);
    [avg_forces, err_forces, names, sub_title] = get_data_AoA(selected_vars, processed_data_path, bool);

    AC_pos = findAC(avg_forces, AoA_sel);

    [low_pos, high_pos] = findCOMrange(avg_forces, AoA_sel);
end
end
end

% shift_distance = -1;
% avg_forces = shiftPitchMom(avg_forces, AoA_sel, shift_distance);

% forceIndex = 5;
% plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, bool.norm, forceIndex);