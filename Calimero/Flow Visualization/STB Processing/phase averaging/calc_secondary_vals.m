function calc_secondary_vals(D, turbine_bool, plot_bool, save_filepath_local)
tic
% Spatial resolution
dx = abs(D.x(2,1,1) - D.x(1,1,1));
dy = abs(D.y(1,2,1) - D.y(1,1,1));
dz = abs(D.z(1,1,2) - D.z(1,1,1));

% Replace NaNs with zeros, otherwise Q iso surfaces are holey
% u_phase_avg = S.u_phase_avg;
% u_phase_avg(isnan(u_phase_avg)) = 0;
% 
% v_phase_avg = S.v_phase_avg;
% v_phase_avg(isnan(v_phase_avg)) = 0;
% 
% w_phase_avg = S.w_phase_avg;
% w_phase_avg(isnan(w_phase_avg)) = 0;

% Compute Q-Criterion
[Qx,Qy,Qz,Q] = calQlate3D(D.u_phase_avg, D.v_phase_avg, D.w_phase_avg, dx,dy,dz);
S.Qx = Qx; S.Qy = Qy; S.Qz = Qz; S.Q = Q;

num_bins = D.num_bins;
speed = D.U_act * D.U;
[~, ~, freq] = parse_name(D.PIV_case_name);
dt = 1 / (freq * num_bins);
x_conv = zeros(1, num_bins);
for k = 1:num_bins
    x_conv(k) =  speed * dt * (k - 1);
end

% ------------------------------------------------------------
% Trim velocity field before calculating integral quantities
% -------------------------------------------------------------
y = D.y;
z = D.z;
u_tr = D.u_phase_avg;
v_tr = D.v_phase_avg;
w_tr = D.w_phase_avg;

vortX_tr = D.vortX_phase_avg;
vortY_tr = D.vortY_phase_avg;
vortZ_tr = D.vortZ_phase_avg;

unc_tr = D.uncTot_phase_avg;
numP_tr = D.numP_phase_avg;
hel_tr = D.hel_phase_avg;

[y_tr, z_tr, u_tr] = trim_vel_field(y, z, u_tr);
[~, ~, v_tr] = trim_vel_field(y, z, v_tr);
[~, ~, w_tr] = trim_vel_field(y, z, w_tr);
[~, ~, vortX_tr] = trim_vel_field(y, z, vortX_tr);
[~, ~, vortY_tr] = trim_vel_field(y, z, vortY_tr);
[~, ~, vortZ_tr] = trim_vel_field(y, z, vortZ_tr);
[~, ~, unc_tr] = trim_vel_field(y, z, unc_tr);
[~, ~, Utot_tr] = trim_vel_field(y, z, D.Utot_phase_avg);
[~, ~, Utot_diff_tr] = trim_vel_field(y, z, D.Utot_diff_phase_avg);
[~, ~, vortTot_tr] = trim_vel_field(y, z, D.vortTot_phase_avg);
[~, ~, numP_tr] = trim_vel_field(y, z, numP_tr);
[~, ~, hel_tr] = trim_vel_field(y, z, hel_tr);

% Replace nans in velocity field with median values so integral
% calculations aren't skewed
u_tr = nanToMedian(u_tr);
v_tr = nanToMedian(v_tr);
w_tr = nanToMedian(w_tr);

F.x = x_conv; F.y = y_tr; F.z = z_tr;
F.u = u_tr; F.v = v_tr; F.w = w_tr;
F.vortX = vortX_tr; F.vortY = vortY_tr; F.vortZ = vortZ_tr;
F.unc = unc_tr;

% Calculate lift and drag from wake
avg_type = 1;
[lift_vel, drag_vel] = get_wake_lift(speed, D.L, F, avg_type, false, D.rho_act);
[lift, drag] = get_wake_lift(speed, D.L, F, avg_type, true, D.rho_act);
S.lift = lift; S.drag = drag; S.lift_vel = lift_vel; S.drag_vel = drag_vel;

% Calculate extrapolated field using Helmholtz decomposition
y_arr = squeeze(y_tr(:,1));
z_arr = squeeze(z_tr(1,:));
[y_B, z_B, velX_B, velY_B, velZ_B] = helm_decomp(x_conv, y_arr, z_arr, D.L, F);
S.y_B = y_B; S.z_B = z_B; S.velX_B = velX_B; S.velY_B = velY_B; S.velZ_B = velZ_B;

% Total KE including freestream KE
KE_field = Utot_tr.^2;
KE = trapz(y_arr, KE_field, 1);
KE = trapz(z_arr, KE, 2);
KE = squeeze(KE);

