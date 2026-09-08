function S = phase_avg_STB(file_path, U, L, save_filepath_local, PIV_case_name, bools)
tic

% Prepare path and name for file to be saved
if bools.RPCA
    save_filename = PIV_case_name + "_RPCA_phase_avg.mat";
else
    save_filename = PIV_case_name + "_phase_avg.mat";
end
if bools.proc_vel
    save_path = fullfile(save_filepath_local, save_filename);
else
    save_path = fullfile(save_filepath_local, "phase_avg/", save_filename);
end

[amp, ~, freq] = parse_name(PIV_case_name);

% ----------------------------------------------------------------
% -------- Calculate phase averaged kinematics and power ---------
% ----------------------------------------------------------------
if ~bools.turbine
[daq_data_filename, daq_data_path] = get_daq_paths(PIV_case_name);

% Get raw data from file
load([daq_data_path daq_data_filename]);

% no load cell mounted, so blank values used
offsets = zeros(1,size(results,2));
cal_mat = zeros(6,6);

ticksPerRev = 18432;
OC_pulse_step = 4;
pulsesPerRev = ticksPerRev / OC_pulse_step;
[~, ~, voltAdj, curAdj, home_signal, pos, speed, acc, wing_pos, wing_speed, wing_acc] = ...
    process_data(results, offsets, cal_mat, ticksPerRev, OC_pulse_step, amp, true);

% Define the field names in the order they are returned by the function
fNames = {'freq_avg', 'norm_time_speed', 'phase_avg_pos', 'phase_std_pos', ...
          'phase_avg_speed', 'phase_std_speed',...
          'phase_avg_acc', 'phase_std_acc',...
          'phase_avg_wing_pos', 'phase_std_wing_pos',...
          'phase_avg_wing_speed', 'phase_std_wing_speed',...
          'phase_avg_wing_acc', 'phase_std_wing_acc',...
          'bin_count_speed', 'bin_std_speed',...
          'phase_avg_volt', 'phase_std_volt',...
          'phase_avg_cur', 'phase_std_cur'};

% Capture all outputs into a cell array
outputs = cell(1, numel(fNames));
[outputs{:}] = speed_phase_avg(results, voltAdj, curAdj, pos, speed, acc,...
                wing_pos, wing_speed, wing_acc, pulsesPerRev, bools.plot);

% Map cell array to struct fields
for i = 1:numel(fNames)
    D.(fNames{i}) = outputs{i};
end

D.phase_avg_speed_error = abs(D.phase_avg_speed - freq);
D.phase_avg_power = D.phase_avg_volt .* D.phase_avg_cur;

% Brushed DC motor parameters
mot_R = 51.4; % Ohms
mot_L = 1.8e-3; % H
mot_k = 27.4e-3; % Nm/A, torque constant
gR = 9; % gear ratio
mot_eff = 0.81; % gearbox efficiency

% Estimate motor current from voltage data using motor model

% Estimate motor voltage from current data using motor model
dt = (1/freq) / length(D.phase_avg_cur);
mechTerm = mot_k*(D.phase_avg_speed*2*pi*gR); % Nm/A = V/(speed in rad/s)
resTerm = mot_R*(D.phase_avg_cur/1000);
indTerm = mot_L*gradient(D.phase_avg_cur/1000, dt);
D.phase_avg_volt_model = mechTerm + resTerm + indTerm;
% potentially a brush voltage drop term is missing

end

% ----------------------------------------------------------------
% ------------ Calculate phase averaged STB fields ---------------
% ----------------------------------------------------------------
if bools.proc_vel
num_images = 2500;
disp("-----------------------------------")
disp("Assuming num images = " + num_images)
disp("-----------------------------------")
% get bin number associated with each frame from DAQ measurements
[norm_frame_pos, tick_frame_pos, bin_ind_arr, num_bins, full_cycle, cycle_freq, num_clusters, phase_spread_ratio]...
    = frame_to_bin(PIV_case_name, num_images, D.freq_avg, bools.turbine, bools.plot);

% Find matching DAQ file
[daq_data_filename, daq_data_path] = get_daq_paths(PIV_case_name);

% Get AFAM parameters associated with that trial
if ~bools.turbine
    if contains(daq_data_filename, regexpPattern('x\d'))
        new_bool = true;
    end
    WT_d = get_wind_tunnel_data(daq_data_path, daq_data_filename, new_bool);
    if new_bool
        speed = WT_d.Speed;
        S.rho_act = WT_d.Density;
        mu = WT_d.Viscosity;
    else
        speed = WT_d.Speed_m_s_;
        S.rho_act = WT_d.Density_kg_m3_;
        mu = WT_d.Viscosity_N_s_m2_;
    end
    S.U_act = speed / U;
    S.Re = (S.rho_act * speed * L) / mu;
end
density = 1.225;

% variable preallocation
bin_count = zeros(1,num_bins);
bin_std = zeros(1,num_bins);
lift_phase_avg = struct();
drag_phase_avg = struct();
print_dim_bool = true;

fields = get_STB_processing_fields();

% Compute array of x-positions associated with each frame
% [~, ~, freq] = parse_name(PIV_case_name);
% dt = 1 / (freq * num_bins);
% x_conv = zeros(1, num_bins);
% for k = 1:num_bins
%     x_conv(k) =  -speed * dt * (k - 1); % negative sign added for ref. frame
% end
x_conv = 0;

