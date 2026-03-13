function [norm_signal, tick_frame_pos, bin_ind_arr, num_bins, full_cycle, cycle_freq] = frame_to_bin(PIV_case_name, num_images, turbine_bool)

[daq_data_filename, daq_data_path] = get_daq_paths(PIV_case_name);

% Get raw data from file
load([daq_data_path daq_data_filename]);

% 0 - binning according to encoder phase, 1 - binning according to time
phase_type = 1;

if turbine_bool
num_bins = 25;

mid_indices = find(las_count_orig ~= 0 & las_count_orig ~= las_count_orig(end));
% if removed all mid_indices, would miss first and last pulse
mid_indices_adj = [mid_indices(1) - 1; mid_indices; mid_indices(end) + 1];
las_count_tr = las_count_orig(mid_indices_adj);
las_count_diff = diff(las_count_tr);
whole_idx = find(las_count_diff ~= 0);
las_rep_rate = diff(whole_idx);

laser_ind = whole_idx + mid_indices_adj(1);

enc_pos = enc(laser_ind);

full_cycle = 0.5:1:ticksPerRev+0.5;
norm_frame_pos = enc_pos / ticksPerRev;
norm_frame_pos = mod(norm_frame_pos, 1);
tick_frame_pos = round(norm_frame_pos * ticksPerRev);

cycle_freq = mean(speed(mid_indices(1):mid_indices(end)));

time_frame = time(laser_ind);
time_frame = time_frame(end-(num_images - 1):end); % cropping time array
norm_time = mod((time_frame - time_frame(1)) * cycle_freq, 1);

disp("Cropped off " + (length(norm_frame_pos) - num_images) + " extra laser pulses from beginning")
% crop off last few extra pulses
% bin_ind_arr = bin_ind_arr(1:num_images);
% crop off first few extra pulses
norm_frame_pos = norm_frame_pos(end-(num_images - 1):end);

switch phase_type
    case 0
        disp("Using motor position for phase")
        norm_signal = norm_frame_pos;
    case 1
        disp("Using time for phase")
        norm_signal = norm_time;
end

disp("Using " + num_bins + " bins")
% num_bins = 25; % for 4 Hz
bins = linspace(0,1,num_bins+1);
bin_ind_arr = discretize(norm_signal, bins);

num_cycles = length(find(diff(bin_ind_arr) < 0)); % back to beginning of a cycle
disp("Number of cycles: " + num_cycles)

bin_count = zeros(1,num_bins);
bin_std = zeros(1,num_bins);

for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    % bin_indices_all{i} = bin_indices;
    bin_count(i) = length(bin_indices);

    % Account for cases at overlap which would otherwise artificially raise
    % the apparent standard deviation
    adj_norm_frame_pos = norm_signal(bin_indices);
    if sum(adj_norm_frame_pos < 0.2) > 0 && sum(adj_norm_frame_pos > 0.8) > 0
        adj_norm_frame_pos(adj_norm_frame_pos < 0.2) = adj_norm_frame_pos(adj_norm_frame_pos < 0.2) + 1;
    end

    bin_std(i) = std(adj_norm_frame_pos); % removed for turbine case
end

% CPR = 500;
% trigger_int = 80;
% 
% % Encoder phase for each frame
% phase = mod((0:num_images-1) * trigger_int, CPR);
% 
% % Unique phase bins (sorted)
% sortIndex = sort(unique(phase));
% num_bins = length(sortIndex);
% 
% % Assign each frame to a phase bin
% [~, bin_ind_arr] = ismember(phase, sortIndex);
% disp("used Taylor phase average code")

else
[~, ~, ~, cycle_freq, ~, ~, ~, ~] = parse_filename(daq_data_filename);

ticksPerRev = 18432;
OC_pulse_step = 4;
rate = 15000;

% Find indices where a laser fire has been recorded, each time this
% counter is incremented, a laser pulse (and vel field) has been recorded
las_count = results(:,12);

% trim beginning and end of recording session
mid_indices = find(las_count ~= 0 & las_count ~= las_count(end));
% if removed all mid_indices, would miss first and last pulse
mid_indices_adj = [mid_indices(1) - 1; mid_indices; mid_indices(end) + 1];
las_count_tr = las_count(mid_indices_adj);

% find indices where laser counter increments
las_count_diff = diff(las_count_tr);
whole_idx = find(las_count_diff ~= 0);
laser_ind = whole_idx + mid_indices_adj(1);

% confirm laser fired at expected rate
frames_bw_pulses = diff(whole_idx);
las_rep_rate = rate / mean(frames_bw_pulses);
disp("Laser recorded firing at: " + las_rep_rate + " Hz on average")

% find value of laser counter when camera trigger signal initiated
cam_fire_idx = find(results(:,13) == 2, 1, "first");
laser_count_at_cam_fire = las_count(cam_fire_idx);
disp("Laser pulses by camera fire: " + laser_count_at_cam_fire)

switch phase_type
    case 0
        disp("Using motor position for phase")

        % motor position is recorded using OC pulses sent by galil
        % 1 revolution of the motor corresponds to (ticksPerRev / OC_pulse_step)
        % pulses
        OC_pulse_count = results(:,11);
        
        % normalized signal where 1 now represents 1 full rotation/wingbeat
        norm_signal = OC_pulse_count / (ticksPerRev / OC_pulse_step);
    case 1
        disp("Using time for phase")

        time = results(:,1);

        % normalized signal where 1 now represents 1 full rotation/wingbeat
        norm_signal = time * cycle_freq;
end

% find signal value corresponding to laser pulse
norm_signal = norm_signal(laser_ind);

disp("Cropped off " + (length(norm_signal) - num_images) + " extra laser pulses from beginning")
% crop off first few extra pulses
norm_signal = norm_signal(end-(num_images - 1):end);

% wrap values so only expressed between 0 and 1
norm_signal = mod(norm_signal, 1);

if phase_type == 0
    tick_frame_pos = round(norm_signal * (ticksPerRev / OC_pulse_step),3);
    full_cycle = 0.5:1:(ticksPerRev / OC_pulse_step)+0.5;
else
    tick_frame_pos = zeros(size(norm_signal));
    full_cycle = zeros(size(norm_signal));
end

[num_bins, bin_ind_arr, bin_count, bin_std] = findBestNumBins(norm_signal);
disp("Using " + num_bins + " bins")

% rough estimate of number of cycles based on value resetting to zero
num_cycles = length(find(diff(bin_ind_arr) < 0));
disp("Number of cycles: " + num_cycles)
disp("Expected number of cycles: " + num_images / (200 / cycle_freq))

end

figure
histogram(tick_frame_pos, full_cycle)
xlabel("Encoder Ticks")
ylabel("Frequency")

figure
bar(bin_count)
xlabel("Bin number", FontSize=16)
ylabel("Number of frames per bin", FontSize=16)

figure
bar(bin_std)
xlabel("Bin number", FontSize=16)
ylabel("Phase variability per bin (% cycle)", FontSize=16)
end