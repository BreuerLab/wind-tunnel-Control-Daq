function S = phase_avg_STB(file_path, U, L, save_filepath_local, PIV_case_name, num_images, bools, bounds)
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
disp("-----------------------------------")
disp("Assuming num images = " + num_images)
disp("-----------------------------------")
% get bin number associated with each frame from DAQ measurements
[norm_frame_pos, tick_frame_pos, bin_ind_arr, num_bins, full_cycle, cycle_freq, num_clusters, phase_spread_ratio,...
    bin_phase_var, phase_res] = frame_to_bin(PIV_case_name, num_images, D.freq_avg, bools.turbine, bools.plot);

% Find matching DAQ file
[daq_data_filename, daq_data_path] = get_daq_paths(PIV_case_name);

% Get AFAM parameters associated with that trial
if ~bools.turbine
    if contains(daq_data_filename, regexpPattern('x\d')) || contains(daq_data_filename, "MPS")
        new_bool = true;
    else
        new_bool = false;
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
lift_before_avg = struct();
drag_before_avg = struct();
% velocity-only lift (u*w) and drag (get_wake_lift with vort_bool false)
lift_vel_before_avg = zeros(1,num_bins);
drag_vel_before_avg = zeros(1,num_bins);
fields = get_STB_processing_fields();

