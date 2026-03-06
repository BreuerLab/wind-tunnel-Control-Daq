function [norm_frame_pos, bin_ind_arr, num_bins, cycle_freq] = frame_to_bin(PIV_case_name, num_images, turbine_bool)
[daq_data_filename, daq_data_path] = get_daq_paths(PIV_case_name);

% exp_data_folder = daq_data_path + "experiment data\";
% offsets_data_folder = daq_data_path + "offsets data\";

% [case_name, time_stamp, type, wing_freq, AoA, wind_speed, amp, file_type] = parse_filename(daq_data_filename);
% 
% % Find matching offsets file
% offsets_string = "before_offsets";
% calibration_filepath = "../DAQ/Calibration Files/Mini40/FT52907.cal";
% cal_mat = obtain_cal(calibration_filepath);
% 
% % Get a list of all files in the folder with the desired file name pattern.
% filePattern = fullfile(offsets_data_folder, '*.mat');
% offsets_files = dir(filePattern);
% 
% % try
% [offsets, offsets_filename] = findMatchingOffset...
%     (offsets_files, offsets_string, wing_freq, amp, AoA, wind_speed, type, time_stamp);
% % catch
% %     error("Oops, no offsets found. Did you check that daq_data_path is correct?")
% % end

% Get raw data from file
load([daq_data_path daq_data_filename]); % load in results var

if turbine_bool
num_bins = 210;

figure
histogram(enc_pos, num_bins)
xlabel("Encoder Ticks")
ylabel("Frequency")

norm_frame_pos = enc_pos / ticksPerRev;

disp("Using " + num_bins + " bins")
% num_bins = 25; % for 4 Hz
bins = linspace(0,1,num_bins+1);
bin_ind_arr = discretize(norm_frame_pos, bins);
num_cycles = length(find(diff(bin_ind_arr) < 0)); % back to beginning of a cycle
disp("Number of cycles: " + num_cycles)

disp("Cropped off " + (length(bin_ind_arr) - num_images) + " extra laser pulses from beginning")
% crop off last few extra pulses
% bin_ind_arr = bin_ind_arr(1:num_images);
% crop off first few extra pulses
bin_ind_arr = bin_ind_arr(end-(num_images - 1):end);

bin_count = zeros(1,num_bins);
bin_std = zeros(1,num_bins);

for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    % bin_indices_all{i} = bin_indices;
    bin_count(i) = length(bin_indices);

    % Account for cases at overlap which would otherwise artificially raise
    % the apparent standard deviation
    adj_norm_frame_pos = norm_frame_pos(bin_indices);
    if sum(adj_norm_frame_pos < 0.2) > 0 && sum(adj_norm_frame_pos > 0.8) > 0
        adj_norm_frame_pos(adj_norm_frame_pos < 0.2) = adj_norm_frame_pos(adj_norm_frame_pos < 0.2) + 1;
    end

    bin_std(i) = std(adj_norm_frame_pos); % removed for turbine case
end

figure
bar(bin_count)
xlabel("Bin number", FontSize=16)
ylabel("Number of frames per bin", FontSize=16)

figure
bar(bin_std)
xlabel("Bin number", FontSize=16)
ylabel("Phase variability per bin", FontSize=16)

cycle_freq = 30;

else
[case_name, time_stamp, type, wing_freq, AoA, wind_speed, amp, file_type] = parse_filename(daq_data_filename);
cycle_freq = wing_freq;

ticksPerRev = 18432;
OC_pulse_step = 4;
% [time_data, force_data, voltAdj, curAdj, speed, OC_pulse_count] = process_data(results, offsets, cal_mat, ticksPerRev, OC_pulse_step, true);
OC_pulse_count = results(:,11);
wing_pos = OC_pulse_count / (ticksPerRev / OC_pulse_step);

% Find indices where a laser fire has been recorded
las_count = results(:,12);
mid_indices = find(las_count ~= 0 & las_count ~= las_count(end));
% if removed all mid_indices, would miss first and last pulse
mid_indices_adj = [mid_indices(1) - 1; mid_indices; mid_indices(end) + 1];
las_count_tr = las_count(mid_indices_adj);
las_count_diff = diff(las_count_tr);
whole_idx = find(las_count_diff ~= 0);
las_rep_rate = diff(whole_idx);

laser_ind = whole_idx + mid_indices_adj(1);
wing_pos_frame = wing_pos(laser_ind);
norm_frame_pos = mod(wing_pos_frame,1);
norm_wing_pos_frame_tr = norm_frame_pos(end-(num_images - 1):end);
norm_wing_pos_frame_int = round(norm_frame_pos * (ticksPerRev / OC_pulse_step),3);
full_cycle = 0.5:1:(ticksPerRev / OC_pulse_step)+0.5;
% edges = (min(norm_wing_pos_frame_int)-0.5):(max(norm_wing_pos_frame_int)+0.5);

cam_fire_idx = find(results(:,13) == 2, 1, "first");
laser_pulse_at_cam_fire = results(cam_fire_idx,12);
disp("Laser pulses by camera fire: " + laser_pulse_at_cam_fire)

figure
histogram(norm_wing_pos_frame_int, full_cycle)
xlabel("Encoder Ticks")
ylabel("Frequency")

figure
histogram(norm_wing_pos_frame_int, 70)
xlabel("Encoder Ticks")
ylabel("Frequency")

% 50 for 2 Hz, 45 for 4 Hz, 45 for 6 Hz, 23 for 8 Hz
% num_bins = 50;
keys = {2, 4, 6, 8};
num_bins_opts = [50, 45, 45, 23];
bins_dict = containers.Map(keys, num_bins_opts);
num_bins = bins_dict(wing_freq);

num_bins = 70;

disp("Using " + num_bins + " bins")
% num_bins = 25; % for 4 Hz
bins = linspace(0,1,num_bins+1);
bin_ind_arr = discretize(norm_frame_pos, bins);
num_cycles = length(find(diff(bin_ind_arr) < 0)); % back to beginning of a cycle
disp("Number of cycles: " + num_cycles)
disp("Expected number of cycles: " + num_images / (200 / wing_freq))

disp("Cropped off " + (length(bin_ind_arr) - num_images) + " extra laser pulses from beginning")
% crop off last few extra pulses
% bin_ind_arr = bin_ind_arr(1:num_images);
% crop off first few extra pulses
bin_ind_arr = bin_ind_arr(end-(num_images - 1):end);
end
end