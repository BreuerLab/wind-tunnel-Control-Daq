function plot_trial(file, raw_data_path, processed_data_path, bools)

[case_name, type, wing_freq, AoA, wind_speed] = parse_filename(file);

if (bools.raw)
    % Get a list of all files in the folder with the desired file name pattern.
    filePattern = fullfile(raw_data_path, '*.csv'); % Change to whatever pattern you need.
    theFiles = dir(filePattern);
    
    % Go through each file, grab its data, take the mean over all results to
    % produce a "dot" (i.e. a single point value) for each force and moment
    for i = 1 : length(theFiles)
        baseFileName = theFiles(i).name;
        [case_name_cur, type_cur, wing_freq_cur, AoA_cur, wind_speed_cur] = parse_filename(baseFileName);
        type_cur = convertCharsToStrings(type_cur);
        
        if (wing_freq == wing_freq_cur ...
        && AoA == AoA_cur ...
        && wind_speed == wind_speed_cur ...
        && strcmp(type, type_cur))
            data_filename = baseFileName;
        end
    end
    
    % Get raw data from file
    data = readmatrix(raw_data_path + data_filename);
    
    raw_time = data(:,1);
    raw_force = data(:,2:7);
    raw_trigger = data(:,8);
    
    % Trim off portion of data where wings are motionless or accelerating
    trimmed_results = trim_data([raw_time raw_force], raw_trigger, wing_freq);
    trimmed_time = trimmed_results(:,1)';
    trimmed_force = trimmed_results(:,2:7)';
    
    plot_raw_data(raw_time', raw_force', trimmed_time, trimmed_force, case_name, 5);
end

load(processed_data_path + file);

[time, lin_vel, lin_acc] = get_kinematics(wing_freq);

[eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed);

