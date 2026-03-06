clear
close all

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))
addpath(genpath('C:\Users\rgissler\Documents\MATLAB')) % readimx path

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% keys = {'2Hz_A20_10AoA', '4Hz_A20_10AoA', '6Hz_A20_10AoA', '8Hz_A20_10AoA',...
%         '2Hz_A30_10AoA', '4Hz_A30_10AoA',...
%         '2Hz_A10_10AoA','4Hz_A10_10AoA','6Hz_A10_10AoA', '8Hz_A10_10AoA',...
%         'r_2Hz_A10_10AoA', 'r_4Hz_A10_10AoA', 'r_6Hz_A10_10AoA', 'r_8Hz_A10_10AoA'};

turbine_bool = false;
% PIV_case_name = 'turbine';
% PIV_case_name = 'flexible_20deg_2Hz';
PIV_case_name = 'flexible_20deg_6Hz';
% PIV_case_name = 'UP_one_flexible_20deg_6Hz';
L = 0.07; % characteristic length, guess of mean aerodynamic chord
if turbine_bool
    U = 6;
else
    U = 4; % characteristic windspeed, freestream
end
save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
save_filepath_local = "Y:\Processed Results\";
num_images = 2500;

readimx_bool = true; % Read data from readimx or from saved .mat
nondim_bool = true;
phase_avg_plot_bool = true;
circ_plot_bool = false;
movie_plot_bool = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% if readimx_bool
% 
% [x, y, z, u, v, w, vortX, vortY, vortZ, uncTot] = import_STB_data(PIV_case_name, nondim_bool, U, L);
% 
% % vars = {'x','y','z','u','v','w','vortX','vortY','vortZ','uncTot'};
% vars = {'x','y','z','vortX','vortY','vortZ'};
% disp("Saving data to " + save_filepath + "trimmed data\")
% save(save_filepath + "trimmed data\" + PIV_case_name + ".mat", vars{:})
% 
% % check variable size in GB
% info = whos('vortZ');
% sizeGB = info.bytes / 1024^3;
% 
% else
%     tic
%     file_name = save_filepath + "trimmed data\" + PIV_case_name + ".mat";
%     disp("Loading " + file_name)
%     load(file_name)
%     toc
% end

%% Time-averaged velocity fields
file_path = get_PIV_paths(PIV_case_name);
files = dir(fullfile(file_path,'*.vc7'));
num_files = length(files);
time_avg_bool = false;

if time_avg_bool
disp("Time Average: Loading file: " + file_path)
num_files = 200; % TEMPORARY LINE ---- DELETE
for i = 1:num_files
    [x, y, z, u, v, w, vortX, vortY, vortZ, uncTot] = import_STB_data(file_path, nondim_bool, U, L, i);

    if i == 1
        mean_u = zeros(size(x));
        mean_v = zeros(size(x));
        mean_w = zeros(size(x));
        mean_vortX = zeros(size(x));
        mean_vortY = zeros(size(x));
        mean_vortZ = zeros(size(x));
    end
    mean_u = mean_u + u;
    mean_v = mean_v + v;
    mean_w = mean_w + w;
    mean_vortX = mean_vortX + vortX;
    mean_vortY = mean_vortY + vortY;
    mean_vortZ = mean_vortZ + vortZ;

    if mod(i,100) == 0
        disp(['processed ',num2str(i),'/',num2str(num_files)])
    end
end

% Divide sum by length to calculate mean
mean_u = mean_u / num_files;
mean_v = mean_v / num_files;
mean_w = mean_w / num_files;
mean_vortX = mean_vortX / num_files;
mean_vortY = mean_vortY / num_files;
mean_vortZ = mean_vortZ / num_files;

params.zero = 0;
params.clims = [-0.1 0.1];
params.y_lab = '\boldmath$\frac{u}{U_{\infty}}$';
params.title = "Spanwise velocity";
PIV_plot(x(:,:,3), y(:,:,3), mean_u(:,:,3), params)

params.zero = 0;
params.clims = [-0.1 0.1];
params.y_lab = '\boldmath$\frac{v}{U_{\infty}}$';
params.title = "Vertical velocity";
PIV_plot(x(:,:,3), y(:,:,3), mean_v(:,:,3), params)

params.zero = 1;
params.clims = [0.9 1.1];
params.y_lab = '\boldmath$\frac{w}{U_{\infty}}$';
params.title = "Streamwise velocity";
PIV_plot(x(:,:,3), y(:,:,3), -mean_w(:,:,3), params)

params.zero = 0;
params.clims = [-0.5 0.5];
params.y_lab = '\boldmath$\frac{u}{U_{\infty}}$';
params.title = "Spanwise vorticity";
PIV_plot(x(:,:,3), y(:,:,3), mean_vortX(:,:,3), params)

params.zero = 0;
params.clims = [-0.5 0.5];
params.y_lab = '\boldmath$\frac{v}{U_{\infty}}$';
params.title = "Vertical vorticity";
PIV_plot(x(:,:,3), y(:,:,3), mean_vortY(:,:,3), params)

params.zero = 0;
params.clims = [-1 1];
params.y_lab = '\boldmath$\frac{w}{U_{\infty}}$';
params.title = "Streamwise vorticity";
PIV_plot(x(:,:,3), y(:,:,3), mean_vortZ(:,:,3), params)
end

% get bin number associated with each frame from DAQ measurements
[norm_frame_pos, bin_ind_arr, num_bins, cycle_freq] = frame_to_bin(PIV_case_name, num_images, turbine_bool);

phase_avg_bool = true;
if phase_avg_bool
disp("Phase Average: Loading file: " + file_path)

bin_count = zeros(1,num_bins);
bin_std = zeros(1,num_bins);

for i = 1:num_bins
    bin_indices = find(bin_ind_arr == i);
    % bin_indices_all{i} = bin_indices;
    bin_count(i) = length(bin_indices);
    bin_std(i) = std(norm_frame_pos(bin_indices)); % removed for turbine case
  
    [x, y, z, u, v, w, Utot, vortX, vortY, vortZ, vortTot, uncU, uncV, uncW, uncTot] = import_STB_data(file_path, nondim_bool, U, L, bin_indices);

    if i == 1
        vortX_phase_avg = zeros(size(x,1), size(x,2), size(x,3), num_bins);
        vortY_phase_avg = zeros(size(vortX_phase_avg));
        vortZ_phase_avg = zeros(size(vortX_phase_avg));
        vortTot_phase_avg = zeros(size(vortX_phase_avg));

        u_phase_avg = zeros(size(vortX_phase_avg));
        v_phase_avg = zeros(size(vortX_phase_avg));
        w_phase_avg = zeros(size(vortX_phase_avg));
        Utot_phase_avg = zeros(size(vortX_phase_avg));

        uncU_phase_avg = zeros(size(vortX_phase_avg));
        uncV_phase_avg = zeros(size(vortX_phase_avg));
        uncW_phase_avg = zeros(size(vortX_phase_avg));
        uncTot_phase_avg = zeros(size(vortX_phase_avg));

        % vort_phase_std = zeros(size(vortX_phase_avg));
        % u_phase_std = zeros(size(vortX_phase_avg));
        % v_phase_std = zeros(size(vortX_phase_avg));
        % w_phase_std = zeros(size(vortX_phase_avg));
    end

    % Calculate average for this bin
    vortX_phase_avg(:,:,:,i) = mean(vortX,4);
    vortY_phase_avg(:,:,:,i) = mean(vortY,4);
    vortZ_phase_avg(:,:,:,i) = mean(vortZ,4);
    vortTot_phase_avg(:,:,:,i) = mean(vortTot,4);

    u_phase_avg(:,:,:,i) = mean(u,4);
    v_phase_avg(:,:,:,i) = mean(v,4);
    w_phase_avg(:,:,:,i) = mean(w,4);
    Utot_phase_avg(:,:,:,i) = mean(Utot,4);

    uncU_phase_avg(:,:,:,i) = mean(uncU,4);
    uncV_phase_avg(:,:,:,i) = mean(uncV,4);
    uncW_phase_avg(:,:,:,i) = mean(uncW,4);
    uncTot_phase_avg(:,:,:,i) = mean(uncTot,4);


    if mod(i,5) == 0
        disp(['processed ',num2str(i),'/',num2str(num_bins)])
    end
end

dx = abs(x(2,1,1) - x(1,1,1));
dy = abs(y(1,2,1) - y(1,1,1));
dz = abs(z(1,1,2) - z(1,1,1));
% Q_phase_avg = calQlate(u_phase_avg, v_phase_avg, dx, dy);
[Qx,Qy,Qz,Q] = calQlate3D(u_phase_avg,v_phase_avg,w_phase_avg,dx,dy,dz);

% Save phase averaged data to .mat file
vars = {"L","U","cycle_freq","PIV_case_name","num_bins","bin_ind_arr","bin_count","bin_std",...
    "x","y","z","u_phase_avg","v_phase_avg","w_phase_avg","Utot_phase_avg",...
    "uncU_phase_avg","uncV_phase_avg","uncW_phase_avg","uncTot_phase_avg",...
    "vortX_phase_avg","vortY_phase_avg","vortZ_phase_avg","vortTot_phase_avg","Qx","Qy","Qz","Q"};
save(save_filepath_local + PIV_case_name + ".mat", vars{:})

% [B, I] = sort(norm_wing_pos_frame_tr);
% vortZ_sorted = vortZ(:,:,:,I);

net_u = zeros(1,num_bins);
net_v = zeros(1,num_bins);
net_w = zeros(1,num_bins);
for i = 1:num_bins
    net_u(i) = mean(u_phase_avg(:,:,:,i),"all");
    net_v(i) = mean(v_phase_avg(:,:,:,i),"all");
    net_w(i) = mean(w_phase_avg(:,:,:,i),"all");
end

% disp("Saving net w vel to " + save_filepath + "processed data\")
% save(save_filepath + "processed data\" + PIV_case_name + ".mat", "net_w")

figure
plot(net_u)
xlabel("Time")
ylabel("Average u velocity")

figure
plot(net_v)
xlabel("Time")
ylabel("Average v velocity")

figure
plot(net_w)
xlabel("Time")
ylabel("Average w velocity")
end
%% Plotting

folder = save_filepath + PIV_case_name;

if ~exist(folder, 'dir')
    mkdir(folder);
end

% figure
% bar(bin_count)
% xlabel("Bin number", FontSize=16)
% ylabel("Number of frames per bin", FontSize=16)
% exportgraphics(gcf, folder + "\phase_avg_bin_histogram.png", 'Resolution', 300);
% 
% figure
% bar(bin_std)
% xlabel("Bin number", FontSize=16)
% ylabel("Phase variability per bin", FontSize=16)
% exportgraphics(gcf, folder + "\phase_avg_bin_variability.png", 'Resolution', 300);

%% Vorticity

params.PIV_case_name = PIV_case_name;
params.save_filepath = save_filepath;
params.num_bins = num_bins;
% params.xlims = [-0.15 0.15];
% params.ylims = [-0.2 0.2];
params.xlims = [-2.14 2.14]; % roughly -0.15 to 0.15 meters
params.ylims = [-2.86 2.86]; % roughly -0.2 to 0.2 meters
z_ind = 3;


if phase_avg_plot_bool
params.zero = 0;
params.title = "Spanwise vorticity - phase averaged";
params.folder = "vortX_avg";
params.clims = [-1 1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), vortX_phase_avg(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Vertical vorticity - phase averaged";
params.folder = "vortY_avg";
params.clims = [-1 1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), vortY_phase_avg(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Streamwise vorticity - phase averaged";
params.folder = "vortZ_avg";
params.clims = [-1 1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), vortZ_phase_avg(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Spanwise Q - phase averaged";
params.folder = "Qx_avg";
params.clims = [0.01 0.1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), Qx(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Vertical Q - phase averaged";
params.folder = "Qy_avg";
params.clims = [0.01 0.1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), Qy(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Streamwise Q - phase averaged";
params.folder = "Qz_avg";
params.clims = [0.01 0.1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), Qz(:,:,z_ind,:), params)

% params.zero = 0;
% params.title = "Streamwise vorticity - sorted";
% params.folder = "vortZ_sorted";
% params.clims = [-1 1];
% params.num_bins = num_images;
% make_movie(x(:,:,3), y(:,:,3), vortZ_sorted(:,:,3,:), params)

% params.title = "Streamwise vorticity - Standard Deviation";
% params.folder = "vort_std";
% params.clims = [0 1];
% make_movie(x, y, vort_phase_std, params)

params.zero = 0;
params.title = "Spanwise velocity - Average";
params.folder = "u_avg";
params.clims = [-0.2 0.2];
make_movie(x(:,:,z_ind), y(:,:,z_ind), u_phase_avg(:,:,z_ind,:), params)

params.zero = 0;
params.title = "Vertical velocity - Average";
params.folder = "v_avg";
params.clims = [-0.2 0.2];
make_movie(x(:,:,z_ind), y(:,:,z_ind), v_phase_avg(:,:,z_ind,:), params)

params.zero = 1;
params.title = "Streamwise velocity - Average";
params.folder = "w_avg";
params.clims = [0.9 1.1];
% params.clims = [0.5 1.1];
make_movie(x(:,:,z_ind), y(:,:,z_ind), -w_phase_avg(:,:,z_ind,:), params)
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
% x_idx = find(x(1,:) > -1 & x(1,:) < 2.14);  % columns
% y_idx = find(y(:,1) > -2.86 & y(:,1) < 2.86);  % rows
% 
% x_tr = x(y_idx, x_idx);
% y_tr = y(y_idx, x_idx);
% u_tr = u_phase_avg(y_idx, x_idx,:);
% v_tr = v_phase_avg(y_idx, x_idx,:);
% vort_phase_avg_tr = vort_phase_avg(y_idx, x_idx,:);
% Q_phase_avg_tr = Q_phase_avg(y_idx, x_idx,:);
% w_phase_avg_tr = w_phase_avg(y_idx, x_idx,:);

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
% stack_vortices(x_tr, y_tr, vort_phase_avg_tr, Q_phase_avg_tr, wing_freq, params);
stack_vortices_3D(x(:,:,z_ind), y(:,:,z_ind), vortZ_phase_avg(:,:,z_ind,:), Qz(:,:,z_ind,:), cycle_freq, params)

figure
params.clims = [-1 1];
params.zero = 0;
params.movie = false;
params.L = L;
params.shift = -7;
params.isoValue = 0.05; % 0.05
% stack_vortices(x_tr, y_tr, vort_phase_avg_tr, Q_phase_avg_tr, wing_freq, params);
stack_vortices_3D(x(:,:,z_ind), y(:,:,z_ind), vortY_phase_avg(:,:,z_ind,:), Qy(:,:,z_ind,:), cycle_freq, params)

figure
params.clims = [-1 1];
params.zero = 0;
params.movie = false;
params.L = L;
params.shift = -7;
params.isoValue = 0.05; % 0.05
% stack_vortices(x_tr, y_tr, vort_phase_avg_tr, Q_phase_avg_tr, wing_freq, params);
stack_vortices_3D(x(:,:,z_ind), y(:,:,z_ind), vortX_phase_avg(:,:,z_ind,:), Qx(:,:,z_ind,:), cycle_freq, params)

ax = gca;
ax.XAxisLocation = 'bottom';   % 'left' or 'right'
ax.YAxisLocation = 'right';   % 'left' or 'right'

% XZ view
view([0 -1 0])   % camera along +Y direction
% camup([1 0 0])  % keep Z vertical

file_name = "phase_avg_stacked_XZ_vortZ";
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
