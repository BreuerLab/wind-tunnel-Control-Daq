function S = phase_avg_STB(file_path, nondim_bool, U, L, save_filepath_local, PIV_case_name, turbine_bool, plot_bool, RPCA_bool)
tic

num_images = 2500;
disp("Assuming num images = " + num_images)
% get bin number associated with each frame from DAQ measurements
[norm_frame_pos, tick_frame_pos, bin_ind_arr, num_bins, full_cycle, cycle_freq]...
    = frame_to_bin(PIV_case_name, num_images, turbine_bool, plot_bool);


% Find matching DAQ file
[daq_data_filename, ~] = get_daq_paths(PIV_case_name);

% Get AFAM parameters associated with that trial
WT_d = get_wind_tunnel_data(daq_data_filename);
speed = WT_d.Speed_m_s_;
density = WT_d.Density_kg_m3_;

bin_count = zeros(1,num_bins);
bin_std = zeros(1,num_bins);
lift_phase_avg = zeros(1,num_bins);
drag_phase_avg = zeros(1,num_bins);

% Define the field names we want to average (must be same order as
% import_STB)
fields = {'u', 'v', 'w', 'Utot', 'vortX', 'vortY', 'vortZ', 'vortTot', 'uncU', 'uncV', 'uncW', 'uncTot', 'hel', 'numP',...
        'dudx', 'dudy', 'dudz', 'dvdx', 'dvdy', 'dvdz', 'dwdx', 'dwdy', 'dwdz', 'Utot_diff'};

for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    % bin_indices_all{i} = bin_indices;
    bin_count(i) = length(bin_indices);
    bin_std(i) = std(norm_frame_pos(bin_indices))*100;

    % Import data (using a temporary struct or list)
    [x, y, z, data{1:length(fields)}] = ...
        import_STB_data(file_path, nondim_bool, U, L, bin_indices, RPCA_bool);

    avg_type = 2;

    x_conv = 0;

    u_tr = data{1}; v_tr = data{2}; w_tr = data{3};
    vortX_tr = data{5}; vortY_tr = data{6}; vortZ_tr = data{7};
    unc_tr = data{12};

    [y_tr, z_tr, u_tr] = trim_vel_field(y, z, u_tr);
    [~, ~, v_tr] = trim_vel_field(y, z, v_tr);
    [~, ~, w_tr] = trim_vel_field(y, z, w_tr);
    [~, ~, vortX_tr] = trim_vel_field(y, z, vortX_tr);
    [~, ~, vortY_tr] = trim_vel_field(y, z, vortY_tr);
    [~, ~, vortZ_tr] = trim_vel_field(y, z, vortZ_tr);
    [~, ~, unc_tr] = trim_vel_field(y, z, unc_tr);

    F.x = x_conv; F.y = y_tr; F.z = z_tr;
    F.u = u_tr; F.v = v_tr; F.w = w_tr;
    F.vortX = vortX_tr; F.vortY = vortY_tr; F.vortZ = vortZ_tr;
    F.unc = unc_tr;
    [lift_vals, drag_vals] = get_wake_lift(speed, L, F, avg_type, true, density);
        
    if i == 1
        % Initialize structure with zeros based on first file size
        for f = 1:length(fields)
            S.([fields{f} '_phase_avg']) = zeros(size(x,1), size(x,2), size(x,3), num_bins);
        end
    end


    for f = 1:length(fields)
        fname = [fields{f}, '_phase_avg'];
        % Compute mean along the 4th dimension
        S.(fname)(:,:,:,i) = mean(data{f}, 4, "omitnan");

        fname = [fields{f}, '_phase_std'];
        S.(fname)(:,:,:,i) = std(data{f}, 0, 4, "omitnan");

        lift_phase_avg(i) = mean(lift_vals.vortX);
        drag_phase_avg(i) = mean(drag_vals.tot);
    end


    if mod(i,5) == 0
        disp(['processed ',num2str(i),'/',num2str(num_bins)])
    end
end

% Spatial resolution
dx = abs(x(2,1,1) - x(1,1,1));
dy = abs(y(1,2,1) - y(1,1,1));
dz = abs(z(1,1,2) - z(1,1,1));

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
[Qx,Qy,Qz,Q] = calQlate3D(S.u_phase_avg, S.v_phase_avg, S.w_phase_avg, dx,dy,dz);
S.Qx = Qx; S.Qy = Qy; S.Qz = Qz; S.Q = Q;

if avg_type ~= 0
    [~, ~, freq] = parse_name(PIV_case_name);
    dt = 1 / (freq * num_bins);
    x_conv = zeros(1, num_bins);
    for k = 1:num_bins
        x_conv(k) =  speed * dt * (k - 1);
    end
else
    x_conv = 0;
end

% ------------------------------------------------------------
% Trim velocity field before calculating integral quantities
% -------------------------------------------------------------
u_tr = S.u_phase_avg;
v_tr = S.v_phase_avg;
w_tr = S.w_phase_avg;