% Optional outputs (default on if the caller didn't set them)
calc_Q_inst = ~isfield(bools, 'Q_inst') || bools.Q_inst;
calc_vort_uavg = ~isfield(bools, 'vort_uavg') || bools.vort_uavg;

% time spent in each stage, printed at the end
t_stage = struct('import', 0, 'forces', 0, 'stats', 0, 'Q_inst', 0, 'vort_uavg', 0, 'save', 0);

% Compute array of x-positions associated with each frame
% [~, ~, freq] = parse_name(PIV_case_name);
% dt = 1 / (freq * num_bins);
% x_conv = zeros(1, num_bins);
% for k = 1:num_bins
%     x_conv(k) =  -speed * dt * (k - 1); % negative sign added for ref. frame
% end
x_conv = 0;

% Values the bin loop needs (turbine runs have no wind tunnel data)
if bools.turbine
    speed = U;
    rho_act = density;
else
    rho_act = S.rho_act;
end
opts.calc_Q_inst = calc_Q_inst;
opts.nondim = bools.nondim;
opts.RPCA = bools.RPCA;
opts.turbine = bools.turbine;

% Bins are independent, so they can be processed in parallel. Each
% worker holds one bin's frames for every field, so lower num_workers if
% memory runs out. 0 runs the bins one after another on this client.
num_workers = 0;
if isfield(bools, 'num_workers')
    num_workers = bools.num_workers;
end
num_workers = start_pool(num_workers);

R = cell(1, num_bins);
t_loop = tic;
parfor (i = 1:num_bins, num_workers)
    bin_indices = find(bin_ind_arr == i);
    R{i} = process_bin(file_path, U, L, bin_indices, norm_frame_pos(bin_indices),...
        fields, x_conv, bounds, speed, rho_act, opts, i == 1);
    fprintf('processed bin %d/%d\n', i, num_bins);
end
t_loop = toc(t_loop);

% ----- Gather the per-bin results -----
x = R{1}.x; y = R{1}.y; z = R{1}.z;
grid_size = [size(x,1), size(x,2), size(x,3), num_bins];

for f = 1:length(fields)
    S.([fields{f} '_phase_avg']) = zeros(grid_size);
    S.([fields{f} '_phase_std']) = zeros(grid_size);
end
stress_names = fieldnames(R{1}.stress);
for k = 1:length(stress_names)
    S.(stress_names{k}) = zeros(grid_size);
end
Q_names = {'Qx_inst_avg', 'Qy_inst_avg', 'Qz_inst_avg', 'Q_inst_avg',...
    'Qx_inst_std', 'Qy_inst_std', 'Qz_inst_std', 'Q_inst_std'};
if calc_Q_inst
    for k = 1:length(Q_names)
        S.(Q_names{k}) = zeros(grid_size);
    end
end

if ~bools.turbine
    lift_fields = fieldnames(R{1}.lift);
    drag_fields = fieldnames(R{1}.drag);
    for f = 1:length(lift_fields)
        lift_before_avg.(lift_fields{f}) = zeros(1,num_bins);
    end
    for f = 1:length(drag_fields)
        drag_before_avg.(drag_fields{f}) = zeros(1,num_bins);
    end
end

for i = 1:num_bins
    B = R{i};
    R{i} = []; % free memory as we go
    bin_count(i) = B.bin_count;
    bin_std(i) = B.bin_std;

    for f = 1:length(fields)
        S.([fields{f} '_phase_avg'])(:,:,:,i) = B.avg{f};
        S.([fields{f} '_phase_std'])(:,:,:,i) = B.std{f};
    end
    for k = 1:length(stress_names)
        S.(stress_names{k})(:,:,:,i) = B.stress.(stress_names{k});
    end
    if calc_Q_inst
        for k = 1:length(Q_names)
            S.(Q_names{k})(:,:,:,i) = B.Q{k};
        end
    end

    if ~bools.turbine
        for f = 1:length(lift_fields)
            lift_before_avg.(lift_fields{f})(i) = B.lift.(lift_fields{f});
        end
        for f = 1:length(drag_fields)
            drag_before_avg.(drag_fields{f})(i) = B.drag.(drag_fields{f});
        end
        lift_vel_before_avg(i) = B.lift_vel;
        drag_vel_before_avg(i) = B.drag_vel;
    end

    t_stage.import = t_stage.import + B.t.import;
    t_stage.forces = t_stage.forces + B.t.forces;
    t_stage.stats = t_stage.stats + B.t.stats;
    t_stage.Q_inst = t_stage.Q_inst + B.t.Q_inst;
end
clear R B

% Vorticity of the phase-averaged velocity (in addition to the average of
% the per-frame vorticity, vort*_phase_avg)
if calc_vort_uavg
t0 = tic;
[S.vortX_uavg, S.vortY_uavg, S.vortZ_uavg] = vorticity_of_mean_velocity(x, y, z,...
    S.u_phase_avg, S.v_phase_avg, S.w_phase_avg,...
    S.uncU_phase_avg, S.uncV_phase_avg, S.uncW_phase_avg);
t_stage.vort_uavg = toc(t0);
end

% Add metadata to the struct
S.x = x; S.y = y; S.z = z; S.L = L; S.U = U; S.rho = density; S.cycle_freq = cycle_freq;
S.num_bins = num_bins; S.tick_frame_pos = tick_frame_pos; S.full_cycle = full_cycle;
S.bin_ind_arr = bin_ind_arr; S.bin_count = bin_count; S.bin_std = bin_std;
S.bin_phase_var = bin_phase_var; S.phase_res = phase_res; % % of bin width
S.num_clusters = num_clusters; S.phase_spread_ratio = phase_spread_ratio;
S.PIV_case_name = PIV_case_name;

if ~bools.turbine
% before-averaging (BA) forces: computed per frame, then averaged per bin
S.lift_before_avg = lift_before_avg; S.drag_before_avg = drag_before_avg;
S.lift_vel_before_avg = lift_vel_before_avg; S.drag_vel_before_avg = drag_vel_before_avg;
end

% Save the entire structure
disp("Saving data to: " + save_path)
t0 = tic;
save_STB_struct(save_path, S, bools);
t_stage.save = toc(t0);

fprintf('Processing and saving data took %.4f seconds.\n', toc);
if num_workers > 0
    fprintf('  bin loop (%d workers, wall clock): %.1f s; stage times below are summed over workers\n',...
        num_workers, t_loop);
end
fprintf(['  load (import_STB_data): %.1f s\n  per-frame forces: %.1f s\n' ...
    '  phase avg / std / stresses: %.1f s\n  Q_inst_avg: %.1f s\n' ...
    '  vorticity of mean velocity: %.1f s\n  save: %.1f s\n'], ...
    t_stage.import, t_stage.forces, t_stage.stats, t_stage.Q_inst, ...
    t_stage.vort_uavg, t_stage.save);

% Calculate secondary values (Q, power, integral values) and save in
% separate file
calc_secondary_vals_phase(S, D, bools, save_filepath_local, bounds);

else

% load in processed velocity field struct from an earlier run
S = load(save_path);

% Calculate secondary values (Q, power, integral values) and save in
% separate file
calc_secondary_vals_phase(S, D, bools, save_filepath_local, bounds);
end
end

% Process one phase bin: load its frames, compute the phase average,
% standard deviation, Reynolds stresses, per-frame forces and (optionally)
% per-frame Q averaged over the bin. Runs on a parallel worker.
function B = process_bin(file_path, U, L, bin_indices, bin_frame_pos, fields, x_conv, bounds,...
    speed, rho_act, opts, print_dim_bool)

B.bin_count = length(bin_indices);
B.bin_std = std(bin_frame_pos)*100;
B.t = struct('import', 0, 'forces', 0, 'stats', 0, 'Q_inst', 0);

data = cell(1, length(fields));
t0 = tic;
[x, y, z, data{:}] = import_STB_data(file_path, opts.nondim, U, L, bin_indices, opts.RPCA);
B.t.import = toc(t0);
B.x = x; B.y = y; B.z = z;

% Forces on each frame, then averaged over the bin
t0 = tic;
if ~opts.turbine
    F = prepare_STB_wake_field(L, y, z, print_dim_bool, data, x_conv, bounds); % trimming fields
    [lift_vals, drag_vals] = get_wake_lift(speed, L, F, true, rho_act);
    [lift_vel_vals, drag_vel_vals] = get_wake_lift(speed, L, F, false, rho_act);
    clear F

    lift_fields = fieldnames(lift_vals);
    for f = 1:length(lift_fields)
        cur_vals = lift_vals.(lift_fields{f});
        B.lift.(lift_fields{f}) = mean(cur_vals(:), "omitnan");
    end
    drag_fields = fieldnames(drag_vals);
    for f = 1:length(drag_fields)
        cur_vals = drag_vals.(drag_fields{f});
        B.drag.(drag_fields{f}) = mean(cur_vals(:), "omitnan");
    end
    B.lift_vel = mean(lift_vel_vals(:), "omitnan");
    B.drag_vel = mean(drag_vel_vals(:), "omitnan");
end
B.t.forces = toc(t0);

% Phase average and standard deviation of every field
t0 = tic;
B.avg = cell(1, length(fields));
B.std = cell(1, length(fields));
for f = 1:length(fields)
    B.avg{f} = mean(data{f}, 4, "omitnan");
    B.std{f} = std(data{f}, 0, 4, "omitnan");
end

% Velocity fluctuations for Reynolds stress calculation
u_fluc = data{1} - B.avg{1};
v_fluc = data{2} - B.avg{2};
w_fluc = data{3} - B.avg{3};
wx_fluc = data{5} - B.avg{5};
wy_fluc = data{6} - B.avg{6};

% Normal stresses
B.stress.uu_stress = mean(u_fluc .* u_fluc, 4, "omitnan");
B.stress.vv_stress = mean(v_fluc .* v_fluc, 4, "omitnan");
B.stress.ww_stress = mean(w_fluc .* w_fluc, 4, "omitnan");
% Shear stresses
B.stress.uv_stress = mean(u_fluc .* v_fluc, 4, "omitnan");
B.stress.uw_stress = mean(u_fluc .* w_fluc, 4, "omitnan");
B.stress.vw_stress = mean(v_fluc .* w_fluc, 4, "omitnan");
% Fluctuation terms related to force calculation
B.stress.u_wx_stress = mean(u_fluc .* wx_fluc, 4, "omitnan");
B.stress.u_wy_stress = mean(u_fluc .* wy_fluc, 4, "omitnan");
B.t.stats = toc(t0);

% Q on each instantaneous field, then averaged over the bin, with its
% frame-to-frame standard deviation
if opts.calc_Q_inst
    t0 = tic;
    B.Q = cell(1, 8);
    [B.Q{:}] = inst_Q_avg(data{1}, data{2}, data{3}, x, y, z);
    B.t.Q_inst = toc(t0);
end
end

% Start (or reuse) a parallel pool with num_workers workers. Returns 0,
% i.e. run serially, if num_workers is 0 or parallel pools aren't
% available (no Parallel Computing Toolbox).
function num_workers = start_pool(num_workers)
if num_workers <= 0
    num_workers = 0;
    return
end
if ~license('test', 'Distrib_Computing_Toolbox') || isempty(ver('parallel'))
    warning("phase_avg_STB:noParallel",...
        "Parallel Computing Toolbox not available, processing bins serially")
    num_workers = 0;
    return
end

pool = gcp('nocreate');
if ~isempty(pool) && pool.NumWorkers ~= num_workers
    delete(pool);
    pool = [];
end
if isempty(pool)
    parpool(num_workers);
end
end
