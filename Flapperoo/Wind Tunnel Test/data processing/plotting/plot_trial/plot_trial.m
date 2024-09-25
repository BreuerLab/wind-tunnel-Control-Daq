function plot_trial(file, raw_data_path, processed_data_path, bools, sub_strings, nondimensional)

if (sub_strings(1) == "")
    body_subtraction = false;
else
    body_subtraction = true;
end

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

Re_og = Re;
St_og = St;

disp("Loading data from " + case_name + " trial")

if (bools.time_data)

if (nondimensional)
    x_label = "Time (s)";
    y_label_F = "Force Coefficient";
    y_label_M = "Moment Coefficient";
    subtitle = "Trimmed, Rotated";
    axes_labels = [x_label, y_label_F, y_label_M];
    plot_forces(time_data, dimensionless(results_lab, norm_factors), case_name, subtitle, axes_labels, 0);
    
    subtitle = "Trimmed, Rotated, Filtered";
    axes_labels = [x_label, y_label_F, y_label_M];
    plot_forces(time_data, dimensionless(filtered_data, norm_factors), case_name, subtitle, axes_labels, 0);

    y_label = "Probability";
    x_label_F = "Force Coefficient";
    x_label_M = "Moment Coefficient";
    subtitle = "Trimmed, Rotated, Filtered";
    axes_labels = [y_label, x_label_F, x_label_M];
    plot_force_histogram(time_data, dimensionless(filtered_data, norm_factors), case_name, subtitle, axes_labels, 0);
else
    x_label = "Time (s)";
    y_label_F = "Force (N)";
    y_label_M = "Moment (N*m)";
    subtitle = "Trimmed, Rotated";
    axes_labels = [x_label, y_label_F, y_label_M];
    plot_forces(time_data, results_lab, case_name, subtitle, axes_labels, 0);
    
    subtitle = "Trimmed, Rotated, Filtered";
    axes_labels = [x_label, y_label_F, y_label_M];
    plot_forces(time_data, filtered_data, case_name, subtitle, axes_labels, 0);

    y_label = "Probability";
    x_label_F = "Force (N)";
    x_label_M = "Moment (N*m)";
    subtitle = "Trimmed, Rotated, Filtered";
    axes_labels = [y_label, x_label_F, x_label_M];
    plot_force_histogram(time_data, filtered_data, case_name, subtitle, axes_labels, 0);
end

end

CAD_bool = true;
[time, ang_disp, ang_vel, ang_acc] = get_kinematics(wing_freq, CAD_bool);

wing_length = 0.25; % meters
arm_length = 0.016;
full_length = wing_length + arm_length;
r = arm_length:0.001:full_length;
lin_vel = deg2rad(ang_vel) * r;
lin_acc = deg2rad(ang_acc) * r;

[eff_AoA, u_rel] = get_eff_wind(time, lin_vel, AoA, wind_speed);