if (bools.kinematics)
    % % Just angular displacement
    % fig = figure;
    % fig.Position = [200 50 900 560];
    % plot(time_disp, displacement, DisplayName="Angular Displacement (deg)")
    % xlabel("Time (s)")
    % ylabel("Angular Displacement (deg)")
    % title("Angular Displacement of Wings Flapping at 1 Hz")
    % 
    % % Just angular velocity
    % fig = figure;
    % fig.Position = [200 50 900 560];
    % plot(time_vel, velocity)
    % xlabel("Time (s)")
    % ylabel("Angular Velocity (deg/s)")
    % title("Angular Velocity of Wings Flapping at 1 Hz")
    % 
    % % Both displacement and velocity
    % fig = figure;
    % fig.Position = [200 50 900 560];
    % hold on
    % yyaxis left
    % plot(time_disp, displacement, DisplayName="Angular Displacement (deg)")
    % yyaxis right
    % plot(time_vel, velocity, DisplayName="Angular Velocity (deg/s)")
    % hold off
    % xlabel("Time (s)")
    % ylabel("Angular Displacement/Velocity")
    % title("Angular Motion of Wings Flapping at 1 Hz")
    % legend(Location="northeast")
    
    % Linear velocity
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, lin_vel(:,51), DisplayName="r = 0.05")
    plot(time, lin_vel(:,151), DisplayName="r = 0.15")
    plot(time, lin_vel(:,251), DisplayName="r = 0.25")
    xlim([0 max(time_cycle)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Linear Velocity (m/s)")
    title("Linear Velocity of Wings Flapping at 1 Hz")
    legend(Location="northeast")
    
    % Linear acceleration
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, lin_acc(:,51), DisplayName="r = 0.05")
    plot(time, lin_acc(:,151), DisplayName="r = 0.15")
    plot(time, lin_acc(:,251), DisplayName="r = 0.25")
    xlim([0 max(time_cycle)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Linear Acceleration (m/s^2)")
    title("Linear Acceleration of Wings Flapping at 1 Hz")
    legend(Location="northeast")
end

if (bools.eff_wind)
    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, u_rel(:,51), DisplayName="r = 0.05")
    plot(time, u_rel(:,151), DisplayName="r = 0.15")
    plot(time, u_rel(:,251), DisplayName="r = 0.25")
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Effective Wind Speed (m/s)")
    title("Effective Wind Speed during Flapping for " + case_name)
    legend(Location="northeast")

    fig = figure;
    fig.Position = [200 50 900 560];
    hold on
    plot(time, eff_AoA(:,51), DisplayName="r = 0.05")
    plot(time, eff_AoA(:,151), DisplayName="r = 0.15")
    plot(time, eff_AoA(:,251), DisplayName="r = 0.25")
    xlim([0 max(time)])
    plot_wingbeat_patch();
    hold off
    xlabel("Time (s)")
    ylabel("Effective Angle of Attack (deg)")
    title("Effective Angle of Attack during Flapping for " + case_name)
    legend(Location="northeast")
end

if (bools.inertial)
    % % Inertial Force
    % wing_mass = 0.010; % kg
    % inertial_force = 2*wing_mass*lin_acc(:,151).*cosd(ang_disp_cycle);
    % COM_chord_pos = 0.15; % m
    % fig = figure;
    % fig.Position = [200 50 900 560];
    % hold on
    % plot(time, inertial_force, DisplayName="r = 0.15")
    % xlim([0 max(time_cycle)])
    % plot_wingbeat_patch();
    % hold off
    % xlabel("Time (s)")
    % ylabel("Inertial Force (N)")
    % title("Inertial Force of Wings Flapping at 1 Hz")
    % legend(Location="northeast")
end

% x_label = "Time (s)";
% y_label_F = "Force (N)";
% y_label_M = "Moment (N*m)";
% subtitle = "Trimmed, Rotated";
% axes_labels = [x_label, y_label_F, y_label_M];
% plot_forces(time_data, results_lab, case_name, subtitle, axes_labels);

x_label = "Time (s)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered";
axes_labels = [x_label, y_label_F, y_label_M];
plot_forces(time_data, filtered_data, case_name, subtitle, axes_labels, 5);

if (wing_freq > 0)
x_label = "Wingbeat Period (t/T)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
plot_forces_mean(frames, wingbeat_avg_forces, wingbeat_avg_forces + wingbeat_std_forces, wingbeat_avg_forces - wingbeat_std_forces, case_name, subtitle, axes_labels);

x_label = "Wingbeat Period (t/T)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
plot_forces_mean_subset(frames, dimensionless(wingbeat_avg_forces,norm_factors), dimensionless(wingbeat_avg_forces + wingbeat_std_forces,norm_factors), dimensionless(wingbeat_avg_forces - wingbeat_std_forces, norm_factors), case_name, subtitle, axes_labels);

x_label = "Wingbeat Period (t/T)";
y_label_F = "Force Coefficient";
y_label_M = "Moment Coefficient";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> Range";
plot_forces_mean(frames, wingbeat_avg_forces, wingbeat_max_forces, wingbeat_min_forces, case_name, subtitle, axes_labels);

x_label = "Wingbeat Period (t/T)";
y_label_F = "RMSE";
y_label_M = "RMSE";
axes_labels = [x_label, y_label_F, y_label_M];
subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat RMS'd";
plot_forces(frames, wingbeat_rmse_forces, case_name, subtitle, axes_labels, 0);

COP = wingbeat_avg_forces(5,:) ./ wingbeat_avg_forces(3,:); % M_y / F_z
% fc = 20; % cutoff frequency
% fs = 9000;
% [b,a] = butter(6,fc/(fs/2));
% filtered_COP = filtfilt(b,a,COP);
f = figure;
f.Position = [200 50 900 560];
plot(frames, COP)
% plot(frames, filtered_COP)
% plot(frames, wingbeat_COP)
ylim([-1, 1])
title("Movement of Center of Pressure for " + case_name)
xlabel("Wingbeat Period (t/T)");
ylabel("COP Location (m)");
end

if (bools.movie)
    y_label_F = "Force Coefficient";
    y_label_M = "Moment Coefficient";
    axes_labels = [x_label, y_label_F, y_label_M];
    subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged";
    wingbeat_movie(frames, dimensionless(wingbeat_forces, norm_factors), case_name, subtitle, axes_labels);
end

if (bools.spectrum)
    subtitle = "Trimmed, Rotated, Non-dimensionalized, Power Spectrum";
    plot_spectrum(wind_speed, freq, freq_power, case_name, subtitle)
end

end