vortX_tr = S.vortX_phase_avg;
vortY_tr = S.vortY_phase_avg;
vortZ_tr = S.vortZ_phase_avg;

unc_tr = S.uncTot_phase_avg;
numP_tr = S.numP_phase_avg;

[y_tr, z_tr, u_tr] = trim_vel_field(y, z, u_tr);
[~, ~, v_tr] = trim_vel_field(y, z, v_tr);
[~, ~, w_tr] = trim_vel_field(y, z, w_tr);
[~, ~, vortX_tr] = trim_vel_field(y, z, vortX_tr);
[~, ~, vortY_tr] = trim_vel_field(y, z, vortY_tr);
[~, ~, vortZ_tr] = trim_vel_field(y, z, vortZ_tr);
[~, ~, unc_tr] = trim_vel_field(y, z, unc_tr);
[~, ~, Utot_tr] = trim_vel_field(y, z, S.Utot_phase_avg);
[~, ~, Utot_diff_tr] = trim_vel_field(y, z, S.Utot_diff_phase_avg);
[~, ~, vortTot_tr] = trim_vel_field(y, z, S.vortTot_phase_avg);
[~, ~, numP_tr] = trim_vel_field(y, z, numP_tr);

% Replace nans in velocity field with median values so integral
% calculations aren't skewed
u_tr = nanToMedian(u_tr);
v_tr = nanToMedian(v_tr);
w_tr = nanToMedian(w_tr);

D.x = x_conv; D.y = y_tr; D.z = z_tr;
D.u = u_tr; D.v = v_tr; D.w = w_tr;
D.vortX = vortX_tr; D.vortY = vortY_tr; D.vortZ = vortZ_tr;
D.unc = unc_tr;

avg_type = 1;
[lift_vel, drag_vel] = get_wake_lift(speed, L, D, avg_type, false, density);
[lift, drag] = get_wake_lift(speed, L, D, avg_type, true, density);

y_arr = squeeze(y_tr(:,1));
z_arr = squeeze(z_tr(1,:));

[y_B, z_B, velX_B, velY_B, velZ_B] = helm_decomp(x_conv, y_arr, z_arr, L, D);

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
power_field = KE_diff_field .* -(u_tr + 1);
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

div_field = S.dudx_phase_avg + S.dvdy_phase_avg + S.dwdz_phase_avg;

% u_avg = trapz(y_arr, u_tr, 1);
% u_avg = trapz(z_arr, u_avg, 2);
% 
% Ly = y_arr(end) - y_arr(1);
% Lz = z_arr(end) - z_arr(1);
% 
% u_avg = squeeze(u_avg) / (Ly * Lz);

u_avg = mean(u_tr, [1, 2]);
numP_avg = mean(numP_tr, [1, 2]);
unc_avg = mean(unc_tr, [1, 2]);

% Add metadata to the struct
S.x = x; S.y = y; S.z = z; S.L = L; S.U = U; S.cycle_freq = cycle_freq;
S.num_bins = num_bins; S.tick_frame_pos = tick_frame_pos; S.full_cycle = full_cycle;
S.bin_ind_arr = bin_ind_arr; S.bin_count = bin_count; S.bin_std = bin_std;
S.PIV_case_name = PIV_case_name;
S.lift = lift; S.drag = drag; S.lift_vel = lift_vel; S.drag_vel = drag_vel;
S.lift_phase_avg = lift_phase_avg; S.drag_phase_avg = drag_phase_avg;
S.KE = KE; S.KE_diff = KE_diff; S.KE_tot = KE_tot; S.enst = enst; S.u_avg = u_avg;
S.y_B = y_B; S.z_B = z_B; S.velX_B = velX_B; S.velY_B = velY_B; S.velZ_B = velZ_B;
S.power = power; S.numP_avg = numP_avg; S.unc_avg = unc_avg;
S.div = div_field;

if ~turbine_bool
    % Calculate phase averaged speed
    [norm_time_speed, phase_avg_pos, phase_std_pos,...
    phase_avg_speed, phase_std_speed, phase_avg_acc, phase_std_acc,...
    phase_avg_wing_pos, phase_std_wing_pos,...
    phase_avg_wing_speed, phase_std_wing_speed, phase_avg_wing_acc, phase_std_wing_acc,...
    bin_count_speed, bin_std_speed, phase_avg_volt, phase_std_volt,...
    phase_avg_cur, phase_std_cur] = speed_phase_avg(PIV_case_name, plot_bool);

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

S.U_act = speed / U;
S.rho_act = density;

% Save the entire structure
if RPCA_bool
    save_filename = PIV_case_name + "_RPCA_phase_avg.mat";
else
    save_filename = PIV_case_name + "_phase_avg.mat";
end
save_path = fullfile(save_filepath_local, save_filename);
% _RPCA
disp("Saving data to: " + save_path)
save(save_path, '-struct', 'S');

fprintf('Processing and saving data took %.4f seconds.\n', toc);
end