if (wing_freq > 0)
    [mod_filtered_data] = shiftPitchMoment(wingbeat_avg_forces_smooth, AoA);
    wingbeat_avg_forces_smooth = mod_filtered_data;

    cycle_avg_forces = wingbeat_avg_forces_smooth;
    cycle_std_forces = wingbeat_std_forces_smooth;
    cycle_min_forces = wingbeat_min_forces;
    cycle_max_forces = wingbeat_max_forces;
    cycle_rmse_forces = wingbeat_rmse_forces;

    if (body_subtraction)
    disp("Subtraction only occurs for wingbeat_avg_forces and model")
    % Parse relevant information from subtraction string
    case_parts = strtrim(split(sub_strings));
    sub_type = "";
    sub_wing_freq = wing_freq;
    sub_wind_speed = wind_speed;
    sub_AoA = AoA;
    index = length(case_parts) + 1;
    for j=1:length(case_parts)
        if (contains(case_parts(j), "Hz"))
            sub_wing_freq = str2double(erase(case_parts(j), "Hz"));
            if index == (length(case_parts) + 1)
                index = j;
            end
        elseif (contains(case_parts(j), "m.s"))
            sub_wind_speed = str2double(erase(case_parts(j), "m.s"));
            if index == (length(case_parts) + 1)
                index = j;
            end
        elseif (contains(case_parts(j), "deg"))
            sub_AoA = str2double(erase(case_parts(j), "deg"));
            if index == (length(case_parts) + 1)
                index = j;
            end
        end
    end
    sub_type = strjoin(case_parts(1:index-1)); % speed is first thing after type
    
    sub_case_name = sub_type + " " + sub_wind_speed + "m.s " + sub_AoA + "deg " + sub_wing_freq + "Hz";

    % cycle_avg_forces_old = wingbeat_avg_forces;
    % cycle_std_forces_old = wingbeat_std_forces;

    vars = {'wingbeat_avg_forces', 'wingbeat_std_forces', ...
        'wingbeat_avg_forces_smooth', 'wingbeat_std_forces_smooth', 'Re', 'St'};
    load(processed_data_path + sub_case_name + '.mat', vars{:});

    [mod_filtered_data] = shiftPitchMoment(wingbeat_avg_forces_smooth, sub_AoA);
    wingbeat_avg_forces_smooth = mod_filtered_data;

    cycle_avg_forces = cycle_avg_forces - wingbeat_avg_forces_smooth;
    cycle_std_forces = cycle_std_forces + wingbeat_std_forces_smooth;

    % cycle_avg_forces = cycle_avg_forces_old - wingbeat_avg_forces;
    % cycle_std_forces = cycle_std_forces_old + wingbeat_std_forces;

    disp("Subtracting data from " + sub_case_name + " trial")

    if (nondimensional)
        sub_case_title = sub_type + ", Re: " + num2str(round(Re,2,"significant")) + ...
                ", St: " + num2str(round(St,2,"significant")) + ", AoA: " + sub_AoA + " deg";
    else
        sub_case_title = sub_type + ", U: " + sub_wind_speed + ...
            " m/s, f: " + sub_wing_freq + " Hz, AoA: " + sub_AoA + " deg";
    end
end

if (nondimensional)
    case_title = type + ", Re: " + num2str(round(Re_og,2,"significant")) +...
        ", St: " + num2str(round(St_og,2,"significant")) + ", AoA: " + AoA + " deg";
else
    case_title = type + ", U: " + wind_speed + " m/s, f: " +...
        wing_freq + " Hz, AoA: " + AoA + " deg";
end

if (bools.kinematics)
    plot_kinematics(time, ang_disp, ang_vel, lin_vel, lin_acc);
end

if (bools.eff_wind)
    eff_wind_plot(time, u_rel, eff_AoA, case_title);
end

