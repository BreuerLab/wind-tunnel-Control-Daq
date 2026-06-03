% use after StRe_extract.m
clc
clear
close all

% set default font sizes
set(0, 'DefaultAxesFontSize', 16);    % Sets everything except xline

% load data

cd(fileparts(mfilename('fullpath')));
addpath(genpath('../../../'))

DELIM = string(filesep);

h = helpdlg("Please select the StRe_data folder.");
uiwait(h);     % ensure the user reads it before continuing

% Open a file selection dialog and get the file path
if strcmp(DELIM, "\")
    data_path = uigetdir(".", "Select the StRe_data folder") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
else  % For Zachary's Mac to directly open file
    data_path = uigetdir("/Users/zjrosoff/Documents/GitHub/wind-tunnel-Control-Daq/Calimero/data analysis/processing/Zachary_files/wing_plot_LE_fullShift", "Select the StRe_data folder") + DELIM;
    if isequal(data_path, 0)
        disp('User canceled folder selection.');
    else
        disp(['Selected folder: ', data_path]);
    end
end

load(fullfile(data_path, 'StRe_data.mat'))

% Populate with St and Re target cases
target_St = [0.0000 0.051 0.077 0.10 0.026 0.039 0.092 0.14 0.18 ...
    0.046 0.069];
target_Re = [1.4E+04 2.9E+04 7.2E+03]; % assuming ~22.5 degrees C

%% Now Plotting Histograms

figure(1)
histogram(all_St, 'BinWidth', 0.001)
title('Strouhal Number Distribution')
xlabel('Trial Strouhal Number')
ylabel('Frequency')
for i=1:length(target_St)
xline(target_St(i), 'r', 'LineWidth', 1, 'LineStyle', '--', 'Label', strcat('St = ', string(target_St(i))))
    hold on
end
legend('Measured St', 'Target St', 'Location','bestoutside')

figure(2)
histogram(all_Re, 'BinWidth', 200);
title('Reynolds Number Distribution')
xlabel('Trial Reynolds Number')
ylabel('Frequency')
for i=1:length(target_Re)
    xline(target_Re(i), 'r', 'LineWidth', 1, 'LineStyle', '--', 'Label', strcat('Re = ', string(target_Re(i))))
    hold on
end
legend('Measured Re', 'Target Re', 'Location','bestoutside')


%% Now doing error bars

% STROUHAL ERROR BARS

error_St = zeros(length(target_St), 1); % populating error vector
mean_St = zeros(length(target_St), 1);
rel_std_dev_St = zeros(length(target_St), 1);
num_St = zeros(length(target_St), 1);
for i=1:length(target_St)
    idx = abs(all_St-target_St(i)) < 0.005;
    error_St(i) = std(all_St(idx)); % only using St within narrow band
    mean_St(i) = mean(all_St(idx));
    rel_std_dev_St(i) = (error_St(i)/mean_St(i))*100;
    num_St(i) = length(all_St(idx));
end

figure(3)
x_St = target_St; % target values
y_St = mean_St; % mean vaues
err_St = error_St; % standard deviation

errorbar(x_St, y_St, err_St, 'k.', 'MarkerFaceColor', 'k', 'LineStyle', 'none', 'CapSize', 8, 'MarkerSize', 12);
title('Strouhal Accuracy: Target vs. Measured')
xlabel('Target Strouhal Number')
ylabel('Measured Mean St (±1 SD)')
hold on

% to plot y=x of target_values (straight line below)
upper_limit_St = max(x_St)*1.1; 
plot([0 upper_limit_St],[0 upper_limit_St],'Color', 'r', 'LineWidth', 0.5, 'LineStyle', '--') % plotting target vs target to see how well my mean values match

legend('Measured Data', 'Ideal Match (1:1)', 'Location', 'NorthWest')
xlim([0 upper_limit_St])
ylim([0 upper_limit_St])
grid on

% Sort the results by Target St before table creation
% round to 4 because AFAM records to four decimals
[target_St_sorted, s_idx] = sort(target_St);
mean_St = round(mean_St, 2, 'significant');
err_St = round(err_St, 2, 'significant');
rel_std_dev_St = round(rel_std_dev_St, 2, 'significant');
St_table = table(target_St_sorted', mean_St(s_idx), err_St(s_idx), rel_std_dev_St(s_idx),...
    'VariableNames', {'Target St', 'Mean', 'Standard Deviation', 'Relative Standard Deviation [%]'});
disp(St_table);

% REYNOLDS ERROR BARS

error_Re = zeros(length(target_Re), 1); % populating error vector
mean_Re = zeros(length(target_Re), 1);
rel_std_dev_Re = zeros(length(target_Re), 1);
num_Re = zeros(length(target_Re), 1);
for i=1:length(target_Re)
    idx = abs(all_Re-target_Re(i)) < 1000;
    error_Re(i) = std(all_Re(idx)); % only using St within narrow band
    mean_Re(i) = mean(all_Re(idx));
    rel_std_dev_Re(i) = (error_Re(i)/mean_Re(i))*100;
    num_Re(i) = length(all_Re(idx));
end

figure(4)
x_Re = target_Re; % target values
y_Re = mean_Re; % mean vaues
err_Re = error_Re; % standard deviation

errorbar(x_Re, y_Re, err_Re, 'k.', 'MarkerFaceColor', 'k', 'LineStyle', 'none', 'CapSize', 8, 'MarkerSize', 12);
title('Reynolds Accuracy: Target vs. Measured')
xlabel('Target Reynolds Number')
ylabel('Measured Mean Re (±1 SD)')
hold on

% to plot y=x of target_values (straight line below)
upper_limit_Re = max(x_Re)*1.1; 
plot([0 upper_limit_Re],[0 upper_limit_Re],'Color', 'r', 'LineWidth', 0.5, 'LineStyle', '--') % plotting target vs target to see how well my mean values match

legend('Measured Data', 'Ideal Match (1:1)', 'Location', 'NorthWest')
xlim([0 upper_limit_Re])
ylim([0 upper_limit_Re])
grid on

% create table, round to 4 because AFAM records to four decimals
[target_Re_sorted, r_idx] = sort(target_Re);
mean_Re = round(mean_Re, 2, 'significant');
err_Re = round(err_Re, 2, 'significant');
rel_std_dev_Re = round(rel_std_dev_Re, 2, 'significant');
Re_table = table(target_Re_sorted', mean_Re(r_idx), err_Re(r_idx), rel_std_dev_Re(r_idx), ...
    'VariableNames', {'Target Re', 'Mean', 'Standard Deviation', 'Relative Standard Deviation [%]'});
disp(Re_table);

%% Save files

% save tables
writetable(St_table, 'St_error.csv');
writetable(Re_table, 'Re_error.csv');

% % Now creating a command that will save all 4 figures, using export
% % graphics for quality and cropping
% plotFolder = fullfile(data_path, 'StRe_Plots');
% if ~exist(plotFolder, 'dir')
%     mkdir(plotFolder);
% end
% 
% % List of figure numbers you want to save
% figHandles = [1, 2, 3, 4];
% figNames = ["St_Histogram", "Re_Histogram", "St_ErrorBars", "Re_ErrorBars"];
% 
% for k = 1:length(figHandles)
%     currentFig = figure(figHandles(k));
%     baseName = fullfile(plotFolder, figNames(k));
% 
%     % 1. Save as MATLAB .fig (for future editing)
%     saveas(currentFig, baseName + '.fig');
% 
%     % 2. Save as .png (for Word/PowerPoint)
%     % 'Resolution', 300 makes it high-definition
%     exportgraphics(currentFig, baseName + '.png', 'Resolution', 600);
% 
%     % 3. Save as .eps (Vector format for LaTeX or high-end publishing)
%     exportgraphics(currentFig, baseName + '.eps', 'ContentType', 'vector');
% 
%     fprintf('Saved Figure %d to %s\n', figHandles(k), plotFolder);
% end