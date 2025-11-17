clear
close all
addpath(genpath('../../'))

num_images = 2500;

minCorrelationValue = 0.3;

keys = {'2Hz_10AoA', '4Hz_10AoA'};
values = ["R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\2Hz_10AoA_01\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
          "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\4Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU"];
PIV_dict = containers.Map(keys, values);

case_name = '2Hz_10AoA';
file_path = PIV_dict(case_name);
D = loadpiv(file_path,"extractAllVariables","Validate", minCorrelationValue);
% "numCamFields", 4 HOW TO USE, I HAVE 4 CAMERAS

if size(D.x,3) ~= num_images
    error("PIV not " + num_images + " frames!")
end

% mirror about y-axis
D.x = -D.x;

%% Compute summary statistics
% u_avg =  mean(u_field_frames,3);
% v_avg =  mean(v_field_frames,3);
w_avg = mean(D.w,3);
vort_avg = mean(D.vort,3);
corr_avg = mean(D.corr,3);

%% loading force data
daq_data_path = "R:\ENG_Breuer_Shared\rgissler\Calimero Data\Calimero 11_16_2025\Calimero\DAQ\data\";
exp_data_folder = daq_data_path + "experiment data\";
offsets_data_folder = daq_data_path + "offsets data\";

keys = {'2Hz_10AoA'};
values = ["PIV_0m.s_0deg_2Hz_2025-11-16 12-25-23_experiment_2025_11_16_12_27_36.mat",...
            ];
daq_dict = containers.Map(keys, values);
daq_data_filename = daq_dict('2Hz_10AoA');

[case_name, time_stamp, type, wing_freq, AoA, wind_speed] = parse_filename(daq_data_filename);

% Find matching offsets file
offsets_string = "before_offsets";
calibration_filepath = "../../DAQ/Calibration Files/Mini40/FT52907.cal";
cal_mat = obtain_cal(calibration_filepath);

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(offsets_data_folder, '*.mat');
offsets_files = dir(filePattern);

[offsets, offsets_filename] = findMatchingOffset...
    (offsets_files, offsets_string, wing_freq, AoA, wind_speed, type, time_stamp);

% Get raw data from file
load(exp_data_folder + daq_data_filename); % load in results var

ticksPerRev = 18432;
OC_pulse_step = 4;
[time_data, force_data, voltAdj, curAdj, enc_pulse, speed] = process_data(results, offsets, cal_mat, ticksPerRev, OC_pulse_step);

wing_pos = results(:,11) / (ticksPerRev / OC_pulse_step);

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
norm_wing_pos_frame = mod(wing_pos_frame,1);

num_bins = 50;
bins = linspace(0,1,num_bins);
bin_ind_arr = discretize(norm_wing_pos_frame, bins);
num_cycles = length(find(diff(bin_ind_arr) < 0)); % back to beginning of a cycle
disp("Number of cycles: " + num_cycles)
disp("Expected number of cycles: " + num_images / (200 / wing_freq))

bin_ind_arr = bin_ind_arr(1:num_images);
disp("Extra laser pulses: " + (length(bin_ind_arr) - num_images))

vort_phase_avg = zeros(size(D.x,1), size(D.x,2), num_bins);
for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    vort_phase_avg(i) = mean(D.vort(bin_indices));
end

%% Plotting
f2 = figure;
pcolor(D.x, D.y, vort_phase_avg);
ax = gca;
shading(ax, 'interp');
clim([-100 100]); colormap(ax,jet);
colorbar;
title('Streamwise vorticty')

save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
% Create the video file
v = VideoWriter(save_filepath + "vort_avg.mp4", 'MPEG-4');
v.FrameRate = 30;     % frames per second
open(v);

figure;
h = pcolor(D.x, D.y, vort_phase_avg(:,:,1));   % first frame of your data
ax = gca;
shading(ax, 'interp');
clim([-100 100]);
colormap(ax, jet);
colorbar;
title('Streamwise vorticity');

% --- Animation loop ---
for k = 1:num_bins
    % Update ONLY the CData
    set(h, 'CData', vort_phase_avg(:,:,k));
    
    drawnow;
    frame = getframe(gcf);
    writeVideo(v, frame);
end

% Close the file
close(v);