clear
close all
restoredefaultpath
addpath(genpath('../data analysis'))

% File to get gliding lift slopes from data

% selection has the following form:
% Flapperoo/Half_Wings_3m.s

bird_strings = ["Flapperoo"];
types = ["Half_Wings"];
speeds = ["3m.s", "4m.s", "5m.s", "6m.s"];
range = [-12 12];
force_ind = 5; % choose 3 or 5, lift or pitch

% bools
norm_bool = true; % needs to be true otherwise slopes will be different for different speeds
shift_bool = true; % needs to be true otherwise pitching moment won't be defined about LE so that it can be compared with theory
drift_bool = false;
sub_bool = true;

Flapperoo = flapper("Flapperoo");
MetaBird = flapper("MetaBird");
cur_bird = Flapperoo;

selection_list = [];
for i = 1:length(bird_strings)
    for j = 1:length(types)
        for k = 1:length(speeds)
            cur_sel = bird_strings(i) + "/" + types(j) + "_" + speeds(k);
            selection_list = [selection_list cur_sel];
        end
    end
end

path = "D:\Final Force Data" + "/plot data/" + cur_bird.name + "/";
attachFileListsToBird(path, cur_bird);

struct_matches = get_file_matches(selection_list, norm_bool, shift_bool, drift_bool, sub_bool, Flapperoo, MetaBird);
disp("Found following matches:")
disp(struct_matches)

for i = 1:length(selection_list)
    for j = 1:length(struct_matches)
        if (selection_list(i) == struct_matches(j).selector)
            cur_struct_match = struct_matches(j);
            break;
        end
    end

    flapper_name = string(extractBefore(selection_list(i), "/"));
    dir_name = string(extractAfter(selection_list(i), "/"));

    cur_bird = getBirdFromName(flapper_name, Flapperoo, MetaBird);

    lim_AoA_sel = cur_bird.angles(cur_bird.angles >= range(1) & cur_bird.angles <= range(2));
    
    disp("Loading " + path + cur_struct_match.file_name)
    load(path + cur_struct_match.file_name, "avg_forces", "err_forces")
    freq_ind = 1; % corresponds to gliding case
    lim_avg_forces = avg_forces(:,cur_bird.angles >= range(1) & cur_bird.angles <= range(2),freq_ind);
    lim_err_forces = err_forces(:,cur_bird.angles >= range(1) & cur_bird.angles <= range(2),freq_ind);

    x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
    y = lim_avg_forces(force_ind,:)';
    b = x\y;
    model = x*b;
    Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
    % SE_slope = (sum((y - model).^2) / (sum((lim_AoA_sel - mean(lim_AoA_sel)).^2)*(length(lim_AoA_sel) - 2)) ).^(1/2);
    % x_int = - b(1) / b(2);

    if force_ind == 3
        thinAirfoil = 2*pi*deg2rad(lim_AoA_sel);
    elseif force_ind == 5
        thinAirfoil = -(1/2)*pi*deg2rad(lim_AoA_sel);
    end

    label_str = "y = " + round(b(2),3) + "x + " + round(b(1),3) + ", R^2 = " + round(Rsq,3);
    title_str = strrep(dir_name, "_", " ");

    figure
    hold on
    e = errorbar(lim_AoA_sel, lim_avg_forces(force_ind,:), lim_err_forces(force_ind,:), '.');
    e.MarkerSize = 25;
    e.DisplayName = "Data";
    p = plot(lim_AoA_sel, model);
    p.DisplayName = label_str;
    m = plot(lim_AoA_sel, thinAirfoil);
    m.DisplayName = "Thin Airfoil";
    hold off
    title(title_str)
    legend()
end