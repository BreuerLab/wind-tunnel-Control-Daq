clear
close all
addpath(genpath('../../'))

minCorrelationValue = 0.3;

keys = {'0Hz_0AoA','0Hz_10AoA', '2Hz_10AoA'};
values = ["R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\0Hz_0AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
        "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\0Hz_10AoA\StereoPIV_MPd(4x16x16_50%ov)_GPU",...
        "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Calimero_11_16_2025\2Hz_10AoA_01\StereoPIV_MPd(4x16x16_50%ov)_GPU"];
dict = containers.Map(keys, values);

case_name = '0Hz_10AoA';
file_path = dict(case_name);
D = loadpiv(file_path,"extractAllVariables","Validate", minCorrelationValue);
% "numCamFields", 4 HOW TO USE, I HAVE 4 CAMERAS

% mirror about y-axis
D.x = -D.x;

%% Compute summary statistics
% u_avg =  mean(u_field_frames,3);
% v_avg =  mean(v_field_frames,3);
w_avg = mean(D.w,3);
vort_avg = mean(D.vort,3);
corr_avg = mean(D.corr,3);

%% Plot
f1 = figure;
pcolor(D.x, D.y, w_avg);
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
ax = gca;
shading(ax, 'interp');
clim([-100 100]); colormap(ax,jet);
colorbar;
title('Streamwise vorticty')

f3 = figure;
pcolor(D.x, D.y, corr_avg);
ax = gca;
shading(ax, 'interp');
clim([minCorrelationValue 1]); colormap(ax,jet);
colorbar;
title('Average PIV correlation')

save_filepath = "R:\ENG_Breuer_Shared\rgissler\Calimero Flow Viz\Processed Results\";
saveas(f1,save_filepath + case_name + "_w.fig")
saveas(f2,save_filepath + case_name + "_omega.fig")
saveas(f3,save_filepath + case_name + "_corr.fig")
disp("Saved 3 plots to " + save_filepath)