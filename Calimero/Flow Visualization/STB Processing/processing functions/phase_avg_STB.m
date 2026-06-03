function S = phase_avg_STB(file_path, U, L, save_filepath_local, PIV_case_name, bools)
tic

% Prepare path and name for file to be saved
if bools.RPCA
    save_filename = PIV_case_name + "_RPCA_phase_avg.mat";
else
    save_filename = PIV_case_name + "_phase_avg.mat";
end
save_path = fullfile(save_filepath_local, save_filename);

if bools.proc_vel
num_images = 2500;
disp("Assuming num images = " + num_images)
% get bin number associated with each frame from DAQ measurements
[norm_frame_pos, tick_frame_pos, bin_ind_arr, num_bins, full_cycle, cycle_freq]...
    = frame_to_bin(PIV_case_name, num_images, bools.turbine, bools.plot);

% Find matching DAQ file
[daq_data_filename, ~] = get_daq_paths(PIV_case_name);

% Get AFAM parameters associated with that trial
if ~bools.turbine
    WT_d = get_wind_tunnel_data(daq_data_filename);
    speed = WT_d.Speed_m_s_;
    S.rho_act = WT_d.Density_kg_m3_;
    S.U_act = speed / U;
    S.Re = (WT_d.Density_kg_m3_ *speed * L) / WT_d.Viscosity_N_s_m2_;
end
density = 1.225;

% variable preallocation
bin_count = zeros(1,num_bins);
bin_std = zeros(1,num_bins);
lift_phase_avg = struct();
drag_phase_avg = struct();
print_dim_bool = true;

fields = get_STB_processing_fields();

for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    bin_count(i) = length(bin_indices);
    bin_std(i) = std(norm_frame_pos(bin_indices))*100;

    % Import data (using a temporary struct or list)
    [x, y, z, data{1:length(fields)}] = ...
        import_STB_data(file_path, bools.nondim, U, L, bin_indices, bools.RPCA);

    F = prepare_STB_wake_field(L, y, z, print_dim_bool, data, 0); % trimming fields

    if ~bools.turbine
    [lift_vals, drag_vals] = get_wake_lift(speed, L, F, true, S.rho_act);
    end
        
    % Variable preallocation that is dependent on the data content 
    if i == 1
        % Initialize structure with zeros based on first file size
        for f = 1:length(fields)
            S.([fields{f} '_phase_avg']) = zeros(size(x,1), size(x,2), size(x,3), num_bins);
        end

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
calc_secondary_vals_phase(S, bools.turbine, bools.plot, save_filepath_local);

else

% load in processed velocity field struct from an earlier run
S = load(save_path);

% Calculate secondary values (Q, power, integral values) and save in
% separate file
calc_secondary_vals_phase(S, bools.turbine, bools.plot, save_filepath_local);
end
end