% Calculated using streamwise speed with freestream speed subtracted,
% represents KE introduced by disturbance of flapper
KE_diff_field = Utot_diff_tr.^2;
KE_diff = trapz(y_arr, KE_diff_field, 1);
KE_diff = trapz(z_arr, KE_diff, 2);
KE_diff = squeeze(KE_diff);

% Calculate power
power_field = KE_diff_field .* -u_tr; % remove +1 next to u_tr
% negative sign added since -1.1 velocity means power added, acceleration
power = trapz(y_arr, power_field, 1);
power = trapz(z_arr, power, 2);
power = squeeze(power);

Utot_full = velX_B.^2 + velY_B.^2 + velZ_B.^2;
KE_tot_field = permute(Utot_full,[2 3 1]);
KE_tot = trapz(squeeze(y_B(:,1)), KE_tot_field, 1);
KE_tot = trapz(squeeze(z_B(1,:)), KE_tot, 2);
KE_tot = squeeze(KE_tot);

enst_field = vortTot_tr.^2;
enst = trapz(y_arr, enst_field, 1);
enst = trapz(z_arr, enst, 2);
enst = squeeze(enst);

div_field = D.dudx_phase_avg + D.dvdy_phase_avg + D.dwdz_phase_avg;

S.KE = KE; S.KE_diff = KE_diff; S.KE_tot = KE_tot; S.enst = enst;
S.power = power; S.div = div_field;

% ----------------------------------------------------------------
% --------------------- PLANAR AVERAGES --------------------------
% ----------------------------------------------------------------
% These values are vectors with length equal to the number of bins

S.u_avg = mean(u_tr, [1, 2]);
S.v_avg = mean(v_tr, [1, 2]);
S.w_avg = mean(w_tr, [1, 2]);
S.vortX_avg = mean(vortX_tr, [1, 2]);
S.vortY_avg = mean(vortY_tr, [1, 2]);
S.vortZ_avg = mean(vortZ_tr, [1, 2]);
S.numP_avg = mean(numP_tr, [1, 2]);
S.unc_avg = mean(unc_tr, [1, 2]);
S.hel_avg = mean(hel_tr, [1, 2]);

% The average can also be calculated using the linear interpolation of
% trapz, this seems to be worse (more susceptible to noise)
% u_avg = trapz(y_arr, u_tr, 1);
% u_avg = trapz(z_arr, u_avg, 2);
% 
% Ly = y_arr(end) - y_arr(1);
% Lz = z_arr(end) - z_arr(1);
% 
% u_avg = squeeze(u_avg) / (Ly * Lz);

% ----------------------------------------------------------------
% -------------- Calculate values from DAQ data ------------------
% ----------------------------------------------------------------
if ~turbine_bool
    % Calculate phase averaged speed
    [norm_time_speed, phase_avg_pos, phase_std_pos,...
    phase_avg_speed, phase_std_speed, phase_avg_acc, phase_std_acc,...
    phase_avg_wing_pos, phase_std_wing_pos,...
    phase_avg_wing_speed, phase_std_wing_speed, phase_avg_wing_acc, phase_std_wing_acc,...
    bin_count_speed, bin_std_speed, phase_avg_volt, phase_std_volt,...
    phase_avg_cur, phase_std_cur] = speed_phase_avg(D.PIV_case_name, plot_bool);

    % Add data to a struct
    S.norm_time_speed = norm_time_speed;
    S.phase_avg_pos = phase_avg_pos; S.phase_std_pos = phase_std_pos;
    S.phase_avg_speed = phase_avg_speed; S.phase_std_speed = phase_std_speed;
    S.phase_avg_acc = phase_avg_acc; S.phase_std_acc = phase_std_acc;
    
    S.phase_avg_wing_pos = phase_avg_wing_pos; S.phase_std_wing_pos = phase_std_wing_pos;
    S.phase_avg_wing_speed = phase_avg_wing_speed; S.phase_std_wing_speed = phase_std_wing_speed;
    S.phase_avg_wing_acc = phase_avg_wing_acc; S.phase_std_wing_acc = phase_std_wing_acc;
    S.bin_count_speed = bin_count_speed; S.bin_std_speed = bin_std_speed;

    S.phase_avg_volt = phase_avg_volt; S.phase_std_volt = phase_std_volt;
    S.phase_avg_cur = phase_avg_cur; S.phase_std_cur = phase_std_cur;
    S.phase_avg_power = phase_avg_volt .* phase_avg_cur;
end

% Save the entire structure
save_filename = D.PIV_case_name + "_phase_avg_integral.mat";
save_path = fullfile(save_filepath_local, save_filename);
disp("Saving data to: " + save_path)
save(save_path, '-struct', 'S');

fprintf('Secondary file: Processing and saving data took %.4f seconds.\n', toc);
end