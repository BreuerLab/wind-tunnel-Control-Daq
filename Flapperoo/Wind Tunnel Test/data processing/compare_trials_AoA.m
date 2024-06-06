% Author: Ronan Gissler
% Last updated: October 2023
clear
close all
addpath 'general'
addpath 'process_trial'
addpath 'process_trial/functions'
addpath robot_parameters\
addpath 'plotting'

% -----------------------------------------------------------------
% ----The parameter combinations you want to see the data for------
% -----------------------------------------------------------------
% wing_freq_sel = [0];
% wind_speed_sel = [0,2,4,6];
% type_sel = ["tubespars v2"];
% AoA_sel = -16:2:16;

freq_speed_combos = [2, 4; 3, 6; 0, 4; 0, 6];

% 0,2,3,4,5  4; 0,3,4  6;

wing_freq_sel = [0];
wind_speed_sel = [2,4,6];
type_sel = ["blue wings with tail"];
% type_sel = ["no wings with tail"];
% AoA_sel = -10:1:10;
AoA_sel = -16:1:16;
% AoA_sel = [-8, -7, -6, -5, -4, -3, -2, 0, 1, 2, 3, 4, 5, 6, 7, 8];
sub_strings = ["no wings with tail"];

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
processed_data_path = "../processed data/";

% select_type_UI(processed_data_path)

norm_bool = true;
shift_bool = true;
regress_bool = true;

% Put all our selected variables into a struct called selected_vars
selected_vars.AoA = AoA_sel;
selected_vars.freq = wing_freq_sel;
selected_vars.wind = wind_speed_sel;
selected_vars.type = type_sel;

% forceIndex = 5;

[avg_forces, err_forces, names, sub_title, norm_factors] = ...
    get_data_AoA(selected_vars, processed_data_path, norm_bool, sub_strings, shift_bool);

% pitch_moment_LE = zeros(size(squeeze(avg_forces(1,:,:,:,:))));
% for i = 1:length(AoA_sel)
%     drag_force = squeeze(avg_forces(1,i,:,:,:));
%     lift_force = squeeze(avg_forces(3,i,:,:,:));
%     pitch_moment = squeeze(avg_forces(5,i,:,:,:));
% 
%     normal_force = lift_force*cosd(AoA_sel(i)) + drag_force*sind(AoA_sel(i));
% 
%     [center_to_LE, chord] = getWingMeasurements();
%     shift_distance = -center_to_LE;
% 
%     % Shift pitch moment
%     pitch_moment_LE(i,:,:,:) = pitch_moment + normal_force * shift_distance;
% end
% 
% shifted_avg_forces = avg_forces;
% shifted_avg_forces(5,:,:) = pitch_moment_LE;

% figure
% hold on
% scatter(AoA_sel, avg_forces(3,:,:,:,:), 40,'filled',DisplayName="0 Hz Data")
% xlabel("Angle of Attack (deg)")
% ylabel("Lift Coefficient")
% title(type_sel + " " + wind_speed_sel + " m/s " + wing_freq_sel + " Hz")

% figure
% hold on
% plot(AoA_sel(1:7), COP(1:7), Color=[0, 0.4470, 0.7410])
% plot(AoA_sel(11:end), COP(11:end), Color=[0, 0.4470, 0.7410])
% % plot(AoA_sel, COP)
% plot(AoA_sel, 25*ones(1,length(AoA_sel)), 'k--')
% hold off
% xlabel("Angle of Attack (deg)")
% ylabel("Center of Pressure Location (% Chord)")
% title(type_sel + " " + wind_speed_sel + " m/s " + wing_freq_sel + " Hz")

% [NP_pos, NP_mom] = findNP(avg_forces, AoA_sel, true, sub_title);

% [distance_vals_chord, slopes] = findCOMrange(avg_forces, AoA_sel, true);

plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, norm_bool, 1, regress_bool, shift_bool);
plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, norm_bool, 3, regress_bool, shift_bool);
plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, norm_bool, 5, regress_bool, shift_bool);

% plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, norm_bool, 2);
% plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, norm_bool, 4);
% plot_forces_AoA(selected_vars, avg_forces, err_forces, names, sub_title, norm_bool, 6);

% [avg_forces, err_forces, names, sub_title] = get_data_AoA_combo(freq_speed_combos, selected_vars, processed_data_path, bool);
% 
% plot_forces_AoA_combo(freq_speed_combos, selected_vars, avg_forces, err_forces, names, sub_title, bool.norm, forceIndex);

% pitchMom = [];
% AoA = [];
% freq = [];
% for j=1:3
%     pitchMom = [pitchMom avg_forces(5, :, j, 1, 1)];
%     AoA = [AoA AoA_sel];
%     freq = [freq wing_freq_sel(j)*ones(1,length(AoA_sel))];
% end
% [h,atab,ctab,stats] = aoctool(AoA, pitchMom, freq);