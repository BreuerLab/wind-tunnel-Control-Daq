clear
close all
addpath(genpath('../../'))

% minCorrelationValue = 0.3;

keys = {'0Hz_0AoA','0Hz_10AoA', '2Hz_10AoA', '0Hz_10AoA_v2', '0Hz_10AoA_rigid'};
values = ["R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\0Hz_0AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
        "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\0Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
        "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\2Hz_10AoA_01\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
        "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_18_2025\flexible_0Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
        "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_18_2025\rigid_0Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU"];
dict = containers.Map(keys, values);

case_name = '0Hz_0AoA';
file_path = dict(case_name);
disp("Loading file: " + file_path)
D = loadpiv(file_path,"extractAllVariables"); % "Validate", minCorrelationValue
% "numCamFields", 4 HOW TO USE, I HAVE 4 CAMERAS

%% Compute summary statistics
% u_avg =  mean(u_field_frames,3);
% v_avg =  mean(v_field_frames,3);
w_avg = mean(D.w,3,"omitnan");
vort_avg = mean(D.vort,3,"omitnan");
corr_avg = mean(D.corr,3,"omitnan");

xlims = [-0.15 0.15];
ylims = [-0.2 0.2];
%% Plot
f1 = figure;
pcolor(D.x, D.y, w_avg);
xlim(xlims)
ylim(ylims)
ax = gca;
shading(ax, 'interp');
clim([min(w_avg,[],'all') max(w_avg,[],'all')]);
colormap(ax, jet);
cb = colorbar;
ylabel(cb,'\boldmath$\bar{w}$','Interpreter','Latex','FontSize',16,'Rotation',0)
% ylabel(cb,'\boldmath$\frac{\bar{w}}{U_{\infty}}$','Interpreter','Latex','FontSize',16,'Rotation',0)
title('Streamwise velocity, <w>')

f2 = figure;
pcolor(D.x, D.y, vort_avg);
xlim(xlims)
ylim(ylims)
ax = gca;
shading(ax, 'interp');
vort_scale = 50;
colorbarpzn(-vort_scale, vort_scale); % , 'level', 21
title('Streamwise vorticty')

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

f3 = figure;
pcolor(D.x, D.y, corr_avg);
xlim(xlims)
ylim(ylims)
ax = gca;
shading(ax, 'interp');
clim([0.3 1]); colormap(ax,jet);
colorbar;
title('Average PIV correlation')

save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\Gliding Averages\";

if ~exist(save_filepath, 'dir')
    mkdir(save_filepath);
end

saveas(f1,save_filepath + case_name + "_w.fig")
saveas(f2,save_filepath + case_name + "_omega.fig")
exportgraphics(f2, save_filepath + case_name + "_omega.png", 'Resolution', 300);
saveas(f3,save_filepath + case_name + "_corr.fig")
disp("Saved 3 plots to " + save_filepath)