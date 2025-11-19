clear
close all
addpath(genpath('../../'))
addpath(genpath('.'))
addpath(genpath('C:\Users\rgissler\Documents\MATLAB'))

num_images = 2500;

% minCorrelationValue = 0.2;

keys = {'2Hz_10AoA', '4Hz_10AoA', '6Hz_10AoA', '8Hz_10AoA'};
values = ["R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\2Hz_10AoA_01\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
          "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\4Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
          "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\6Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
          "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\8Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU"];
PIV_dict = containers.Map(keys, values);

PIV_case_name = '2Hz_10AoA';
file_path = PIV_dict(PIV_case_name);
D = loadpiv(file_path,"extractAllVariables"); % "Validate", minCorrelationValue
% "numCamFields", 4 HOW TO USE, I HAVE 4 CAMERAS

if size(D.u,3) ~= num_images
    error("PIV not " + num_images + " frames!")
end

% mirror about y-axis
% D.x = flip(D.x,2);
% D.y = flip(D.y,2);
% D.u = flip(D.u,2);
% D.v = flip(D.v,2);
% D.w = flip(D.w,2);
% D.vort = flip(D.vort,2);
% D.corr = flip(D.corr,2);

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

keys = {'2Hz_10AoA', '4Hz_10AoA', '6Hz_10AoA', '8Hz_10AoA'};
values = ["PIV_0m.s_0deg_2Hz_2025-11-16 12-25-23_experiment_2025_11_16_12_27_36.mat",...
          "PIV_0m.s_0deg_4Hz_2025-11-16 13-04-38_experiment_2025_11_16_13_05_58.mat",...
          "PIV_0m.s_0deg_6Hz_2025-11-16 13-35-20_experiment_2025_11_16_13_36_29.mat",...
          "PIV_0m.s_0deg_8Hz_2025-11-16 14-03-45_experiment_2025_11_16_14_04_45.mat"];
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

% 50 for 2 Hz, 40 for 4 Hz, 20 for 8 Hz
num_bins = 50;
% num_bins = 25; % for 4 Hz
bins = linspace(0,1,num_bins+1);
bin_ind_arr = discretize(norm_wing_pos_frame, bins);
num_cycles = length(find(diff(bin_ind_arr) < 0)); % back to beginning of a cycle
disp("Number of cycles: " + num_cycles)
disp("Expected number of cycles: " + num_images / (200 / wing_freq))

disp("Extra laser pulses: " + (length(bin_ind_arr) - num_images))
bin_ind_arr = bin_ind_arr(1:num_images);

vort_phase_avg = zeros(size(D.x,1), size(D.x,2), num_bins);
u_phase_avg = zeros(size(vort_phase_avg));
v_phase_avg = zeros(size(vort_phase_avg));
w_phase_avg = zeros(size(vort_phase_avg));

vort_phase_std = zeros(size(D.x,1), size(D.x,2), num_bins);
u_phase_std = zeros(size(vort_phase_avg));
v_phase_std = zeros(size(vort_phase_avg));
w_phase_std = zeros(size(vort_phase_avg));

bin_count = zeros(1,num_bins);
bin_std = zeros(1,num_bins);
for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    bin_count(i) = length(bin_indices);
    bin_std(i) = std(norm_wing_pos_frame(bin_indices));

    vort_phase_avg(:,:,i) = mean(D.vort(:,:,bin_indices),3);
    u_phase_avg(:,:,i) = mean(D.u(:,:,bin_indices),3);
    v_phase_avg(:,:,i) = mean(D.v(:,:,bin_indices),3);
    w_phase_avg(:,:,i) = mean(D.w(:,:,bin_indices),3);

    vort_phase_std(:,:,i) = std(D.vort(:,:,bin_indices), 0, 3);
    u_phase_std(:,:,i) = std(D.u(:,:,bin_indices), 0, 3);
    v_phase_std(:,:,i) = std(D.v(:,:,bin_indices), 0, 3);
    w_phase_std(:,:,i) = std(D.w(:,:,bin_indices), 0, 3);
end

%% Plotting
save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";

figure
bar(bin_count)
xlabel("Bin number")
ylabel("Number of frames per bin")
exportgraphics(gcf, save_filepath + PIV_case_name + "\phase_avg_bin_histogram.png", 'Resolution', 300);

figure
bar(bin_std)
xlabel("Bin number")
ylabel("Phase variability per bin")
exportgraphics(gcf, save_filepath + PIV_case_name + "\phase_avg_bin_variability.png", 'Resolution', 300);

