clear
% close all

volt_idx = 7;
cur_idx = 8;
sel_idx = cur_idx;
% Options: "wingbeat_avg_forces_raw", "wingbeat_avg_forces",
% "wingbeat_avg_forces_smoother", "wingbeat_avg_forces_smoothest"
forces_to_plot = "wingbeat_avg_forces_raw";
vars = {"frames", "wingbeat_avg_forces_raw", "wingbeat_avg_forces",...
    "wingbeat_avg_forces_smoother", "wingbeat_avg_forces_smoothest",...
    "wingbeat_std_forces_raw", "wingbeat_std_forces",...
    "wingbeat_std_forces_smoother", "wingbeat_std_forces_smoothest"};

root_dir = "R:\ENG_Breuer_Shared\rgissler\Calimero Force Data\Redesign tests July 2026\";

% Loading in file with homing index
sub_dir = "07_21_2026\0 m.s\benchtop_2026_07_21\processed data\";
% with hall effect sensor, auto homing
% filepath = "benchtop 20 0m.s 10deg 4Hz 2026 07 21 10 49 35 2026_07_21_10_50_51.mat";
% load(root_dir + sub_dir + filepath, vars{:});
% motor running in reverse with hall effect sensor, no autohoming
% filepath = "benchtop 20 0m.s 10deg 4Hz 2026 07 21 12 55 14 2026_07_21_12_56_32";
% load(root_dir + sub_dir + filepath, vars{:});

% Load 1st file
sub_dir = "07_01_2026\0 m.s\benchtop_2026_07_01\processed data\";
% filepath = "benchtop 20 0m.s 0deg 4Hz 2026-07-01 18-58-30 2026_07_01_18_59_43.mat";
% filepath = "benchtop 20 0m.s 0deg 6Hz 2026-07-01 19-01-41 2026_07_01_19_02_41.mat";
filepath = "benchtop 20 0m.s 0deg 8Hz 2026-07-01 19-04-48 2026_07_01_19_05_42.mat";
load(root_dir + sub_dir + filepath, vars{:});

figure
hold on
[avg_forces, std_forces] = get_forces_to_plot(forces_to_plot, wingbeat_avg_forces_raw, ...
    wingbeat_avg_forces, wingbeat_avg_forces_smoother, wingbeat_avg_forces_smoothest,...
    wingbeat_std_forces_raw, wingbeat_std_forces, wingbeat_std_forces_smoother,...
    wingbeat_std_forces_smoothest);
disp(mean(avg_forces(sel_idx,:)))
p = plot(frames, avg_forces(sel_idx,:));
p.DisplayName = "Original";
p.LineWidth = 2;

% Load 2nd file
% sub_dir = "07_06_2026\no spring\0 m.s\benchtop_2026_07_06\processed data\";
% % filepath = "benchtop  20 0m.s 0deg 4Hz 2026-07-06 15-01-18 2026_07_06_15_02_31.mat";
% filepath = "benchtop  20 0m.s 0deg 6Hz 2026-07-06 15-04-37 2026_07_06_15_05_37.mat";
% load(root_dir + sub_dir + filepath, vars{:});
% 
% forces = get_forces_to_plot(forces_to_plot, wingbeat_avg_forces_raw, ...
%     wingbeat_avg_forces, wingbeat_avg_forces_smoother, wingbeat_avg_forces_smoothest);
% disp(mean(forces(sel_idx,:)))
% p = plot(frames, forces(sel_idx,:));
% p.DisplayName = "Rolling";
% p.LineWidth = 2;

% % Load 3rd file
sub_dir = "07_07_2026\0 m.s\benchtop_2026_07_07\processed data\";
% filepath = "benchtop 20 0m.s 0deg 4Hz 2026 07 07 12 43 38 2026_07_07_12_44_55.mat";
% filepath = "benchtop 20 0m.s 0deg 6Hz 2026 07 07 12 47 10 2026_07_07_12_48_15.mat";
filepath = "benchtop 20 0m.s 0deg 8Hz 2026 07 07 12 50 29 2026_07_07_12_51_28.mat";
load(root_dir + sub_dir + filepath, vars{:});

[avg_forces, std_forces] = get_forces_to_plot(forces_to_plot, wingbeat_avg_forces_raw, ...
    wingbeat_avg_forces, wingbeat_avg_forces_smoother, wingbeat_avg_forces_smoothest,...
    wingbeat_std_forces_raw, wingbeat_std_forces, wingbeat_std_forces_smoother,...
    wingbeat_std_forces_smoothest);
disp(mean(avg_forces(sel_idx,:)))
p = plot(frames, avg_forces(sel_idx,:));
p.DisplayName = "Spring + Rolling";
p.LineWidth = 2;

