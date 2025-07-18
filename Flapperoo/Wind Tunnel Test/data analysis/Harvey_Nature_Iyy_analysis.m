clear
close all

filepath = "C:\Users\rgissler\Documents\Harvey_Nature_2022_Iyy_Data\";

% Get conversion from short bird name to common bird name
filename = "Other\2021_09_02_allspecimen_birdinfo.csv";
gen_data = readtable(filepath + filename);

species_short = gen_data.species;
species_common = gen_data.species_fullname;
wingspans = gen_data.wing_span_cm;
y_loc_wing = gen_data.y_loc_humeral_insert;
% missing chord, wingbeat frequency, wind speed, wingbeat amplitude
% could sorta get chord from wing_s in individual files
% just going to assume amplitude of 30 degrees

filePattern = fullfile(filepath, '*.csv');
theFiles = dir(filePattern);

pitch_inertias = zeros(size(theFiles));
wing_areas = zeros(size(theFiles));
COM_x_vals = zeros(size(theFiles));
for i = 1:length(theFiles)
    baseFileName = convertCharsToStrings(theFiles(i).name);
    data = readtable(filepath + baseFileName);
    pitch_inertias(i) = max(data.full_Iyy);
    wing_areas(i) = max(data.wing_S);
    COM_x_vals(i) = -max(data.full_CGx);
    % origin is at the humeral head
    % SHOULD I USE MEAN INSTEAD OF MAX
end

% Viscor and Fuster 1987
% Have info on body weight, body length, wing area, wing spread, wing
% length, wingbeat frequency

% Greenewalt 1962
% Has some data on wingbeat frequency, many old style graphs, are values
% tabulated?

% Groom 2017
% For hovering hummingbirds

% Berg and Rayner 1995 - A GOOD PAPER TO READ IN GENERAL
% moment of inertia of wings, wing length, wing span, wing area, wing mass,
% body mass, wingbeat frequency

% Pennycuick 2001
% air speed, wingbeat frequency, wing span, wing area, body mass
% glaucous_winged_gull mass and wingspan appears to match fairly well with
% herring gull but no perfect matches

% Pennycuick 1996
% mass, span, area, frequency, airspeed but again no perfect matches with
% species

% Pennycuick 1989
% mass, span, area, frequency, airspeed; matches include:
% great blue heron, northern flicker

colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [0.9290 0.6940 0.1250];...
          [0.4940 0.1840 0.5560]; [0.4660 0.6740 0.1880]; [0.3010 0.7450 0.9330]];

norm = false;
if norm
    x_lab = "Like St";
else
    x_lab = "Wingbeat Frequency f (Hz)";
end

figure
ax1 = gca;
hold on
xlabel(x_lab)
ylabel("Natural Frequency \omega_n (Hz)")
title("Short Period Mode")
set(gca, FontSize=14)
legend()

figure
ax2 = gca;
hold on
xlabel(x_lab)
ylabel("f / \omega_n (Hz)")
title("Short Period Mode")
set(gca, FontSize=14)
legend()

num_birds = 3;
plot_I = zeros(1, num_birds);
plot_R = zeros(1, num_birds);
plot_L = zeros(1, num_birds);

% Pennycuick 1968
bird_name = "Pigeon";
amp = deg2rad(180/2); % sweep angle / 2
freq = 5.5; % Hz, rough guess based on frequency variation vs windspeed
% range of 5.2 to 6.2 Hz
speed = 13; % m/s, range of 8 - 18
pigeon_idx = 16;
disp(species_common(pigeon_idx))
I = pitch_inertias(pigeon_idx); % kg * m^2, units assumed since max(pitch_inertias) comparable to ibis
R = wingspans(pigeon_idx) / 2; % meters
L = R - y_loc_wing(pigeon_idx); % meters
chord = wing_areas(pigeon_idx) / R;
COM_x = COM_x_vals(pigeon_idx);
disp(wingspans(pigeon_idx) / chord) % this AR seems too high

freq_list = 5.2:0.1:6.2;
cur_bird_idx = 1;

calc_nat_freq(L, R, chord, amp, freq_list, speed, I, COM_x, ax1, ax2, bird_name, colors(cur_bird_idx,:), norm)

plot_I(cur_bird_idx) = I;
plot_R(cur_bird_idx) = R;
plot_L(cur_bird_idx) = L;

% Pennycuick 1989
bird_name = "Northern Flicker";
amp = deg2rad(60);
% span from pennycuick 0.510 m, area 0.0478 m^2
% span close to harvey data, but wing area is not
freq = 9.2; % +/- 0.8
speed = 12.7; % +/- 1.9
flicker_idx = 14;
disp(species_common(flicker_idx))
I = pitch_inertias(flicker_idx); % kg * m^2
R = wingspans(flicker_idx) / 2; % meters
L = R - y_loc_wing(flicker_idx); % meters
chord = wing_areas(flicker_idx) / wingspans(flicker_idx);
COM_x = COM_x_vals(flicker_idx);
disp(wingspans(flicker_idx) / chord) % this AR seems too high

freq_list = 8.4:0.1:10;
cur_bird_idx = 2;

calc_nat_freq(L, R, chord, amp, freq_list, speed, I, COM_x, ax1, ax2, bird_name, colors(cur_bird_idx,:), norm)

plot_I(cur_bird_idx) = I;
plot_R(cur_bird_idx) = R;
plot_L(cur_bird_idx) = L;

% Pennycuick 1989
bird_name = "Great Blue Heron";
amp = deg2rad(60);
% span from pennycuick 1.76 m, area 0.419 m^2
% again, span is clsoe, but wing area is substantiall different, roughly
% halve, is wing area only area for a single wing for Harvey?
freq = 2.55; % +/- 0.11
speed = 9.4; % +/- 1.6
heron_idx = 8;
disp(species_common(heron_idx))
I = pitch_inertias(heron_idx); % kg * m^2
R = wingspans(heron_idx) / 2; % meters
L = R - y_loc_wing(heron_idx); % meters
chord = wing_areas(heron_idx) / wingspans(heron_idx);
COM_x = COM_x_vals(heron_idx);
disp(wingspans(heron_idx) / chord) % this AR seems too high

freq_list = 2.4:0.1:2.7;
cur_bird_idx = 3;

calc_nat_freq(L, R, chord, amp, freq_list, speed, I, COM_x, ax1, ax2, bird_name, colors(cur_bird_idx,:), norm)

plot_I(cur_bird_idx) = I;
plot_R(cur_bird_idx) = R;
plot_L(cur_bird_idx) = L;

% Ducci 2021
% Parameters for Ibis
% mass 1.2 kg
bird_name = "Ibis";
I = 0.1; % I_y, pitching moment of inertia 0.1 kg * m^2
span = 1.35; % wingspan
chord = 0.15; % mean chord
l_a = 0.134; % arm bone length
l_f = 0.162; % forearm bone length
l_h = 0.084; % hand bone length
l_p3 = 0.25; % primary feather 3 length
L = l_a + l_f + l_h + l_p3;
R = span/2;
amp = deg2rad(42); % wingbeat amplitude
freq = 4; % wingbeat frequency, Hz
speed = 16.5; % m/s, from equilibrium flight condition

% MISSING COM!! They seem to make it up in paper, default value of 5 cm

freq_list = 3.5:0.1:freq;
cur_bird_idx = 4;

% calc_nat_freq(L, R, chord, amp, freq_list, speed, I, ax1, ax2, bird_name, colors(cur_bird_idx,:), norm)

% plot_I(cur_bird_idx) = I;
% plot_R(cur_bird_idx) = R;
% plot_L(cur_bird_idx) = L;