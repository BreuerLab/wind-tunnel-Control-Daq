function S = phase_avg_STB(file_path, nondim_bool, U, L, save_filepath_local, PIV_case_name, turbine_bool)
tic

num_images = 2500;
disp("Assuming num images = " + num_images)
% get bin number associated with each frame from DAQ measurements
[norm_frame_pos, tick_frame_pos, bin_ind_arr, num_bins, full_cycle, cycle_freq]...
    = frame_to_bin(PIV_case_name, num_images, turbine_bool);

bin_count = zeros(1,num_bins);
bin_std = zeros(1,num_bins);

% Define the field names we want to average (must be same order as
% import_STB)
fields = {'u', 'v', 'w', 'Utot', 'vortX', 'vortY', 'vortZ', 'vortTot', 'uncU', 'uncV', 'uncW', 'uncTot'};

for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    % bin_indices_all{i} = bin_indices;
    bin_count(i) = length(bin_indices);
    bin_std(i) = std(norm_frame_pos(bin_indices))*100;
  

    % Import data (using a temporary struct or list)
    [x, y, z, data{1:12}] = import_STB_data(file_path, nondim_bool, U, L, bin_indices);
        
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

% Add metadata to the struct
S.x = x; S.y = y; S.z = z; S.L = L; S.U = U; S.cycle_freq = cycle_freq;
S.num_bins = num_bins; S.tick_frame_pos = tick_frame_pos; S.full_cycle = full_cycle;
S.bin_ind_arr = bin_ind_arr; S.bin_count = bin_count; S.bin_std = bin_std;
S.Qx = Qx; S.Qy = Qy; S.Qz = Qz; S.Q = Q;
S.PIV_case_name = PIV_case_name;

if ~turbine_bool
    % Calculate phase averaged speed
    [norm_time_speed, phase_avg_speed, phase_std_speed, bin_count_speed, bin_std_speed] = speed_phase_avg(PIV_case_name);

    S.norm_time_speed = norm_time_speed; S.phase_avg_speed = phase_avg_speed;
    S.phase_std_speed = phase_std_speed; S.bin_count_speed = bin_count_speed;
    S.bin_std_speed = bin_std_speed;
end

% Save the entire structure
save_path = fullfile(save_filepath_local, [PIV_case_name, '_phase_avg.mat']);
disp("Saving data to: " + save_path)
save(save_path, '-struct', 'S');

fprintf('Processing and saving data took %.4f seconds.\n', toc);
end