% % Load 4th file
sub_dir = "07_08_2026\4 m.s\benchtop_2026_07_08\processed data\";
% filepath = "benchtop 20 4m.s 10deg 6Hz 2026 07 08 11 41 46 2026_07_08_11_42_56.mat";
% filepath = "benchtop 20 4m.s 10deg 6Hz 2026 07 08 11 41 46 2026_07_08_11_42_56.mat";
filepath = "benchtop 20 4m.s 10deg 8Hz 2026 07 08 11 45 08 2026_07_08_11_46_12.mat";
load(root_dir + sub_dir + filepath, vars{:});

[avg_forces, std_forces] = get_forces_to_plot(forces_to_plot, wingbeat_avg_forces_raw, ...
    wingbeat_avg_forces, wingbeat_avg_forces_smoother, wingbeat_avg_forces_smoothest,...
    wingbeat_std_forces_raw, wingbeat_std_forces, wingbeat_std_forces_smoother,...
    wingbeat_std_forces_smoothest);
disp(mean(avg_forces(sel_idx,:)))
p = plot(frames, avg_forces(sel_idx,:));
p.DisplayName = "Spring + Rolling + Wind";
p.LineWidth = 2;

% Loading in file with homing index and spring reversed
sub_dir = "07_21_2026\reverse_spring\0 m.s\benchtop_2026_07_21\processed data\";
% filepath = "benchtop 20 0m.s 10deg 4Hz 2026 07 21 15 33 58 2026_07_21_15_35_13.mat";
% filepath = "benchtop 20 0m.s 10deg 6Hz 2026 07 21 15 35 56 2026_07_21_15_36_58.mat";
filepath = "benchtop 20 0m.s 10deg 8Hz 2026 07 21 15 37 29 2026_07_21_15_38_26.mat";
% filepath = "benchtop 20 0m.s 10deg 10Hz 2026 07 21 15 40 17 2026_07_21_15_41_11.mat";
load(root_dir + sub_dir + filepath, vars{:});

volt_idx = 8;
cur_idx = 9;
sel_idx = cur_idx;

[avg_forces, std_forces] = get_forces_to_plot(forces_to_plot, wingbeat_avg_forces_raw, ...
    wingbeat_avg_forces, wingbeat_avg_forces_smoother, wingbeat_avg_forces_smoothest,...
    wingbeat_std_forces_raw, wingbeat_std_forces, wingbeat_std_forces_smoother,...
    wingbeat_std_forces_smoothest);
disp(mean(avg_forces(sel_idx,:)))

lower_results = avg_forces - std_forces;
upper_results = avg_forces + std_forces;

original_color = "#7f2704"; % hex, some dark red
lighter_color = getLightColor(original_color); % RGB

xconf = [frames, frames(end:-1:1)];
yconf = [upper_results(sel_idx, :), lower_results(sel_idx, end:-1:1)];

p = fill(xconf, yconf, lighter_color);
p.HandleVisibility = 'off';
p.EdgeColor = 'none';

l = plot(frames, avg_forces(sel_idx,:));
l.Color = original_color;
l.DisplayName = "Flipped Spring + Rolling";
l.LineWidth = 2;

xline(0.39/2, LineWidth=2, LineStyle="--", HandleVisibility="off")
xline((0.39/2) + 0.61, LineWidth=2, LineStyle="--", HandleVisibility="off")

xlabel("Time (t/T)")
ylabel("Current (mA)")
legend()
set(gca, FontSize=16);

function [avg_forces, std_forces] = get_forces_to_plot(forces_to_plot, wingbeat_avg_forces_raw, ...
    wingbeat_avg_forces, wingbeat_avg_forces_smoother, wingbeat_avg_forces_smoothest,...
    wingbeat_std_forces_raw, wingbeat_std_forces, wingbeat_std_forces_smoother,...
    wingbeat_std_forces_smoothest)
switch forces_to_plot
    case "wingbeat_avg_forces_raw"
        avg_forces = wingbeat_avg_forces_raw;
        std_forces = wingbeat_std_forces_raw;
    case "wingbeat_avg_forces"
        avg_forces = wingbeat_avg_forces;
        std_forces = wingbeat_std_forces;
    case "wingbeat_avg_forces_smoother"
        avg_forces = wingbeat_avg_forces_smoother;
        std_forces = wingbeat_std_forces_smoother;
    case "wingbeat_avg_forces_smoothest"
        avg_forces = wingbeat_avg_forces_smoothest;
        std_forces = wingbeat_std_forces_smoothest;
    otherwise
        error("Unsupported forces_to_plot value: %s", char(forces_to_plot))
end
end

function lighter_color = getLightColor(original_color)
		original_color = hex2rgb(original_color);
		
		% Amount to lighten (0 = no change, 1 = completely white)
    fade_amount = 0.7;

    % White color in RGB
    white = [1, 1, 1];

    % Linearly interpolate between the original color and white
    lighter_color = (1 - fade_amount) * original_color + fade_amount * white;
end