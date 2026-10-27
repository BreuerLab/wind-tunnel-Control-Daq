function [norm_signal, tick_frame_pos, bin_ind_arr, num_bins, full_cycle, cycle_freq, num_clusters, phase_spread_ratio, ...
    bin_phase_var, phase_res, bin_placement, bin_offset] ...
    = frame_to_bin(PIV_case_name, num_images, freq_cor, turbine_bool, plot_bool, bins_list)
% bins_list     - (optional) bin counts findBestNumBins2 searches, e.g.
%                 100:120 (set with bools.bin_range in main_processing);
%                 default 180:210
% bin_phase_var - range of phase values within each bin (% of bin width)
% phase_res     - phase resolution: smallest phase step the DAQ can
%                 resolve, i.e. one DAQ sample for a time-based phase or
%                 one encoder pulse for the encoder phase (% of bin width).
%                 Best case for bin_phase_var is about phase_res.
% bin_placement - centroid (mean phase) of the frames in each bin minus the
%                 bin centre (% of bin width). Positive = frames sit late in
%                 the bin, negative = early; 0 = centred, which is what
%                 phase averaging assumes.
% bin_offset    - phase (cycles) where bin 1 starts: bin j covers
%                 bin_offset + [j-1, j)/num_bins of norm_signal, so its
%                 centre is bin_offset + (j - 0.5)/num_bins

[daq_data_filename, daq_data_path] = get_daq_paths(PIV_case_name);

% Get raw data from file
load([daq_data_path daq_data_filename]);

% 0 - binning according to encoder phase
% 1 - binning according to time, phase = mod(time * frequency, 1)
% 2 - binning according to time, re-anchored to the encoder at the start
%     of every cycle (no drift build-up over the recording)
phase_type = 2;

if turbine_bool
% not computed for the turbine (needed so later outputs can be requested)
num_clusters = NaN;
phase_spread_ratio = NaN;

% trim beginning and end of recording session
mid_indices = find(las_count_orig ~= 0 & las_count_orig ~= las_count_orig(end));
% if removed all mid_indices, would miss first and last pulse
mid_indices_adj = [mid_indices(1) - 1; mid_indices; mid_indices(end) + 1];
las_count_tr = las_count_orig(mid_indices_adj);

% find indices where laser counter increments
las_count_diff = diff(las_count_tr);
whole_idx = find(las_count_diff ~= 0);
laser_ind = whole_idx + mid_indices_adj(1);

% confirm laser fired at expected rate
frames_bw_pulses = diff(whole_idx);
las_rep_rate = rate / mean(frames_bw_pulses);
disp("Laser recorded firing at: " + las_rep_rate + " Hz on average")

% motor phase position associated with each laser pulse
enc_pos = enc(laser_ind);

full_cycle = 0.5:1:ticksPerRev+0.5;

% normalized signal where 1 now represents 1 full rotation
norm_frame_pos = enc_pos / ticksPerRev;

% wrap values so only expressed between 0 and 1
norm_frame_pos = mod(norm_frame_pos, 1);
tick_frame_pos = round(norm_frame_pos * ticksPerRev);

dt = time(2) - time(1);
order = 3;
framelen = 1501;
[~,speed,~] = savitskyGolayDiff(enc, order, framelen, dt);
speed = speed / ticksPerRev;

speed_tr = speed(mid_indices(1):mid_indices(end));
cycle_freq = mean(speed_tr);

% plot(time(mid_indices(1):mid_indices(end)),speed_tr)
% xlabel("Time (sec)")
% ylabel("Speed (Hz)")
% set(gca, FontSize=16)

time_frame = time(laser_ind);
time_frame = time_frame(end-(num_images - 1):end); % cropping time array
norm_time = mod((time_frame - time_frame(1)) * cycle_freq, 1);

disp("Cropped off " + (length(norm_frame_pos) - num_images) + " extra laser pulses from beginning")
% crop off first few extra pulses
norm_frame_pos = norm_frame_pos(end-(num_images - 1):end);

switch phase_type
    case 0
        disp("Using motor position for phase")
        norm_signal = norm_frame_pos;
    otherwise % 1 or 2 (turbine: time phase, no per-cycle re-anchoring)
        disp("Using time for phase")
        norm_signal = norm_time;
end

num_bins = 40;
% [num_bins, bin_ind_arr, bin_count, bin_std] = findBestNumBins(norm_signal);
disp("Using " + num_bins + " bins")

bins = linspace(0,1,num_bins+1);
bin_ind_arr = discretize(norm_signal, bins);

num_cycles = length(find(diff(bin_ind_arr) < 0)); % back to beginning of a cycle
disp("Number of cycles: " + num_cycles)

bin_count = zeros(1,num_bins);
bin_std = zeros(1,num_bins);

for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    bin_count(i) = length(bin_indices);

    % Account for cases at overlap which would otherwise artificially raise
    % the apparent standard deviation
    adj_norm_frame_pos = norm_signal(bin_indices);
    if sum(adj_norm_frame_pos < 0.2) > 0 && sum(adj_norm_frame_pos > 0.8) > 0
        adj_norm_frame_pos(adj_norm_frame_pos < 0.2) = adj_norm_frame_pos(adj_norm_frame_pos < 0.2) + 1;
    end

    bin_std(i) = std(adj_norm_frame_pos); % removed for turbine case
end

bin_offset = 0; % fixed bins starting at phase 0
bin_phase_var = bin_phase_variability(norm_signal, bin_ind_arr, num_bins);
if phase_type == 0
    phase_step = 1 / ticksPerRev; % one encoder tick
else
    phase_step = cycle_freq * dt; % one DAQ sample
end
phase_res = phase_step * num_bins * 100;