%% Vorticity

dx = abs(D.x(1,2) - D.x(1,1));
dy = abs(D.y(2,1) - D.y(1,1));
Q_phase_avg = calQlate(u_phase_avg, v_phase_avg, dx, dy);

params.PIV_case_name = PIV_case_name;
params.save_filepath = save_filepath;
params.num_bins = num_bins;

params.title = "Streamwise vorticity";
params.folder = "vort_avg";
params.cmin = -50;
params.cmax = 50;
make_movie(D.x, D.y, vort_phase_avg, params)

params.title = "Streamwise vorticity";
params.folder = "vort_std";
params.cmin = 0;
params.cmax = 50;
make_movie(D.x, D.y, vort_phase_std, params)

params.title = "2D Q";
params.folder = "Q";
params.cmin = 0;
params.cmax = 100;
make_movie(D.x, D.y, Q_phase_avg, params)

% track region of Q that's greater than 10 and located to the right of
% x = 0 and that has some minimum size

%% Stack phase averaged frames together into a volume
figure
wind_speed = 4;
dt = wing_freq / num_bins;
z = zeros(1, num_bins);
for k = 1:num_bins
    z(k) =  wind_speed * dt * k;
    h = contourf(D.x, D.y, vort_phase_avg(:,:,k), 71,'linestyle','none','ZLocation',z(k));  
end

% % --- Make each filled contour patch transparent ---
% patches = get(h, 'Children');      % get individual contour patches
% if iscell(patches), patches = vertcat(patches{:}); end
% 
% for p = 1:length(patches)
%     set(patches(p), 'FaceAlpha', 1);  % 0 (invisible) → 1 (opaque)
% end
view(3)

figure
Qthresh = 3;
for k = 1:num_bins
    z(k) =  wind_speed * dt * k;
    % h = contourf(D.x, D.y, vort_phase_avg(:,:,k), 71,'linestyle','none','ZLocation',z(k));
    contour(D.x, D.y, Q_phase_avg(:,:,k), [Qthresh Qthresh],'LineColor', 'y', 'LineWidth',3,'ZLocation',z(k));
    axis equal
    % shading(ax, 'interp');
    xlim([-0.15 0.15])
    ylim([-0.2 0.2])
    zlim([min(z) max(z)])
    xlabel("x [m]")
    ylabel("y [m]")
    % Xiaowei color map
    % min_vort = min(vort_phase_avg,[],'all');
    % max_vort = max(vort_phase_avg,[],'all');
    % vort_scale = max(abs([min_vort max_vort]));
    cb = colorbarpzn(params.cmin, params.cmax); % , 'level', 21
end
view(3)

% figure
% hold on
% for k = 1:num_bins
%     surf(D.x, D.y, z(k)*ones(size(D.x)), Q_phase_avg(:,:,k), ...
%          'EdgeColor','none');
% end
% colormap(jet)
% colorbar
% view(3)
% axis equal

z = zeros(1, num_bins);
for k = 1:num_bins
    z(k) =  wind_speed * dt * k;
end

% Create 3D grids
% [X, Y, Z] = ndgrid(D.x(1,:), D.y(1,:), z);

% x_idx = find(D.x(1,:) > -0.15 & D.x(1,:) < 0.15);  % columns
% Trimming everything but tip vortex
x_idx = find(D.x(1,:) > 0.025 & D.x(1,:) < 0.15);  % columns
y_idx = find(D.y(:,1) > -0.2 & D.y(:,1) < 0.2);  % rows

x_tr = D.x(y_idx, x_idx);
y_tr = D.y(y_idx, x_idx);
vort_phase_avg_tr = vort_phase_avg(y_idx, x_idx,:);
Q_phase_avg_tr = Q_phase_avg(y_idx, x_idx,:);

% manually shift z array so that red and blue portions align
% z = circshift(z,5);

[Ny, Nx] = size(x_tr);
Nz = length(z);

% Replicate along z
X = repmat(x_tr, [1 1 Nz]);       % Ny x Nx x Nz
Y = repmat(y_tr, [1 1 Nz]);       % Ny x Nx x Nz
Z = repmat(reshape(z, [1 1 Nz]), [Ny Nx 1]); % Ny x Nx x Nz

shift = -7;
Q_phase_avg_tr_s = circshift(Q_phase_avg_tr, [0 0 shift]);  % shift along the 3rd dimension (Z)
vort_phase_avg_tr_s = circshift(vort_phase_avg_tr, [0 0 shift]);  % shift along the 3rd dimension (Z)

