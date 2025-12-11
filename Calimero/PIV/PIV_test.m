clear
close all
addpath(genpath('../../'))
addpath(genpath('.'))
addpath(genpath('C:\Users\rgissler\Documents\MATLAB'))

% minCorrelationValue = 0.3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PIV_case_name = '0Hz_10AoA_rigid';
L = 0.07; % characteristic length, guess of mean aerodynamic chord
U = 4; % characteristic windspeed, freestream
nondim_bool = true;
save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";

readimx_bool = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

keys = {'0Hz_0AoA','0Hz_10AoA', '2Hz_10AoA', '0Hz_10AoA_v2', '0Hz_10AoA_rigid'};
values = ["R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\0Hz_0AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
        "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\0Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
        "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\2Hz_10AoA_01\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
        "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_18_2025\flexible_0Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
        "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_18_2025\rigid_0Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU"];
dict = containers.Map(keys, values);

if readimx_bool
file_path = dict(PIV_case_name);
disp("Loading file: " + file_path)
D = loadpiv(file_path,"extractAllVariables"); % "Validate", minCorrelationValue

if nondim_bool % Non-dimensionalize variables
    u_full = D.u/U;
    v_full = D.v/U;
    w_full = D.w/U;
    vort_full = D.vort*(L/U);
    x_full = D.x/L;
    y_full = D.y/L;
    uncU = D.uncU/U;
    uncV = D.uncV/U;
    uncW = D.uncW/U;
else
    u_full = D.u;
    v_full = D.v;
    w_full = D.w;
    vort_full = D.vort;
    x_full = D.x;
    y_full = D.y;
    uncU = D.uncU;
    uncV = D.uncV;
    uncW = D.uncW;
end

uncTot = (uncU.^2 + uncV.^2 + uncW.^2).^(1/2);
corr = D.corr;

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

vars = {'x', 'y', 'u', 'v', 'w', 'vort', 'corr', 'uncTot'};
disp("Saving data to " + save_filepath + "trimmed data\")
save(save_filepath + "trimmed data\" + PIV_case_name + "_data.mat", vars{:})

else
    tic
    load(save_filepath + "trimmed data\" + PIV_case_name + "_data.mat")
    toc
end

%% Compute summary statistics
% u_avg =  mean(u_field_frames,3);
% v_avg =  mean(v_field_frames,3);
w_avg = mean(w,3,"omitnan");
vort_avg = mean(vort,3,"omitnan");
corr_avg = mean(D.corr,3,"omitnan");

%% Plot
f1 = figure;
% pcolor(D.x, D.y, w_avg);
contourf(x, y, w_avg, 71,'linestyle','none');
% xlim(xlims)
% ylim(ylims)
% ax = gca;
% shading(ax, 'interp');
cb = colorbarpzn(0.9, 1.1, 'full', 1, 'dft', 'pwg');
xlabel("y/c",FontSize=16)
ylabel("z/c",FontSize=16)
ylabel(cb,'\boldmath$\frac{\bar{w}}{U_{\infty}}$','Interpreter','Latex','FontSize',18,'Rotation',0)
title('Streamwise velocity, <w>',FontSize=18)

f2 = figure;
% pcolor(D.x, D.y, vort_avg);
contourf(x, y, vort_avg, 71,'linestyle','none');
% xlim(xlims)
% ylim(ylims)
% ax = gca;
% shading(ax, 'interp');
vort_scale = 1;
cb = colorbarpzn(-vort_scale, vort_scale); % , 'level', 21
ylabel(cb,'\boldmath$\frac{\omega c}{U_{\infty}}$','Interpreter','Latex','FontSize',18,'Rotation',0)
xlabel("y/c",FontSize=16)
ylabel("z/c",FontSize=16)
title('Streamwise vorticity',FontSize=18)

% grayscale + red colormap
nRed = 10; 
cmap = [gray(256); repmat([1 0 0], nRed, 1)];

f3 = figure;
pcolor(x, y, corr_avg);
ax = gca;
hold on
shading(ax, 'interp');
clim([0.4 0.6]); colormap(ax,cmap);
colorbar;

width = 0.3;
height = 0.45;
FOV_pos = [-0.17 -0.25 width height];
% FOV rectangle
rectangle('Position', FOV_pos, 'EdgeColor', 'k', 'LineWidth', 2)

% xlabel("y/c",FontSize=16)
% ylabel("z/c",FontSize=16)
xlabel("y (m)",FontSize=16)
ylabel("z (m)",FontSize=16)
title('Average PIV correlation',FontSize=18)

%% Mirror voriticty data

% % Duplicate and invert data about mid-body axis
% x0 = -0.14;
% [~, split_idx] = min(abs(D.x(1,:) - x0));
% closest_val = D.x(1,split_idx);
% % Set x0 as the new origin
% new_x = D.x - closest_val;
% 
% % right part of data
% vort_R = vort_avg(:, 1:split_idx, :);
% vort_R_M = -flip(vort_R, 2); % invert vorticity
% new_vort_avg = [vort_R_M vort_R];
% % new_vort_avg = [vort_R];
% 
% % Mirror and invert x-coordinates
% x_R = new_x(:, 1:split_idx);
% x_R_M = -flip(x_R, 2);
% new_x = [x_R_M x_R];
% % new_x = [x_R];
% 
% % Mirror y-coordinates
% y_R = D.y(:, 1:split_idx);
% y_R_M = flip(y_R, 2);
% new_y = [y_R_M y_R];
% % new_y = [y_R];
% 
% figure
% pcolor(new_x, new_y, new_vort_avg);
% ax = gca;
% shading(ax, 'interp');
% clim([-100 100]); colormap(ax,jet);
% colorbar;
% title('Streamwise vorticty')

% f3 = figure;
% pcolor(D.x, D.y, corr_avg);
% xlim(xlims)
% ylim(ylims)
% ax = gca;
% shading(ax, 'interp');
% clim([0.3 1]); colormap(ax,jet);
% colorbar;
% xlabel("y/c")
% ylabel("z/c")
% title('Average PIV correlation')

save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\Gliding Averages\";

if ~exist(save_filepath, 'dir')
    mkdir(save_filepath);
end

saveas(f1,save_filepath + PIV_case_name + "_w.fig")
saveas(f2,save_filepath + PIV_case_name + "_omega.fig")
exportgraphics(f2, save_filepath + PIV_case_name + "_omega.png", 'Resolution', 300);
% saveas(f3,save_filepath + PIV_case_name + "_corr.fig")
disp("Saved 2 plots to " + save_filepath)