clear
close all

% Change current working directory to the directory where this file is
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../'))
addpath(genpath('.'))
addpath(genpath('C:\Users\rgissler\Documents\MATLAB')) % readimx path

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ----------------------- Parameter Selection ------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Want to know what case names are available?
% Call "  case_names = get_case_names();  "
PIV_case_name = 'UP_two_flexible_30deg_6Hz';
% PIV_case_name = 'ring';

save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
save_filepath_local = "Y:\Processed Results\";

avg_type = 1; % 0 - time average, 1 - phase average

nondim_bool = true; % non-dimensionalize data

% If you want to make plots here, you can. However, it is NOT recommended.
% Intead, use main_analysis to produce plots easily in a GUI interface.
plot_bool = false;

circ_plot_bool = false;
movie_plot_bool = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------ Dependent parameters --------------------------
if contains(PIV_case_name,"turbine")
    turbine_bool = true;
else
    turbine_bool = false;
end

% characteristic windspeed (freestream) and characteristic length
if turbine_bool
    U = 6;
    L = 0.07; % temp value, replace with diameter of turbine
else
    U = 4;
    L = 0.07; % guess of mean aerodynamic chord
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Time-averaged velocity fields
file_path = get_PIV_paths(PIV_case_name);
files = dir(fullfile(file_path,'*.vc7'));
num_files = length(files);

switch avg_type
    case 0
        disp("Time Average: Loading file: " + file_path)
        num_files = 1000; % TEMPORARY LINE ---- DELETE
        S = time_avg_STB(file_path, nondim_bool, U, L, num_files, save_filepath_local, PIV_case_name);
        
        if plot_bool
            time_avg_plots(S);
        end
    case 1
        disp("Phase Average: Loading file: " + file_path)
        tic
        S = phase_avg_STB(file_path, nondim_bool, U, L, save_filepath_local, PIV_case_name, turbine_bool);
        toc

        if plot_bool
            error("Plotting phase averaged results not currently supported")
            phase_avg_plots(S);
        end
end
return

% [B, I] = sort(norm_wing_pos_frame_tr);
% vortZ_sorted = vortZ(:,:,:,I);

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