for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    bin_count(i) = length(bin_indices);
    bin_std(i) = std(norm_frame_pos(bin_indices))*100;

    % Import data (using a temporary struct or list)
    [x, y, z, data{1:length(fields)}] = ...
        import_STB_data(file_path, bools.nondim, U, L, bin_indices, bools.RPCA);

    F = prepare_STB_wake_field(L, y, z, print_dim_bool, data, x_conv); % trimming fields

    if ~bools.turbine
    [lift_vals, drag_vals] = get_wake_lift(speed, L, F, true, S.rho_act);
    end
        
    % Variable preallocation that is dependent on the data content 
    if i == 1
        % Initialize structure with zeros based on first file size
        for f = 1:length(fields)
            S.([fields{f} '_phase_avg']) = zeros(size(x,1), size(x,2), size(x,3), num_bins);
        end
        S.uu_stress = zeros(size(x,1), size(x,2), size(x,3), num_bins);
        S.vv_stress = zeros(size(x,1), size(x,2), size(x,3), num_bins);
        S.ww_stress = zeros(size(x,1), size(x,2), size(x,3), num_bins);
        S.uv_stress = zeros(size(x,1), size(x,2), size(x,3), num_bins);
        S.uw_stress = zeros(size(x,1), size(x,2), size(x,3), num_bins);
        S.vw_stress = zeros(size(x,1), size(x,2), size(x,3), num_bins);

        if ~bools.turbine
        lift_fields = fieldnames(lift_vals);
        for f = 1:length(lift_fields)
            lift_phase_avg.(lift_fields{f}) = zeros(1,num_bins);
        end

        drag_fields = fieldnames(drag_vals);
        for f = 1:length(drag_fields)
            drag_phase_avg.(drag_fields{f}) = zeros(1,num_bins);
        end
        end

        % turn printing boolean off for printing of trimmed dimensions
        print_dim_bool = false;
        disp("Trimming for force calculation only")
    end

    % Phase average computation
    for f = 1:length(fields)
        fname = [fields{f}, '_phase_avg'];
        % Compute mean along the 4th dimension
        S.(fname)(:,:,:,i) = mean(data{f}, 4, "omitnan");

        fname = [fields{f}, '_phase_std'];
        S.(fname)(:,:,:,i) = std(data{f}, 0, 4, "omitnan");
    end

    % Velocity fluctuations for Reynolds stress calculation
    u_fluc = data{1} - S.u_phase_avg(:,:,:,i);
    v_fluc = data{2} - S.v_phase_avg(:,:,:,i);
    w_fluc = data{3} - S.w_phase_avg(:,:,:,i);

    wx_fluc = data{5} - S.vortX_phase_avg(:,:,:,i);
    wy_fluc = data{6} - S.vortY_phase_avg(:,:,:,i);
    % wz_fluc = data{7} - S.vortZ_phase_avg(:,:,:,i);

    % Normal stresses
    S.uu_stress(:,:,:,i) = mean(u_fluc .* u_fluc, 4, "omitnan");
    S.vv_stress(:,:,:,i) = mean(v_fluc .* v_fluc, 4, "omitnan");
    S.ww_stress(:,:,:,i) = mean(w_fluc .* w_fluc, 4, "omitnan");

    % Shear stresses
    S.uv_stress(:,:,:,i) = mean(u_fluc .* v_fluc, 4, "omitnan");
    S.uw_stress(:,:,:,i) = mean(u_fluc .* w_fluc, 4, "omitnan");
    S.vw_stress(:,:,:,i) = mean(v_fluc .* w_fluc, 4, "omitnan");

    % Fluctuation terms related to force calculation
    S.u_wx_stress(:,:,:,i) = mean(u_fluc .* wx_fluc, 4, "omitnan");
    S.u_wy_stress(:,:,:,i) = mean(u_fluc .* wy_fluc, 4, "omitnan");

    if ~bools.turbine
    % Compute phase averages from lift data in current bin
    for f = 1:length(lift_fields)
        field_name = lift_fields{f};
        cur_vals = lift_vals.(field_name);
        lift_phase_avg.(field_name)(i) = mean(cur_vals(:), "omitnan");
    end

    % Compute phase averages from drag data in current bin
    for f = 1:length(drag_fields)
        field_name = drag_fields{f};
        cur_vals = drag_vals.(field_name);
        drag_phase_avg.(field_name)(i) = mean(cur_vals(:), "omitnan");
    end
    end

    if mod(i,5) == 0
        disp(['processed ',num2str(i),'/',num2str(num_bins)])
    end
end

% Add metadata to the struct
S.x = x; S.y = y; S.z = z; S.L = L; S.U = U; S.rho = density; S.cycle_freq = cycle_freq;
S.num_bins = num_bins; S.tick_frame_pos = tick_frame_pos; S.full_cycle = full_cycle;
S.bin_ind_arr = bin_ind_arr; S.bin_count = bin_count; S.bin_std = bin_std;
S.num_clusters = num_clusters; S.phase_spread_ratio = phase_spread_ratio;
S.PIV_case_name = PIV_case_name;

if ~bools.turbine
S.lift_phase_avg = lift_phase_avg; S.drag_phase_avg = drag_phase_avg;
end

% Save the entire structure
disp("Saving data to: " + save_path)
save(save_path, '-struct', 'S');

fprintf('Processing and saving data took %.4f seconds.\n', toc);

% Calculate secondary values (Q, power, integral values) and save in
% separate file
calc_secondary_vals_phase(S, D, bools, save_filepath_local);

else

% load in processed velocity field struct from an earlier run
S = load(save_path);

% Calculate secondary values (Q, power, integral values) and save in
% separate file
calc_secondary_vals_phase(S, D, bools, save_filepath_local);
end
end