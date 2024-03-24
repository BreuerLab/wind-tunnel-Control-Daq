function [avg_forces, err_forces, names, sub_title] = get_data_AoA(selected_vars, processed_data_path, bool)

nondimensional = bool.norm;
body_subtraction = bool.body_sub;

AoA_sel = selected_vars.AoA;
wing_freq_sel = selected_vars.freq;
wind_speed_sel = selected_vars.wind;
type_sel = selected_vars.type;

% Initialize variables
avg_forces = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
avg_forces_temp = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
avg_forces_body = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel));
avg_forces_body_temp = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel));
err_forces = zeros(6, length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
cases_final = strings(length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));
names = strings(length(wing_freq_sel), length(wind_speed_sel), length(type_sel));

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

% Go through each file, grab its data, take the mean over all results to
% produce a "dot" (i.e. a single point value) for each force and moment
for i = 1 : length(theFiles)
    baseFileName = theFiles(i).name;
    [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);
    type = convertCharsToStrings(type);
    
%     pitch = deg2rad(-AoA);
%     yaw = deg2rad(205);
%     dcm_F = angle2dcm(yaw, pitch, 0,'ZYX');
%     dcm_M = angle2dcm(yaw, 0, 0, 'ZYX');
    
    if (body_subtraction && type == "no wings" && ismember(wing_freq, wing_freq_sel) && ismember(AoA, AoA_sel) && ismember(wind_speed, wind_speed_sel))
        load(processed_data_path + baseFileName);
        for k = 1:6
            if (nondimensional)
                avg_forces_body(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed) = mean(filtered_norm_data(k, :));
%                 avg_forces_body_temp(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed) = mean(filtered_norm_data(:, k));
            else
                avg_forces_body(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed) = mean(filtered_data(k, :));
%                 avg_forces_body_temp(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed) = mean(filtered_data(:, k));
            end
        end
%         avg_forces_body(1:3, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed) ...
%                     = (dcm_F * avg_forces_body_temp(1:3, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed));
%         avg_forces_body(4:6, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed) ...
%                     = (1 * dcm_M * avg_forces_body_temp(4:6, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed));
    end
    
    if (ismember(wing_freq, wing_freq_sel) && ismember(AoA, AoA_sel) && ismember(wind_speed, wind_speed_sel) && ismember(type, type_sel))        
        load(processed_data_path + baseFileName);
        for k = 1:6
            if (nondimensional)
                % avg_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = mean(filtered_norm_data(k, :));
                avg_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = mean(dimensionless(filtered_data(k, :),norm_factors));
%                 avg_forces_temp(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = mean(filtered_norm_data(:, k));
            else
                avg_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = mean(filtered_data(k, :));
%                 avg_forces_temp(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = mean(filtered_data(:, k));
            end
            if (wing_freq == 0)
                if (nondimensional)
                    % err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = std(filtered_norm_data(k, :));
                    err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = std(dimensionless(filtered_data(k, :),norm_factors));
                else
                    err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = std(filtered_data(k, :));
                end
            else
                if (nondimensional)
                    wingbeat_rmse_forces_norm = dimensionless(wingbeat_rmse_forces, norm_factors);
                    err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = mean(wingbeat_rmse_forces_norm(k, :));
                else
                    err_forces(k, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = mean(wingbeat_rmse_forces(k, :));
                end
            end
        end
%         avg_forces(1:3, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) ...
%                     = (dcm_F * avg_forces_temp(1:3, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type));
%         avg_forces(4:6, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) ...
%                     = (1 * dcm_M * avg_forces_temp(4:6, AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type));
        
        cases_final(AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = baseFileName;
        
        if (nondimensional)
        if (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = "";
            sub_title = type2name(type) +  " Re: " + num2str(round(Re,2,"significant")) + " St: " + num2str(round(St,2,"significant"));
        elseif (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type);
            sub_title =  " Re: " + num2str(round(Re,2,"significant")) + " St: " + num2str(round(St,2,"significant"));
        % elseif (length(wing_freq_sel) == 1 && length(type_sel) == 1)
        %     names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) =  " Re: " + num2str(round(Re,2,"significant"));
        %     sub_title = type2name(type) + " St: " + num2str(round(St,2,"significant"));
        elseif (length(wind_speed_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) =  " St: " + num2str(round(St,2,"significant"));
            sub_title = type2name(type) +  " Re: " + num2str(round(Re,2,"significant"));
        % elseif (length(wing_freq_sel) == 1)
        %     names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) +  " Re: " + num2str(round(Re,2,"significant"));
        %     sub_title = " St: " + num2str(round(St,2,"significant"));
        elseif (length(wind_speed_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " St: " + num2str(round(St,2,"significant"));
            sub_title =  " Re: " + num2str(round(Re,2,"significant"));
        elseif (length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) =  " Re: " + num2str(round(Re,2,"significant")) + " St: " + num2str(round(St,2,"significant"));
            sub_title = type2name(type);
        else
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) +  " Re: " + num2str(round(Re,2,"significant")) + " St: " + num2str(round(St,2,"significant"));
            sub_title = "";
        end
        
        else
            
        if (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = "";
            sub_title = type2name(type) + " " + int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
        elseif (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type);
            sub_title = int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
        elseif (length(wing_freq_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = int2str(wind_speed) + " m/s";
            sub_title = type2name(type) + " " + int2str(wing_freq) + " Hz";
        elseif (length(wind_speed_sel) == 1 && length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = int2str(wing_freq) + " Hz";
            sub_title = type2name(type) + " " + int2str(wind_speed) + " m/s";
        elseif (length(wing_freq_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + int2str(wind_speed) + " m/s";
            sub_title = int2str(wing_freq) + " Hz";
        elseif (length(wind_speed_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + int2str(wing_freq) + " Hz";
            sub_title = int2str(wind_speed) + " m/s";
        elseif (length(type_sel) == 1)
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
            sub_title = type2name(type);
        else
            names(wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = type2name(type) + " " + int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
            sub_title = "";
        end
        end
    end
end

if (body_subtraction)
    for i = 1:length(AoA_sel)
    for j = 1:length(wing_freq_sel)
    for k = 1:length(wind_speed_sel)
    for m = 1:length(type_sel)
    for n = 1:6
        avg_forces(n, i, j, k, m) = avg_forces(n, i, j, k, m) - avg_forces_body(n, i, j, k);
    end
    end
    end
    end
    end
end
    

end

function name = type2name(type)
    name = type;
    if (type == "blue wings")
        name = "Wings";
    elseif (type == "no wings")
        name = "No Wings";
    elseif (type == "iinertial")
        name = "Skeleton Wings";
    end
end