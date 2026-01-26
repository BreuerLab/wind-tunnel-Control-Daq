close
clear all

%% ----------------Model Parameters-------------------
wing_freq = 3; % Hz
wind_speed = 4; % m/s
wing_length = 0.25;
arm_length = 0.06;
amp_flapping = pi/3; % amplitude of flapping motion
% amp_vals_pitching = linspace(0, pi/3, 5); % amplitude of pitching motion
% amp_pitching = pi/6;
amp_pitching = 0;
phase_pitching_vals = -linspace(0, pi/2, 4);

lift_slope = 6;
zero_lift_alpha = 0;

figure
hold on
legend()
for j = 1:length(phase_pitching_vals)

%% ----------Get kinematics for wing motion-----------
time = 0:0.001:1;
time = time' / wing_freq;

% amp_pitching = amp_vals_pitching(j);
phase_pitching = phase_pitching_vals(j);
AoA_static = deg2rad(10);
AoA = amp_pitching.*cos(2*pi*wing_freq.*time + phase_pitching) + AoA_static;
AoA = rad2deg(AoA);

ang_disp = amp_flapping.*cos(2*pi*wing_freq.*time);
ang_vel = -2*pi*wing_freq*amp_flapping.*sin(2*pi*wing_freq.*time);
ang_acc = -4* pi^2 * wing_freq^2 * amp_flapping .* cos(2*pi*wing_freq.*time);

ang_disp = rad2deg(ang_disp);
ang_vel = rad2deg(ang_vel);
ang_acc = rad2deg(ang_acc);

factor = 0.5;
wing_length_mod = (wing_length * factor)*cos(2*pi*wing_freq.*time - pi/2) + wing_length*(1 - factor);
% wing_length_mod = wing_length * ones(size(time));
full_length_mod = wing_length_mod + arm_length;

full_length = wing_length + arm_length;
dr = 0.001;
num_pts = length(arm_length:dr:full_length);

for i = 1:length(time)
    r = linspace(arm_length, full_length_mod(i), num_pts);
    lin_vel(i,:) = deg2rad(ang_vel(i)) .* r;
    lin_acc(i,:) = deg2rad(ang_acc(i)) .* r;
end

%% Calculate aerodynamic variables

[eff_AoA, u_rel] = get_eff_wind_mod(time, lin_vel, AoA, wind_speed);

C_L_r = lift_slope*deg2rad(eff_AoA - zero_lift_alpha) .* (u_rel / wind_speed).^2 .* cosd(ang_disp);
C_L = trapz(dr, C_L_r, 2) / wing_length;

% plot(time, C_L, DisplayName="\theta = " + amp_pitching)
% disp("\theta = " + amp_pitching + ", avg lift = " + mean(C_L))
plot(time, C_L, DisplayName="\xi = " + phase_pitching)
disp("\xi = " + phase_pitching + ", avg lift = " + mean(C_L))

end
