function S = phase_avg_STB(file_path, nondim_bool, U, L, save_filepath_local, PIV_case_name, turbine_bool, plot_bool, RPCA_bool)
tic

num_images = 2500;
disp("Assuming num images = " + num_images)
% get bin number associated with each frame from DAQ measurements
[norm_frame_pos, tick_frame_pos, bin_ind_arr, num_bins, full_cycle, cycle_freq]...
    = frame_to_bin(PIV_case_name, num_images, turbine_bool, plot_bool);

bin_count = zeros(1,num_bins);
bin_std = zeros(1,num_bins);

% Define the field names we want to average (must be same order as
% import_STB)
fields = {'u', 'v', 'w', 'Utot', 'vortX', 'vortY', 'vortZ', 'vortTot', 'uncU', 'uncV', 'uncW', 'uncTot', 'hel'};

for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    % bin_indices_all{i} = bin_indices;
    bin_count(i) = length(bin_indices);
    bin_std(i) = std(norm_frame_pos(bin_indices))*100;

    % Import data (using a temporary struct or list)
    [x, y, z, data{1:13}] = import_STB_data(file_path, nondim_bool, U, L, bin_indices, RPCA_bool);
        
    if i == 1
        % Initialize structure with zeros based on first file size
        for f = 1:length(fields)
            S.([fields{f} '_phase_avg']) = zeros(size(x,1), size(x,2), size(x,3), num_bins);
        end
    end


    for f = 1:length(fields)
        fname = [fields{f}, '_phase_avg'];
        % Compute mean along the 4th dimension
        S.(fname)(:,:,:,i) = mean(data{f}, 4);
    end


    if mod(i,5) == 0
        disp(['processed ',num2str(i),'/',num2str(num_bins)])
    end
end

% Spatial resolution
dx = abs(x(2,1,1) - x(1,1,1));
dy = abs(y(1,2,1) - y(1,1,1));
dz = abs(z(1,1,2) - z(1,1,1));

% Compute Q-Criterion
[Qx,Qy,Qz,Q] = calQlate3D(S.u_phase_avg, S.v_phase_avg, S.w_phase_avg,dx,dy,dz);
S.Qx = Qx; S.Qy = Qy; S.Qz = Qz; S.Q = Q;

% Compute integral quanitites: lift, drag, KE, enstrophy, conv_U
avg_type = 1;
y_cen = -0.142 / L;
z_cen = -0.03 / L;

if avg_type == 0
    speed = d.U;
    density = 1.225;
else
    % Find matching DAQ file
    [daq_data_filename, daq_data_path] = get_daq_paths(PIV_case_name);

    WT_d = get_wind_tunnel_data(daq_data_filename);
    speed = WT_d.Speed_m_s_;
    density = WT_d.Density_kg_m3_;
    % density = 1.225;
end

if avg_type ~= 0
    [~, ~, freq] = parse_name(case_name);
    num_bins = size(d.u_phase_avg,4);
    dt = 1 / (freq * num_bins);
    x = zeros(1, num_bins);
    for k = 1:num_bins
        x(k) =  speed * dt * (k - 1);
    end
else
    x = 0;
end

[lift_vel, drag_vel] = get_wake_lift(speed, L, x, y, z, S, avg_type, false, y_cen, z_cen, density);
[lift, drag] = get_wake_lift(speed, L, x, y, z, S, avg_type, true, y_cen, z_cen, density);

x_ind = 3;

y_arr = squeeze(y(x_ind,:,1));
z_arr = squeeze(z(x_ind,1,:));

KE_field = squeeze(S.Utot_phase_avg(x_ind,:,:,:)).^2;
KE = trapz(y_arr, KE_field, 1); % WHAT DIMENSION SHOULD THIS BE?
KE = trapz(z_arr, KE, 2);
KE = squeeze(KE);

enst_field = squeeze(S.vortTot_phase_avg(x_ind,:,:,:)).^2;
enst = trapz(y_arr, enst_field, 1);
enst = trapz(z_arr, enst, 2);
enst = squeeze(enst);

u_avg = trapz(y_arr, squeeze(S.u_phase_avg(x_ind,:,:,:)), 1);
u_avg = trapz(z_arr, u_avg, 2);

Ly = y_arr(end) - y_arr(1);
Lz = z_arr(end) - z_arr(1);

u_avg = squeeze(u_avg) / (Ly * Lz);

% Add metadata to the struct
S.x = x; S.y = y; S.z = z; S.L = L; S.U = U; S.cycle_freq = cycle_freq;
S.num_bins = num_bins; S.tick_frame_pos = tick_frame_pos; S.full_cycle = full_cycle;
S.bin_ind_arr = bin_ind_arr; S.bin_count = bin_count; S.bin_std = bin_std;
S.PIV_case_name = PIV_case_name;
S.lift = lift; S.drag = drag; S.lift_vel = lift_vel; S.drag_vel = drag_vel;
S.KE = KE; S.enst = enst; S.u_avg = u_avg;

if ~turbine_bool
    % Calculate phase averaged speed
    [norm_time_speed, phase_avg_speed, phase_std_speed, bin_count_speed, bin_std_speed,...
     phase_avg_volt, phase_std_volt, phase_avg_cur, phase_std_cur] = speed_phase_avg(PIV_case_name, plot_bool);

    S.norm_time_speed = norm_time_speed; S.phase_avg_speed = phase_avg_speed;
    S.phase_std_speed = phase_std_speed; S.bin_count_speed = bin_count_speed;
    S.bin_std_speed = bin_std_speed;

    S.phase_avg_volt = phase_avg_volt; S.phase_std_volt = phase_std_volt;
    S.phase_avg_cur = phase_avg_cur; S.phase_std_cur = phase_std_cur;
end

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