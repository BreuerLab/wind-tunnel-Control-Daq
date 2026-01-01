% Author: Ronan Gissler
% Last updated: October 2023

% Inputs: 
% file - filename of trial to process
% raw_data_path - relative path to access existing experiment
%                 data from (.csv files)
% processed_data_path - relative path to the location where the
%                       processed data will be stored (.mat files)

% Outputs:
% A .mat file is produced in the directory described by processed_data_path
% containing a number of variables whose contents describe the results of
% the experiment in more ways than simply the raw data does.
function process_trial(file, raw_data_path, offsets_path, processed_data_path, wind_tunnel_path)

[case_name, time_stamp, type, wing_freq, AoA, wind_speed, amp, ~] = parse_filename(file);

% NUM_WINGBEATS IS CURRENTLY NOT 180 EXACTLY SINCE JUST USING PWM
[frame_rate, num_wingbeats, rec_wingbeats, ticksPerRev, OC_pulse_step] = get_sampling_info(wing_freq);

% Get force calibration file
calibration_filepath = "../../DAQ/Calibration Files/Mini40/FT52907.cal"; 
cal_matrix = obtain_cal(calibration_filepath);

% UNCOMMENT !!!!!!!!!!!!!!!!!!!!!!!
% find matching offsets file
offsets_file = findInitialOffsetsFile(offsets_path, case_name);
load(offsets_path + offsets_file); % load in results var
offsets = offsets(1,:);
disp("Matching offsets: " + offsets_file)

% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% filePattern = fullfile(offsets_path, '*.mat'); % Change to whatever pattern you need.
% offsets_files = [];
% for i = 1:length(filePattern)
%     offsets_files = [offsets_files; dir(filePattern(i))];
% end
% 
% offsets_string = "before_offsets";
% [offsets_cur, offsets_cur_filename] = findMatchingOffset...
% (offsets_files, offsets_string, wing_freq, AoA, wind_speed, type, time_stamp);
% disp("Current offsets: " + offsets_cur_filename)
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

% Get raw data from file
load(raw_data_path + file); % load in results var

if (wing_freq == 0)
% for gliding case, trim off first and last second of data
trimmed_results = results(frame_rate:end-frame_rate,:);
else
% trim off period when acceleration + padding
trimmed_results = trim_data(results, rec_wingbeats, num_wingbeats);
end

% REPLACE WITH PROPER TRIMMING!!!!!!!!!!!!!!!!!!!!!!!
% trimmed_results = results;
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

[time_data, force_data, voltAdj, curAdj, enc_pulse, OC_pulse_count] = ...
    process_data(trimmed_results, offsets, cal_matrix, ticksPerRev, OC_pulse_step);

dt = time_data(2) - time_data(1);
% speed = gradient(results(:,11), dt)

order = 3;
framelen = 21;
speed = savitskyGolayDiff(OC_pulse_count, order, framelen, dt);
speed = speed / (ticksPerRev / OC_pulse_step);

% Rotate the data from the force transducer reference frame to the wind
% tunnel reference frame (body frame to global frame)
results_lab = coordinate_transformation(force_data, AoA);

% enc_pulse not added because this is the only data that is filtered
mod_results = [results_lab; voltAdj'; curAdj'];

% motor model check
% if wing_freq ~= 0
%     motor_model(time_data, voltAdj, curAdj, wing_freq, speed);
% end

% Non-dimensionalize the data. Newtons to Force Coefficients and
% Newton*meters to Moment Coefficients
[norm_data, norm_factors, St, Re] = non_dimensionalize_data(wind_tunnel_path, results_lab, file);

% Smooth the data with a butterworth filter
% fc = 100; % cutoff frequency
if (wing_freq > 1)
    % fc = 10*wing_freq; % cutoff frequency
    fc = 10*wing_freq; % cutoff frequency
else
    fc = 10;
end
filtered_data = filter_data(mod_results, frame_rate, fc);
% filtered_norm_data = filter_data(norm_data, frame_rate, fc);

if (wing_freq > 1)
    % fc = 10*wing_freq; % cutoff frequency
    fc = 5*wing_freq; % cutoff frequency
else
    fc = 10;
end
filtered_data_smoothest = filter_data(mod_results, frame_rate, fc);