% ------------------------------------------------------------------------
% ------------------ Phase Averaging Code from Taylor --------------------
% ------------------------------------------------------------------------
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
pulsesPerRev = ticksPerRev / OC_pulse_step;
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

% could use cycle_freq or freq_cor here, but using the measured average
% wingbeat frequency freq_cor seems more accurate
norm_signal = get_norm_signal(results, phase_type, pulsesPerRev, freq_cor, laser_ind, num_images);
norm_pos = get_norm_signal(results, 0, pulsesPerRev, cycle_freq, laser_ind, num_images);

% associate t = 0 with theta = 0
[~,I] = min(norm_pos);
t_phase_zero = norm_signal(I);
norm_signal(norm_signal < t_phase_zero) = norm_signal(norm_signal < t_phase_zero) + 1;
norm_signal = norm_signal - t_phase_zero;

tick_frame_pos = round(norm_pos * pulsesPerRev,3);
full_cycle = 0.5:1:pulsesPerRev + 0.5;

gap_thresh = 2;

num_clusters = sum(diff(unique(tick_frame_pos)) > gap_thresh);

phase_spread_ratio = length(unique(tick_frame_pos)) / length(tick_frame_pos);

if nargin < 6 || isempty(bins_list)
    bins_list = 180:1:210;
end
minFrames = 3;
% [num_bins, bin_ind_arr, bin_count, bin_std] = findBestNumBins(norm_signal, bins_list, minFrames);
num_shifts = 10;
[num_bins, bin_offset, bin_ind_arr, bin_count,bin_std] = findBestNumBins2(norm_signal, bins_list, minFrames, num_shifts);
disp("Using " + num_bins + " bins (searched " + min(bins_list) + "-" + max(bins_list) + ")")
if num_bins == 0
    error("Zero bins identified (no bin count in %d-%d gives at least %d frames in every bin)", ...
        min(bins_list), max(bins_list), minFrames)
end
if numel(bins_list) > 1 && ismember(num_bins, [min(bins_list), max(bins_list)])
    disp("Note: best bin count is at the edge of the searched range; the best overall may lie outside it")
end
bin_phase_var = bin_std; % range within each bin, % of bin width

% phase resolution: median phase step between consecutive DAQ samples
% (one sample for a time-based phase, one OC pulse for the encoder phase)
full_phase = get_norm_signal(results, phase_type, pulsesPerRev, freq_cor);
dphi = diff(full_phase);
phase_step = median(dphi(dphi > 0 & dphi < 0.5));
phase_res = phase_step * num_bins * 100;
disp("Phase resolution: " + sprintf("%.2f%% of a bin", phase_res))

% rough estimate of number of cycles based on value resetting to zero
num_cycles = length(find(diff(bin_ind_arr) < 0));
disp("Number of cycles: " + num_cycles)
disp("Expected number of cycles: " + num_images / (200 / cycle_freq))

end

bin_placement = get_bin_placement(norm_signal, bin_ind_arr, num_bins, bin_offset);

if plot_bool
figure
histogram(tick_frame_pos, full_cycle)
xlabel("Encoder Ticks")
ylabel("Frequency")

figure
bar(bin_count)
xlabel("Bin number", FontSize=16)
ylabel("Number of frames per bin", FontSize=16)

figure
h = plot(bin_phase_var, '-o', 'MarkerSize', 4);
h.MarkerFaceColor = h.Color; % filled markers
xlabel("Bin number", FontSize=16)
ylabel("Phase variability per bin (% bin width)", FontSize=16)
title(sprintf("Phase variability: mean %.2f%% of bin, resolution %.2f%% of bin", ...
    mean(bin_phase_var, "omitnan"), phase_res), FontSize=14)

figure
h = plot(bin_placement, '-o', 'MarkerSize', 4);
h.MarkerFaceColor = h.Color; % filled markers
yline(0, '-k', 'HandleVisibility', 'off')
xlabel("Bin number", FontSize=16)
ylabel("Centroid offset from bin centre (% bin width)", FontSize=16)
title(sprintf("Bin placement: mean %+.2f%%, mean |offset| %.2f%% of bin (+ = late in bin)", ...
    mean(bin_placement, "omitnan"), mean(abs(bin_placement), "omitnan")), FontSize=14)
end
end

function bin_var = bin_phase_variability(norm_signal, bin_ind_arr, num_bins)
% Range of phase within each bin (% of bin width), taken around the circle
% (1 minus the largest gap between sorted phases, including 1 -> 0) so a bin
% straddling the 0/1 seam isn't inflated. Empty bins give NaN.
bin_var = NaN(1, num_bins);
for j = 1:num_bins
    p = sort(mod(norm_signal(bin_ind_arr == j), 1));
    if isempty(p), continue, end
    gaps = [diff(p(:)); p(1) + 1 - p(end)];
    bin_var(j) = (1 - max(gaps)) * num_bins * 100;
end
end

function placement = get_bin_placement(norm_signal, bin_ind_arr, num_bins, bin_offset)
% Mean phase of the frames in each bin minus the bin centre (% of bin
% width). Bin j spans [(j-1)/num_bins, j/num_bins) of the signal shifted by
% bin_offset (see findBestNumBins2), so its centre in the original phase is
% bin_offset + (j - 0.5)/num_bins. Differences are wrapped to [-0.5, 0.5)
% so a bin at the 0/1 seam is handled. Empty bins give NaN.
placement = NaN(1, num_bins);
for j = 1:num_bins
    p = norm_signal(bin_ind_arr == j);
    if isempty(p), continue, end
    centre = bin_offset + (j - 0.5) / num_bins;
    delta = mod(p - centre + 0.5, 1) - 0.5;
    placement(j) = mean(delta) * num_bins * 100;
end
end