isoValue = 100;
figure
s = isosurface(X, Y, Z, Q_phase_avg_tr_s, isoValue);
cData = interp3(X, Y, Z, vort_phase_avg_tr_s, s.vertices(:,1), s.vertices(:,2), s.vertices(:,3));
p = patch('Vertices', s.vertices, 'Faces', s.faces, ...
          'FaceVertexCData', cData, ...
          'FaceColor', 'interp', ...
          'EdgeColor', 'none');

% p = patch(s);
% isonormals(x,y,z,V,p)
view(3);
params.cmin = -50;
params.cmax = 50;
colorbarpzn(params.cmin, params.cmax); % , 'level', 21
xlabel("x [m]")
ylabel("y [m]")
zlabel("z [m]")
ax = gca;
ax.ZDir = 'reverse';  % inverts tick direction
ax.YAxisLocation = 'right';   % 'left' or 'right'

% figure
% scatter(s.vertices(:,2), s.vertices(:,3), 20, cData, 'filled')  % 20 = marker size
% xlabel('Y')
% ylabel('Z')
% 
% xProj = s.vertices(:,1);
% zProj = s.vertices(:,3);
% F = scatteredInterpolant(xProj, zProj, cData, 'natural', 'none');
% 
% nx = 200;  % number of grid points in X
% nz = 200;  % number of grid points in Z
% 
% xq = linspace(min(xProj), max(xProj), nx);
% zq = linspace(min(zProj), max(zProj), nz);
% 
% [Xq, Zq] = meshgrid(xq, zq);
% 
% Cq = F(Xq, Zq);
% 
% figure
% imagesc(xq, zq, Cq)
% set(gca, 'YDir', 'normal')  % so Z increases upwards
% axis equal
% xlabel('X')
% ylabel('Z')
% colormap(jet)
% colorbar

% iso-ish view
% view([1 0.2 0.2]); % mostly along X, slight tilt in Y and Z
% camup([0 1 0]);    % keep Y pointing up

% YZ view
view([1 0 0])   % camera along +X direction
camup([0 1 0])  % keep Y vertical

isoValue = 100;
figure
s = isosurface(X, Y, Z, Q_phase_avg_tr_s, isoValue);
cData = interp3(X, Y, Z, vort_phase_avg_tr_s, s.vertices(:,1), s.vertices(:,2), s.vertices(:,3));
p = patch('Vertices', s.vertices, 'Faces', s.faces, ...
          'FaceVertexCData', cData, ...
          'FaceColor', 'interp', ...
          'EdgeColor', 'none');

% p = patch(s);
% isonormals(x,y,z,V,p)
view(3);
params.cmin = -50;
params.cmax = 50;
colorbarpzn(params.cmin, params.cmax); % , 'level', 21
xlabel("x [m]")
ylabel("y [m]")
zlabel("z [m]")
ax = gca;
ax.XAxisLocation = 'bottom';   % 'left' or 'right'
ax.YAxisLocation = 'right';   % 'left' or 'right'

% XZ view
view([0 1 0])   % camera along +Y direction
camup([1 0 0])  % keep Z vertical

% set(p,'FaceColor',[0.5 1 0.5]);  
% set(p,'EdgeColor','none');

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

%% 
% Make video with video writer

% % Create the video file
% v = VideoWriter(save_filepath + "vort_avg.mp4", 'MPEG-4');
% v.Quality = 100;   % max quality
% v.FrameRate = 10;     % frames per second
% open(v);
% 
% % f = figure('Units','normalized','OuterPosition',[0 0 1 1]);
% f = figure('Units','normalized','OuterPosition',[0.6292 0.0454 0.3667 0.8759]);
% h = pcolor(D.x, D.y, vort_phase_avg(:,:,1));   % first frame of your data
% ax = gca;
% axis equal
% shading(ax, 'interp');
% xlim([-0.15 0.15])
% ylim([-0.25 0.23])
% clim([-100 100]);
% colormap(ax, jet);
% colorbar;
% title('Streamwise vorticity');
% 
% % --- Animation loop ---
% for k = 1:num_bins
%     % Update ONLY the CData
%     set(h, 'CData', vort_phase_avg(:,:,k));
% 
%     drawnow;
%     frame = getframe(gcf);
%     writeVideo(v, frame);
% end
% 
% % Close the file
% close(v);