% if (wing_freq > 1)
%     fc = 5*wing_freq; % cutoff frequency
% else
%     fc = 5;
% end
% % downsample from 9 kHz to 3 kHz so that low order filter works
% % change to using a FIR filter for numerical stability?
% down_sampled_results = downsample(results_lab', 10)';
% filtered_data_smoothest = filter_data(down_sampled_results, frame_rate, fc);

% may add step to shift pitching moment
% filtered_data(:,5) = move_pitch(filtered_data(:,5));

filename = case_name + " " + time_stamp + ".mat"; % file name for processed data

saved_vars = {'time_data', 'force_data', 'results_lab',...
    'filtered_data','filtered_data_smoothest',...
    'norm_factors', 'St', 'Re'};

% If this is a flapping trial, analyze data over each wingbeat rather than
% just in time
if (wing_freq > 0)
[wingbeat_forces_raw, frames_raw, wingbeat_avg_forces_raw, wingbeat_std_forces_raw,...
    wingbeat_rmse_forces_raw, wingbeat_max_forces_raw, wingbeat_min_forces_raw, wingbeat_COP_raw,...
    cycle_avg_forces_raw]...
    = wingbeat_transformation(num_wingbeats, mod_results, OC_pulse_count, speed, AoA);

[wingbeat_forces, frames, wingbeat_avg_forces, wingbeat_std_forces,...
    wingbeat_rmse_forces, wingbeat_max_forces, wingbeat_min_forces, wingbeat_COP,...
    cycle_avg_forces]...
    = wingbeat_transformation(num_wingbeats, filtered_data, OC_pulse_count, speed, AoA);

% [wingbeat_forces_smoother, frames_smoother, wingbeat_avg_forces_smoother, wingbeat_std_forces_smoother, ...
%     wingbeat_rmse_forces_smoother, wingbeat_max_forces_smoother, wingbeat_min_forces_smoother, ...
%     wingbeat_COP_smoother, cycle_avg_forces_smoother]...
%     = wingbeat_transformation(num_wingbeats, filtered_data_smooth, AoA);

[wingbeat_forces_smoothest, frames_smoothest, wingbeat_avg_forces_smoothest, wingbeat_std_forces_smoothest,...
    wingbeat_rmse_forces_smoothest, wingbeat_max_forces_smoothest, wingbeat_min_forces_smoothest, wingbeat_COP_smoothest,...
    cycle_avg_forces_smoothest]...
    = wingbeat_transformation(num_wingbeats, filtered_data_smoothest, OC_pulse_count, speed, AoA);

raw_wing_vars = {'wingbeat_forces_raw', 'frames_raw',...
    'wingbeat_avg_forces_raw', 'wingbeat_std_forces_raw',...
    'wingbeat_rmse_forces_raw', 'wingbeat_max_forces_raw',...
    'wingbeat_min_forces_raw', 'wingbeat_COP_raw', ...
    'cycle_avg_forces_raw'}; % 'upstroke_avg_forces_raw', 'downstroke_avg_forces'

filt_wing_vars = {'wingbeat_forces','frames',...
    'wingbeat_avg_forces', 'wingbeat_std_forces',...
    'wingbeat_rmse_forces', 'wingbeat_max_forces',...
    'wingbeat_min_forces', 'wingbeat_COP', ...
    'cycle_avg_forces'}; % 'upstroke_avg_forces', 'downstroke_avg_forces'

% filt_smooth_wing_vars = {'wingbeat_forces_smoother', 'frames_smoother',...
%     'wingbeat_avg_forces_smoother', 'wingbeat_std_forces_smoother',...
%     'wingbeat_rmse_forces_smoother', 'wingbeat_max_forces_smoother',...
%     'wingbeat_min_forces_smoother', 'wingbeat_COP_smoother', 'cycle_avg_forces_smoother'};

filt_smoothest_wing_vars = {'wingbeat_forces_smoothest', 'frames_smoothest',...
    'wingbeat_avg_forces_smoothest', 'wingbeat_std_forces_smoothest',...
    'wingbeat_rmse_forces_smoothest', 'wingbeat_max_forces_smoothest',...
    'wingbeat_min_forces_smoothest', 'wingbeat_COP_smoothest', ...
    'cycle_avg_forces_smoothest'}; % 'upstroke_avg_forces_smoothest', 'downstroke_avg_forces_smoothest'

vars = [saved_vars, raw_wing_vars, filt_wing_vars, filt_smoothest_wing_vars];

else
    vars = saved_vars;
end

disp("Saving " + processed_data_path + filename)
save(processed_data_path + filename, vars{:})
% else
%     cycle_forces = reshape(results_lab, 6, length(results_lab)/24, 24);
%     cycle_avg_forces = squeeze(mean(cycle_forces,2));
% 
%     vars = [saved_vars 'cycle_avg_forces'];
%     save(processed_data_path + filename, vars{:})
% end

% if (wing_freq > 0)
% % ------------------------------------------------------------
% 
% idx = 1;
% mean_results = wingbeat_avg_forces(idx,:);
% std_results = wingbeat_SD_forces(idx,:);
% lower_results = mean_results - std_results;
% upper_results = mean_results + std_results;
% 
% original_color = "#7f2704"; % hex, some dark red
% lighter_color = getLightColor(original_color); % RGB
% 
% xconf = [frames, frames(end:-1:1)];
% yconf = [upper_results, lower_results(end:-1:1)];
% 
% figure
% ax = gca;
% hold on
% p = fill(ax, xconf, yconf, lighter_color);
% p.HandleVisibility = 'off';
% p.EdgeColor = 'none';
% 
% l= plot(ax, frames, wingbeat_avg_forces(idx, :));
% l.Color = original_color;
% l.LineWidth = 2;
% title("Drag")
% 
% % ---------------------------------------------------------
% 
% idx = 3;
% mean_results = wingbeat_avg_forces(idx,:);
% std_results = wingbeat_SD_forces(idx,:);
% lower_results = mean_results - std_results;
% upper_results = mean_results + std_results;
% 
% original_color = "#7f2704"; % hex, some dark red
% lighter_color = getLightColor(original_color); % RGB
% 
% xconf = [frames, frames(end:-1:1)];
% yconf = [upper_results, lower_results(end:-1:1)];
% 
% figure
% ax = gca;
% hold on
% p = fill(ax, xconf, yconf, lighter_color);
% p.HandleVisibility = 'off';
% p.EdgeColor = 'none';
% 
% l= plot(ax, frames, wingbeat_avg_forces(idx, :));
% l.Color = original_color;
% l.LineWidth = 2;
% title("Lift")
% 
% % ---------------------------------------------------------
% end
end