function get_laser_phase_bins(results, rate, cycle_freq, freq_cor, num_images, pulsesPerRev, plot_bool)

% 0 - binning according to encoder phase, 1 - binning according to time
phase_type = 1;

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
disp("Identified " + num_clusters + " number of frame clusters, with a phase spread ratio of: " + phase_spread_ratio)

% bins_list = 20:5:125;
% minFrames = 10;
% [num_bins, bin_ind_arr, bin_count, bin_std] = findBestNumBins(norm_signal, bins_list, minFrames);
% disp("Using " + num_bins + " bins")

num_bins = 96;
bins = linspace(0,1,num_bins+1);
bin_ind_arr = discretize(norm_signal, bins);
% variable preallocation
[bin_count, bin_std] = deal(zeros(1, num_bins));

for j = 1:num_bins
    bin_indices = find(bin_ind_arr == j);
    bin_count(j) = length(bin_indices);
    bin_std(j) = range(norm_signal(bin_indices)) .* num_bins;
    % bin_std(j) = std(norm_signal(bin_indices)) .* num_bins;
    % normalizing by width of single bin in terms of phase
    % same as dividing by bin width
end

% rough estimate of number of cycles based on value resetting to zero
num_cycles = length(find(diff(bin_ind_arr) < 0));
disp("Number of cycles: " + num_cycles)
disp("Expected number of cycles: " + num_images / (200 / cycle_freq))

if plot_bool
figure
histogram(tick_frame_pos, full_cycle)
xlabel("Encoder Ticks")
ylabel("Frequency")

% testing to see where distribution falls relative to bin edges
% figure
% histogram(tick_frame_pos * (num_bins / pulsesPerRev), full_cycle * (num_bins / pulsesPerRev))
% xline(bins * (num_bins + 1), LineWidth=2, Linestyle="--")
% xlabel("Encoder Ticks")
% ylabel("Frequency")

figure
bar(bin_count)
xlabel("Bin number", FontSize=16)
ylabel("Number of frames per bin", FontSize=16)

figure
bar(bin_std*100)
xlabel("Bin number", FontSize=16)
ylabel("Phase variability per bin (% cycle)", FontSize=16)
end