if (wing_freq > 0)

    if (bools.model)
        if (body_subtraction && sub_type ~= "no wings" && sub_type ~= "no wings with tail")
            sub_bool = true;
            % only makes sense to subtract the model data when
            % you have a case that also has wings.
        else
            sub_bool = false;
            sub_wind_speed = 0;
            sub_wing_freq = 0;
            sub_AoA = 0;
            sub_case_title = "";
        end
        
        model_plot(wind_speed, wing_freq, AoA, ...
                        sub_wind_speed, sub_wing_freq, sub_AoA, ...
                        case_title, sub_case_title, ...
                        frames, cycle_avg_forces, cycle_std_forces,...
                        norm_factors, sub_bool, nondimensional)
    end
    
    if (nondimensional)
        x_label = "Wingbeat Period (t/T)";
        y_label_F = "Force Coefficient";
        y_label_M = "Moment Coefficient";
        axes_labels = [x_label, y_label_F, y_label_M];
    
        subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
        plot_forces_mean(frames, ...
            dimensionless(cycle_avg_forces, norm_factors), ...
            dimensionless(cycle_avg_forces + cycle_std_forces,norm_factors), ...
            dimensionless(cycle_avg_forces - cycle_std_forces, norm_factors), ...
            case_name, subtitle, axes_labels);
    
        subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> Range";
        plot_forces_mean(frames, ...
            dimensionless(cycle_avg_forces,norm_factors), ...
            dimensionless(cycle_max_forces,norm_factors), ...
            dimensionless(cycle_min_forces,norm_factors), ...
            case_name, subtitle, axes_labels);
    
        subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
        plot_forces_mean_subset(frames, ...
            dimensionless(cycle_avg_forces,norm_factors), ...
            dimensionless(cycle_avg_forces + cycle_std_forces, norm_factors), ...
            dimensionless(cycle_avg_forces - cycle_std_forces, norm_factors), ...
            case_name, subtitle, axes_labels);
    
        y_label_F = "RMSE";
        y_label_M = "RMSE";
        axes_labels = [x_label, y_label_F, y_label_M];
        subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat RMS'd";
        plot_forces(frames, dimensionless(cycle_rmse_forces,norm_factors), case_name, subtitle, axes_labels, 0);
    else
        x_label = "Wingbeat Period (t/T)";
        y_label_F = "Force (N)";
        y_label_M = "Moment (N*m)";
        axes_labels = [x_label, y_label_F, y_label_M];
    
        subtitle = "Trimmed, Rotated, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
        plot_forces_mean(frames, cycle_avg_forces, ...
            cycle_avg_forces + cycle_std_forces, ...
            cycle_avg_forces - cycle_std_forces, ...
            case_name, subtitle, axes_labels);
    
        subtitle = "Trimmed, Rotated, Filtered, Wingbeat Averaged, Shaded -> Range";
        plot_forces_mean(frames, cycle_avg_forces, ...
            cycle_max_forces, cycle_min_forces, ...
            case_name, subtitle, axes_labels);
    
        subtitle = "Trimmed, Rotated, Filtered, Wingbeat Averaged, Shaded -> +/- 1 SD";
        plot_forces_mean_subset(frames, cycle_avg_forces, ...
            cycle_avg_forces + cycle_std_forces, ...
            cycle_avg_forces - cycle_std_forces, ...
            case_name, subtitle, axes_labels);
    
        y_label_F = "RMSE";
        y_label_M = "RMSE";
        axes_labels = [x_label, y_label_F, y_label_M];
        subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat RMS'd";
        plot_forces(frames, cycle_rmse_forces, case_name, subtitle, axes_labels, 0);
    end
    
    if (bools.COP)
        disp("COP calc is broken since data is shifted first before")
        COP = cycle_avg_forces(5,:) ./ cycle_avg_forces(3,:); % M_y / F_z
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

end

if (bools.movie)
    y_label_F = "Force Coefficient";
    y_label_M = "Moment Coefficient";
    axes_labels = [x_label, y_label_F, y_label_M];
    subtitle = "Trimmed, Rotated, Non-dimensionalized, Filtered, Wingbeat Averaged";
    wingbeat_movie(frames, dimensionless(wingbeat_forces, norm_factors),...
        case_name, subtitle, axes_labels);
end

if (bools.spectrum)
    [frame_rate, num_wingbeats] = get_sampling_info();
    plot_St = false; % plot spectra vs Strouhal than frequency
    if (nondimensional)
        subtitle = "Trimmed, Rotated, Non-dimensionalized";
        plot_spectrum(wind_speed, dimensionless(results_lab, norm_factors), frame_rate, case_title, subtitle, plot_St)
        subtitle = "Trimmed, Rotated, Filtered, Non-dimensionalized";
        plot_spectrum(wind_speed, dimensionless(filtered_data, norm_factors), frame_rate, case_title, subtitle, plot_St)
    else
        subtitle = "Trimmed, Rotated";
        plot_spectrum(wind_speed, results_lab, frame_rate, case_title, subtitle, plot_St);
        subtitle = "Trimmed, Rotated, Filtered";
        plot_spectrum(wind_speed, filtered_data, frame_rate, case_title, subtitle, plot_St);
    end
end

end