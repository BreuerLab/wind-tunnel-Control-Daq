function [lift_slope, pitch_slope, zero_lift_alpha, zero_pitch_alpha] = getGlideSlopes(path, cur_bird, dir_name, AoA_range)
    speeds = [3, 4, 5, 6];

    theFiles = cur_bird.file_list;

    % remove speed from dir_name since we want all speeds
    % associated with that configuration
    dir_parts = split(extractBefore(dir_name, "m.s."), '_');
    wind_speed = sscanf(dir_parts(end), '%g', 1);
    dir_name = erase(dir_name, wind_speed + "m.s._");

    count = 0;
    matches = strings(1,length(speeds));
    % Grab each file and process the data from that file, storing the results
    for k = 1 : length(theFiles)
        baseFileName = convertCharsToStrings(theFiles(k).file_name);
        parsed_name = extractBefore(baseFileName, "_saved");
        dir_parts = split(extractBefore(parsed_name, "m.s."), '_');
        cur_wind_speed = sscanf(dir_parts(end), '%g', 1);
        parsed_name = erase(parsed_name, cur_wind_speed + "m.s._");

        if (parsed_name == dir_name && ismember(cur_wind_speed,speeds))
            matches(speeds == cur_wind_speed) = baseFileName;
            count = count + 1;
        end
    end
    if count > 4
        disp(matches)
        error("Woah, found " + count + " (too many) matching files")
    end

    lim_AoA_sel = cur_bird.angles(cur_bird.angles >= AoA_range(1) & cur_bird.angles <= AoA_range(2));
    lim_AoA_sel = deg2rad(lim_AoA_sel);

    freq_ind = 1; % corresponds to gliding case

    lift_slopes = zeros(1,length(matches));
    pitch_slopes = zeros(1,length(matches));
    zero_lift_alphas = zeros(1,length(matches));
    zero_pitch_alphas = zeros(1,length(matches));
    for i = 1:length(matches)
        matched_filename = matches(i);
        cur_file = path + "/" + matched_filename;
        disp("Loading " + cur_file + " for glide slope")
        load(cur_file, "avg_forces")
        lim_avg_forces = avg_forces(:,cur_bird.angles >= AoA_range(1) & cur_bird.angles <= AoA_range(2),:);
   
        lift_force = lim_avg_forces(3,:,freq_ind);
        pitch_force = lim_avg_forces(5,:,freq_ind);

        % TEMPORARY 06/09/2025
        % shift_distance = -0.0684;
        % temp_lim_avg_forces = shiftPitchMom(squeeze(lim_avg_forces(:,:,freq_ind)), shift_distance, rad2deg(lim_AoA_sel));
        % pitch_force = temp_lim_avg_forces(5,:);
        
    
        x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
        y = lift_force';
        b_l = x\y;
        model_lift = x*b_l;
        cur_lift_slope = b_l(2);
        zero_l_alpha = - b_l(1) / b_l(2);
        % Rsq = 1 - sum((y - model).^2)/sum((y - mean(y)).^2);
        % SE_slope = (sum((y - model).^2) / (sum((lim_AoA_sel - mean(lim_AoA_sel)).^2)*(length(lim_AoA_sel) - 2)) ).^(1/2);
        % x_int = - b(1) / b(2);
    
        x = [ones(size(lim_AoA_sel')), lim_AoA_sel'];
        y = pitch_force';
        b_p = x\y;
        model_pitch = x*b_p;
        cur_pitch_slope = b_p(2);
        zero_p_alpha = - b_p(1) / b_p(2);
    
        lift_slopes(i) = cur_lift_slope;
        pitch_slopes(i) = cur_pitch_slope;
        zero_lift_alphas(i) = zero_l_alpha;
        zero_pitch_alphas(i) = zero_p_alpha;

        % TEMPORARY 06/09/2025
        % disp("Basic Shift")
        % cur_pitch_slope + shift_distance * cur_lift_slope
        % disp(" ")
    end

    lift_slope = mean(lift_slopes);
    pitch_slope = mean(pitch_slopes);
    zero_lift_alpha = rad2deg(mean(zero_lift_alphas));
    zero_pitch_alpha = rad2deg(mean(zero_pitch_alphas));

    % Changing slope to be contribution for single wing
    % lift_slope = lift_slope / 2;
    % pitch_slope = pitch_slope / 2;

    plot_bool = false;
    if (plot_bool)
        figure
        hold on
        s = scatter(lim_AoA_sel, lift_force, 25, "filled");
        s.DisplayName = "Data";
        p = plot(lim_AoA_sel, model_lift);
        p.DisplayName = "y = " + round(b_l(2),3) + "x + " + round(b_l(1),3);
        hold off
        title("Lift Force")
        legend()

        figure
        hold on
        s = scatter(lim_AoA_sel, pitch_force, 25, "filled");
        s.DisplayName = "Data";
        p = plot(lim_AoA_sel, model_pitch);
        p.DisplayName = "y = " + round(b_p(2),3) + "x + " + round(b_p(1),3);
        hold off
        title("Pitch Moment")
        legend()
    end
end