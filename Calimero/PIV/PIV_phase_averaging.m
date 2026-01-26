clear
close all

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))
addpath(genpath('C:\Users\rgissler\Documents\MATLAB'))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% keys = {'2Hz_A20_10AoA', '4Hz_A20_10AoA', '6Hz_A20_10AoA', '8Hz_A20_10AoA',...
%         '2Hz_A30_10AoA', '4Hz_A30_10AoA',...
%         '2Hz_A10_10AoA','4Hz_A10_10AoA','6Hz_A10_10AoA', '8Hz_A10_10AoA',...
%         'r_2Hz_A10_10AoA', 'r_4Hz_A10_10AoA', 'r_6Hz_A10_10AoA', 'r_8Hz_A10_10AoA'};

PIV_case_name = '2Hz_A20_10AoA';
L = 0.07; % characteristic length, guess of mean aerodynamic chord
U = 4; % characteristic windspeed, freestream
save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
num_images = 2500;

readimx_bool = false; % Read data from readimx or from saved .mat
phase_avg_plot_bool = false;
circ_plot_bool = false;
movie_plot_bool = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if readimx_bool

% minCorrelationValue = 0.2;

file_path = get_PIV_paths(PIV_case_name);

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
disp("Saving data to " + save_filepath + "trimmed data\")
save(save_filepath + "trimmed data\" + PIV_case_name + ".mat", vars{:})

else
    tic
    file_name = save_filepath + "trimmed data\" + PIV_case_name + ".mat";
    disp("Loading " + file_name)
    load(file_name)
    toc
end

%% Time-averaged velocity fields
% Calculate mean values across time
mean_u = mean(u,3);
mean_v = mean(v,3);
mean_w = mean(w,3);

params.zero = 0;
params.clims = [-0.1 0.1];
params.y_lab = '\boldmath$\frac{u}{U_{\infty}}$';
params.title = "Spanwise velocity";
PIV_plot(x, y, mean_u, params)

params.zero = 0;
params.clims = [-0.1 0.1];
params.y_lab = '\boldmath$\frac{v}{U_{\infty}}$';
params.title = "Vertical velocity";
PIV_plot(x, y, mean_v, params)

params.zero = 1;
params.clims = [0.9 1.1];
params.y_lab = '\boldmath$\frac{w}{U_{\infty}}$';
params.title = "Streamwise velocity";
PIV_plot(x, y, mean_w, params)

%% loading force data
[daq_data_filename, daq_data_path] = get_daq_paths(PIV_case_name);

exp_data_folder = daq_data_path + "experiment data\";
offsets_data_folder = daq_data_path + "offsets data\";

[case_name, time_stamp, type, wing_freq, AoA, wind_speed, amp, file_type] = parse_filename(daq_data_filename);

% Find matching offsets file
offsets_string = "before_offsets";
calibration_filepath = "../DAQ/Calibration Files/Mini40/FT52907.cal";
cal_mat = obtain_cal(calibration_filepath);

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(offsets_data_folder, '*.mat');
offsets_files = dir(filePattern);

% try
[offsets, offsets_filename] = findMatchingOffset...
    (offsets_files, offsets_string, wing_freq, amp, AoA, wind_speed, type, time_stamp);
% catch
%     error("Oops, no offsets found. Did you check that daq_data_path is correct?")
% end

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
% num_bins = 50;
keys = {2, 4, 6, 8};
num_bins_opts = [50, 45, 45, 23];
bins_dict = containers.Map(keys, num_bins_opts);
num_bins = bins_dict(wing_freq);

disp("Using " + num_bins + " bins")
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
% bin_indices_all = {};
for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    % bin_indices_all{i} = bin_indices;
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

net_w = zeros(1,num_bins);
for i = 1:num_bins
    net_w(i) = mean(w_phase_avg(:,:,i),"all");
end

disp("Saving net w vel to " + save_filepath + "processed data\")
save(save_filepath + "processed data\" + PIV_case_name + ".mat", "net_w")

figure
plot(net_w)
xlabel("Time")
ylabel("Average w velocity")

%% Plotting

folder = save_filepath + PIV_case_name;

if ~exist(folder, 'dir')
    mkdir(folder);
end

figure
bar(bin_count)
xlabel("Bin number", FontSize=16)
ylabel("Number of frames per bin", FontSize=16)
exportgraphics(gcf, folder + "\phase_avg_bin_histogram.png", 'Resolution', 300);

figure
bar(bin_std)
xlabel("Bin number", FontSize=16)
ylabel("Phase variability per bin", FontSize=16)
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

if phase_avg_plot_bool
params.zero = 0;
params.title = "Streamwise vorticity - phase averaged";
params.folder = "vort_avg";
params.clims = [-1 1];
make_movie(x, y, vort_phase_avg, params)

params.title = "Streamwise vorticity - Standard Deviation";
params.folder = "vort_std";
params.clims = [0 1];
make_movie(x, y, vort_phase_std, params)

params.title = "Spanwise velocity - Average";
params.folder = "u_avg";
params.clims = [-0.2 0.2];
make_movie(x, y, u_phase_avg, params)

params.title = "Vertical velocity - Average";
params.folder = "v_avg";
params.clims = [-0.2 0.2];
make_movie(x, y, v_phase_avg, params)

params.zero = 1;
params.title = "Streamwise velocity - Average";
params.folder = "w_avg";
params.clims = [0.9 1.1];
make_movie(x, y, w_phase_avg, params)
end

% params.title = "2D Q";
% params.folder = "Q";
% params.cmin = 150;
% params.cmax = 250;
% make_movie(x, y, Q_phase_avg, params)

% track region of Q that's greater than 10 and located to the right of
% x = 0 and that has some minimum size

% Trimming everything but tip vortex
% x_idx = find(x(1,:) > 0.4 & x(1,:) < 2.14);  % columns
x_idx = find(x(1,:) > -1 & x(1,:) < 2.14);  % columns
y_idx = find(y(:,1) > -2.86 & y(:,1) < 2.86);  % rows

x_tr = x(y_idx, x_idx);
y_tr = y(y_idx, x_idx);
u_tr = u_phase_avg(y_idx, x_idx,:);
v_tr = v_phase_avg(y_idx, x_idx,:);
vort_phase_avg_tr = vort_phase_avg(y_idx, x_idx,:);
Q_phase_avg_tr = Q_phase_avg(y_idx, x_idx,:);
w_phase_avg_tr = w_phase_avg(y_idx, x_idx,:);

% ----------------------------------------------------------------

if circ_plot_bool
params.title = "2D Q";
params.folder = "Q";
params.clims = [0.01 0.1];
% make_movie_calc_circ(x_tr, y_tr, u_tr, v_tr, vort_phase_avg_tr, Q_phase_avg_tr, params)
make_movie_calc_circ(x, y, u, v, vort_phase_avg, Q_phase_avg, params)
end

%% Stack phase averaged frames together into a volume
folder = save_filepath + PIV_case_name + "\vort_avg_stacked\";

if ~exist(folder, 'dir')
    mkdir(folder);
end

% ------------------------------------------------------------------

figure
params.clims = [-1 1];
params.zero = 0;
params.movie = false;
params.L = L;
params.shift = -7;
params.isoValue = 0.05; % 0.05
stack_vortices(x_tr, y_tr, vort_phase_avg_tr, Q_phase_avg_tr, wing_freq, params);

ax = gca;
ax.XAxisLocation = 'bottom';   % 'left' or 'right'
ax.YAxisLocation = 'right';   % 'left' or 'right'

% XZ view
view([0 -1 0])   % camera along +Y direction
% camup([1 0 0])  % keep Z vertical

file_name = "phase_avg_stacked_XZ_vort";
saveas(gcf, folder + "\" + file_name + ".fig")
exportgraphics(gcf, folder + "\" + file_name + ".png", 'Resolution', 300);

% Same plot but color coded by streamwise velocity

figure
params.zero = 1;
params.clims = [0.9 1.1];
stack_vortices(x_tr, y_tr, w_phase_avg_tr, Q_phase_avg_tr, wing_freq, params);

ax = gca;
ax.XAxisLocation = 'bottom';   % 'left' or 'right'
ax.YAxisLocation = 'right';   % 'left' or 'right'

% XZ view
view([0 1 0])   % camera along +Y direction
% camup([1 0 0])  % keep Z vertical

file_name = "phase_avg_stacked_XZ_vel";
saveas(gcf, folder + "\" + file_name + ".fig")
exportgraphics(gcf, folder + "\" + file_name + ".png", 'Resolution', 300);

% ------------------------------------------------------------------

figure
params.clims = [-1 1];
params.zero = 0;
params.movie = false;
params.L = L;
params.shift = 0;
stack_vortices(x_tr, y_tr, vort_phase_avg_tr, Q_phase_avg_tr, wing_freq, params);

ax = gca;
ax.XAxisLocation = 'bottom';   % 'left' or 'right'
ax.YAxisLocation = 'right';   % 'left' or 'right'

% YZ view
view([1 0 0])   % camera along +X direction
% camup([0 1 0])  % keep Y vertical

exportgraphics(gcf, folder + "\phase_avg_stacked_YZ.png", 'Resolution', 300);

% ------------------------------------------------------------------

figure
params.clims = [-1 1];
params.zero = 0;
params.movie = false;
params.L = L;
params.shift = 0;
stack_vortices(x_tr, y_tr, vort_phase_avg_tr, Q_phase_avg_tr, wing_freq, params);

ax = gca;
ax.XAxisLocation = 'bottom';   % 'left' or 'right'
ax.YAxisLocation = 'right';   % 'left' or 'right'

% YZ view
view([0 0 1])   % camera along +X direction
% camup([0 1 0])  % keep Y vertical

exportgraphics(gcf, folder + "\phase_avg_stacked_XY.png", 'Resolution', 300);

% ------------------------------------------------------------------
% iso-ish view
% view([1 0.2 0.2]); % mostly along X, slight tilt in Y and Z
% camup([0 1 0]);    % keep Y pointing up

if movie_plot_bool
% Make movie by shifting 3D plot frame by frame
figure
factor = 5;
for i = 1:num_bins*factor
params.shift = i; % -7
params.movie = true;
stack_vortices(x_tr, y_tr, vort_phase_avg_tr, Q_phase_avg_tr, wing_freq, params);

ax = gca;
ax.ZDir = 'reverse';  % inverts tick direction
ax.YAxisLocation = 'right';   % 'left' or 'right'

% YZ view
view([1 0 0])   % camera along +X direction
camup([0 1 0])  % keep Y vertical
% view([0 -1 0])   % camera along +Y direction

drawnow;
filename = sprintf('frame_%04d.png', i);  
exportgraphics(gcf, folder + filename, 'Resolution', 300);
cla(ax)
end

fps = 25;
gif_name = "stacked_animated";
export_plot_gifs(folder, gif_name, fps)
end

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
