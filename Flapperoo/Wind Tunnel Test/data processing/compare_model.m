clear
close all

addpath plotting
addpath general
addpath robot_parameters
addpath modeling
% addpath \process_trial\functions\

wing_freq_sel = [0, 0.1, 2, 2.5, 3, 3.5, 3.75, 4, 4.5, 5];
wind_speed_sel = [3,4,5,6];
AoA_sel = [-16:1.5:-13 -12:1:-9 -8:0.5:8 9:1:12 13:1.5:16];
% norm_bool = true;

C_L_vals = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel));
C_D_vals = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel));
C_N_vals = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel));
C_M_vals = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel));
aero_vals = zeros(6, length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel));
u_eff_vals = zeros(length(AoA_sel),length(wing_freq_sel),length(wind_speed_sel));

for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
for k = 1:length(AoA_sel)

AoA = AoA_sel(k);
freq = wing_freq_sel(j);
speed = wind_speed_sel(m);

case_name = speed + "m/s " + freq + "Hz " + AoA + "deg";

[time, ang_disp, ang_vel, ang_acc] = get_kinematics(freq, true);

[center_to_LE, chord, COM_span, ...
    wing_length, arm_length] = getWingMeasurements();

full_length = wing_length + arm_length;
r = arm_length:0.001:full_length;
lin_vel = deg2rad(ang_vel) * r;

[eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, speed);

thinAirfoil = true;
[C_L, C_D, C_N, C_M] = get_aero(eff_AoA, u_rel, speed, wing_length, thinAirfoil);

C_L_vals(k,j,m) = mean(C_L);
C_D_vals(k,j,m) = mean(C_D);
C_N_vals(k,j,m) = mean(C_N);
C_M_vals(k,j,m) = mean(C_M);

u_eff_vals(k,j,m) = mean(u_rel,'all');
% Do I need to do something like below? I don't think so....
% AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type
end
end
end

aero_vals(1,:,:,:) = C_D_vals;
aero_vals(3,:,:,:) = C_L_vals;
aero_vals(5,:,:,:) = C_M_vals;

filename = "model_higherAR.mat";
% aero_vars = {"C_L_vals", "C_D_vals", "C_M_vals"};
save(filename, "aero_vals", "u_eff_vals")

% Test plot to make sure working as expected
% figure
% hold on
% for j = 1:length(wing_freq_sel)
% for m = 1:length(wind_speed_sel)
%     model = plot(AoA_sel, C_L_vals(:, j, m));
%     model.HandleVisibility = "off";
%     % model.DisplayName = "Model: " + wing_freq_sel(j) + "Hz";
%     % model.Color = colors(j,:,m);
%     model.LineStyle = "--";
%     model.LineWidth = 2;
% end
% end