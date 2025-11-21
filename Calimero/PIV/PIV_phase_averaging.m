clear
close all
addpath(genpath('../../'))
addpath(genpath('.'))
addpath(genpath('C:\Users\rgissler\Documents\MATLAB'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PIV_case_name = '2Hz_A20_10AoA';
L = 0.07; % characteristic length, guess of mean aerodynamic chord
U = 4; % characteristic windspeed, freestream
save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
readimx_bool = true;
num_images = 2500;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if readimx_bool

% minCorrelationValue = 0.2;

keys = {'2Hz_A20_10AoA', '4Hz_A20_10AoA', '6Hz_A20_10AoA', '8Hz_A20_10AoA',...
        '2Hz_A30_10AoA', '4Hz_A30_10AoA',...
        '2Hz_A10_10AoA','4Hz_A10_10AoA'};
values = ["R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\2Hz_10AoA_01\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
          "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\4Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
          "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\6Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
          "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\8Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
           ...
          "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_18_2025\flexible_30_2Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
          "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_18_2025\flexible_30_4Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
           ...
          "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_18_2025\flexible_2Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
          "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_18_2025\flexible_4Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU"];
PIV_dict = containers.Map(keys, values);

file_path = PIV_dict(PIV_case_name);
D = loadpiv(file_path,"extractAllVariables"); % "Validate", minCorrelationValue
% "numCamFields", 4 HOW TO USE, I HAVE 4 CAMERAS

if size(D.u,3) ~= num_images
    error("PIV not " + num_images + " frames!")
end

% Non-dimensionalize variables
u_full = D.u/U;
v_full = D.v/U;
w_full = D.w/U;
vort_full = D.vort*L/U;
x_full = D.x/L;
y_full = D.y/L;
uncU = D.uncU/U;
uncV = D.uncV/U;
uncW = D.uncW/U;

% Trimming data down
xbounds = [-2.14 2.14]; % roughly -0.15 to 0.15 meters
ybounds = [-2.86 2.86]; % roughly -0.2 to 0.2 meters

x_idx = find(x_full(1,:) > xbounds(1) & x_full(1,:) < xbounds(2));  % columns
y_idx = find(y_full(:,1) > ybounds(1) & y_full(:,1) < ybounds(2));  % rows

x = x_full(y_idx, x_idx);
y = y_full(y_idx, x_idx);
u = u_full(y_idx, x_idx,:);
v = v_full(y_idx, x_idx,:);
w = w_full(y_idx, x_idx,:);
vort = vort_full(y_idx, x_idx,:);

init_size = size(x_full);
fin_size = size(x);
fprintf("Data trimmed from: (%d, %d) to (%d, %d)\n", ...
             init_size(1), init_size(2), fin_size(1), fin_size(2));

vars = {'x', 'y', 'u', 'v', 'w', 'vort'};
save(save_filepath + "trimmed data\" + PIV_case_name + "_data.mat", vars{:})

else
    tic
    load(save_filepath + "trimmed data\" + PIV_case_name + "_data.mat", vars{:})
    toc
end

%% loading force data
daq_data_paths = ["R:\ENG_Breuer_Shared\rgissler\Calimero Data\Calimero 11_16_2025\Calimero\DAQ\data\",...
                  "R:\ENG_Breuer_Shared\rgissler\Calimero Data\Calimero_11_18_2025\data\"];
daq_data_path = daq_data_paths(1);
exp_data_folder = daq_data_path + "experiment data\";
offsets_data_folder = daq_data_path + "offsets data\";

keys = {'2Hz_A20_10AoA', '4Hz_A20_10AoA', '6Hz_A20_10AoA', '8Hz_A20_10AoA',...
        '2Hz_A30_10AoA','4Hz_A30_10AoA'...
        '2Hz_A10_10AoA','4Hz_A10_10AoA','6Hz_A10_10AoA','8Hz_A10_10AoA'};
values = ["PIV_0m.s_0deg_2Hz_2025-11-16 12-25-23_experiment_2025_11_16_12_27_36.mat",...
          "PIV_0m.s_0deg_4Hz_2025-11-16 13-04-38_experiment_2025_11_16_13_05_58.mat",...
          "PIV_0m.s_0deg_6Hz_2025-11-16 13-35-20_experiment_2025_11_16_13_36_29.mat",...
          "PIV_0m.s_0deg_8Hz_2025-11-16 14-03-45_experiment_2025_11_16_14_04_45.mat",...
          ...
          "PIV_flexible_30_0m.s_0deg_2Hz_2025-11-18 18-53-17_experiment_2025_11_18_18_55_30.mat",...
          "PIV_flexible_30_0m.s_0deg_4Hz_2025-11-18 19-21-27_experiment_2025_11_18_19_22_47.mat",...
          ....
          "PIV_flexible_0m.s_0deg_2Hz_2025-11-18 16-55-04_experiment_2025_11_18_16_57_14.mat",...
          "PIV_flexible_0m.s_0deg_4Hz_2025-11-18 17-22-50_experiment_2025_11_18_17_24_13.mat",...
          "PIV_flexible_0m.s_0deg_6Hz_2025-11-18 17-52-13_experiment_2025_11_18_17_53_28.mat",...
          "PIV_flexible_0m.s_0deg_8Hz_2025-11-18 18-22-16_experiment_2025_11_18_18_23_19.mat"];
daq_dict = containers.Map(keys, values);
daq_data_filename = daq_dict(PIV_case_name);

[case_name, time_stamp, type, wing_freq, AoA, wind_speed] = parse_filename(daq_data_filename);

% Find matching offsets file
offsets_string = "before_offsets";
calibration_filepath = "../DAQ/Calibration Files/Mini40/FT52907.cal";
cal_mat = obtain_cal(calibration_filepath);

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(offsets_data_folder, '*.mat');
offsets_files = dir(filePattern);

try
[offsets, offsets_filename] = findMatchingOffset...
    (offsets_files, offsets_string, wing_freq, AoA, wind_speed, type, time_stamp);
catch
    error("Oops, no offsets found. Did you check that daq_data_path is correct?")
end

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

% 50 for 2 Hz, 45 for 4 Hz, 45 for 6 Hz, 23 for 8 Hz
num_bins = 50;
% num_bins = 25; % for 4 Hz
bins = linspace(0,1,num_bins+1);
bin_ind_arr = discretize(norm_wing_pos_frame, bins);
num_cycles = length(find(diff(bin_ind_arr) < 0)); % back to beginning of a cycle
disp("Number of cycles: " + num_cycles)
disp("Expected number of cycles: " + num_images / (200 / wing_freq))

disp("Extra laser pulses: " + (length(bin_ind_arr) - num_images))
bin_ind_arr = bin_ind_arr(1:num_images);

vort_phase_avg = zeros(size(x,1), size(x,2), num_bins);
u_phase_avg = zeros(size(vort_phase_avg));
v_phase_avg = zeros(size(vort_phase_avg));
w_phase_avg = zeros(size(vort_phase_avg));

vort_phase_std = zeros(size(x,1), size(x,2), num_bins);
u_phase_std = zeros(size(vort_phase_avg));
v_phase_std = zeros(size(vort_phase_avg));
w_phase_std = zeros(size(vort_phase_avg));

bin_count = zeros(1,num_bins);
bin_std = zeros(1,num_bins);
for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    bin_count(i) = length(bin_indices);
    bin_std(i) = std(norm_wing_pos_frame(bin_indices));

    vort_phase_avg(:,:,i) = mean(vort(:,:,bin_indices),3);
    u_phase_avg(:,:,i) = mean(u(:,:,bin_indices),3);
    v_phase_avg(:,:,i) = mean(v(:,:,bin_indices),3);
    w_phase_avg(:,:,i) = mean(w(:,:,bin_indices),3);

    vort_phase_std(:,:,i) = std(vort(:,:,bin_indices), 0, 3);
    u_phase_std(:,:,i) = std(u(:,:,bin_indices), 0, 3);
    v_phase_std(:,:,i) = std(v(:,:,bin_indices), 0, 3);
    w_phase_std(:,:,i) = std(w(:,:,bin_indices), 0, 3);
end



%% Plotting

folder = save_filepath + PIV_case_name;

if ~exist(folder, 'dir')
    mkdir(folder);
end

figure
bar(bin_count)
xlabel("Bin number")
ylabel("Number of frames per bin")
exportgraphics(gcf, folder + "\phase_avg_bin_histogram.png", 'Resolution', 300);

figure
bar(bin_std)
xlabel("Bin number")
ylabel("Phase variability per bin")
exportgraphics(gcf, folder + "\phase_avg_bin_variability.png", 'Resolution', 300);

%% Vorticity

dx = abs(x(1,2) - x(1,1));
dy = abs(y(2,1) - y(1,1));
Q_phase_avg = calQlate(u_phase_avg, v_phase_avg, dx, dy);

params.PIV_case_name = PIV_case_name;
params.save_filepath = save_filepath;
params.num_bins = num_bins;
% params.xlims = [-0.15 0.15];
% params.ylims = [-0.2 0.2];
params.xlims = [-2.14 2.14]; % roughly -0.15 to 0.15 meters
params.ylims = [-2.86 2.86]; % roughly -0.2 to 0.2 meters

params.zero = 0;
params.title = "Streamwise vorticity - Average";
params.folder = "vort_avg";
params.clims = [-1 1];
make_movie(x, y, vort_phase_avg, params)

params.title = "Streamwise vorticity - Standard Deviation";
params.folder = "vort_std";
params.clims = [0 1];
make_movie(x, y, vort_phase_std, params)

% params.title = "Spanwise velocity - Average";
% params.folder = "u_avg";
% params.clims = [-0.2 0.2];
% make_movie(x, y, u_phase_avg, params)

params.zero = 1;
params.title = "Streamwise velocity - Average";
params.folder = "w_avg";
params.clims = [0.9 1.1];
make_movie(x, y, w_phase_avg, params)

% params.title = "2D Q";
% params.folder = "Q";
% params.cmin = 150;
% params.cmax = 250;
% make_movie(x, y, Q_phase_avg, params)

% track region of Q that's greater than 10 and located to the right of
% x = 0 and that has some minimum size

% Trimming everything but tip vortex
x_idx = find(x(1,:) > 0 & x(1,:) < 2.14);  % columns
y_idx = find(y(:,1) > -2.86 & y(:,1) < 2.86);  % rows

x_tr = x(y_idx, x_idx);
y_tr = y(y_idx, x_idx);
u_tr = u_phase_avg(y_idx, x_idx,:);
v_tr = v_phase_avg(y_idx, x_idx,:);
vort_phase_avg_tr = vort_phase_avg(y_idx, x_idx,:);
Q_phase_avg_tr = Q_phase_avg(y_idx, x_idx,:);
w_phase_avg_tr = w_phase_avg(y_idx, x_idx,:);

% ----------------------------------------------------------------

params.title = "2D Q";
params.folder = "Q";
params.clims = [0.01 0.1];
make_movie_calc_circ(x_tr, y_tr, u_tr, v_tr, vort_phase_avg_tr, Q_phase_avg_tr, params)

%% Stack phase averaged frames together into a volume
folder = save_filepath + PIV_case_name + "\vort_avg_stacked\";

if ~exist(folder, 'dir')
    mkdir(folder);
end

figure
factor = 5;
ax = gca;
for i = 1:num_bins*factor
params.shift = i; % -7
stack_vortices(x_tr, y_tr, vort_phase_avg_tr, Q_phase_avg_tr, w_phase_avg_tr, wing_freq, params);

ax = gca;
ax.ZDir = 'reverse';  % inverts tick direction
ax.YAxisLocation = 'right';   % 'left' or 'right'

% YZ view
view([1 0 0])   % camera along +X direction
camup([0 1 0])  % keep Y vertical

drawnow;
filename = sprintf('frame_%04d.png', i);  
exportgraphics(gcf, folder + filename, 'Resolution', 300);
cla(ax)
end

fps = 25;
gif_name = "stacked_animated";
export_plot_gifs(folder, gif_name, fps)

% ------------------------------------------------------------------

figure
% params.clims = [-1 1];
% params.zero = 0;
params.zero = 1;
params.clims = [0.9 1.1];
params.movie = false;
params.L = L;
params.shift = 0;
stack_vortices(x_tr, y_tr, vort_phase_avg_tr, Q_phase_avg_tr, w_phase_avg_tr, wing_freq, params);

ax = gca;
ax.XAxisLocation = 'bottom';   % 'left' or 'right'
ax.YAxisLocation = 'right';   % 'left' or 'right'

% XZ view
view([0 1 0])   % camera along +Y direction
camup([1 0 0])  % keep Z vertical

exportgraphics(gcf, save_filepath + PIV_case_name + "\phase_avg_stacked_XZ.png", 'Resolution', 300);

% ------------------------------------------------------------------
% iso-ish view
% view([1 0.2 0.2]); % mostly along X, slight tilt in Y and Z
% camup([0 1 0]);    % keep Y pointing up

%% Streamwise velocity

% folder_name = PIV_case_name + "\w_vel\";
% 
% if ~exist(save_filepath + folder_name, 'dir')
%     mkdir(save_filepath + folder_name);
% end

% figure('Units','normalized','OuterPosition',[0.6292 0.0454 0.3667 0.8759]);
% h = pcolor(D.x, D.y, v_phase_avg(:,:,1));   % first frame of your data
% ax = gca;
% axis equal
% shading(ax, 'interp');
% xlim([-0.15 0.15])
% ylim([-0.2 0.2])
% % clim([3 5]);
% clim([-1 1]);
% colormap(ax, jet);
% colorbar;
% title('Streamwise vorticity');
% 
% % --- Animation loop ---
% for k = 1:num_bins
%     % Update ONLY the CData
%     set(h, 'CData', v_phase_avg(:,:,k));
% 
%     drawnow;
%     filename = sprintf('frame_%04d.png', k);  
%     exportgraphics(gcf, save_filepath + folder_name + filename, 'Resolution', 300);
% end
% 
% fps = 10;
% export_plot_gifs(save_filepath, PIV_case_name, fps)
