clear
close all

wing_freq_sel = [0];
wind_speed_sel = [4];
type_sel = ["no wings", "blue wings", "blue wings with tail"];
% type_sel = ["no wings with tail"];
% AoA_sel = -10:1:10;
AoA_sel = -16:1:16;

wing_chord = 0.10; % meters

data_path = "../raw data/wind tunnel data/";

Reynolds = zeros(length(AoA_sel), length(wing_freq_sel), length(wind_speed_sel), length(type_sel));

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(data_path, '*.mat'); % Change to whatever pattern you need.
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
    
    if (ismember(wing_freq, wing_freq_sel) ...
    && ismember(AoA, AoA_sel) ...
    && ismember(wind_speed, wind_speed_sel) ...
    && ismember(type, type_sel))

        disp("   Obtaining data for " + type + " " + wing_freq + " Hz " + wind_speed + " m/s "  + AoA + " deg trial")
            
        [exact_wind_speed, density, Re] = get_tunnel_file_contents(data_path, baseFileName, wing_chord);

        % Reynolds(AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = Re;
        Reynolds(AoA_sel == AoA, wing_freq_sel == wing_freq, wind_speed_sel == wind_speed, type_sel == type) = exact_wind_speed;
    end
end

figure
hold on
for j = 1:length(wing_freq_sel)
for m = 1:length(wind_speed_sel)
for n = 1:length(type_sel)
    s = scatter(AoA_sel, Reynolds(:,j,m,n),50,'filled');
    [name] = get_name(wing_freq_sel, wind_speed_sel, type_sel,...
        wing_freq_sel(j), wind_speed_sel(m), type_sel(n));
    s.DisplayName = name;
end
end
end
legend()
xlabel("Angle of Attack (deg)")
ylabel("Wind Speed (m/s)")

function [name] = get_name(wing_freq_sel, wind_speed_sel, type_sel, wing_freq, wind_speed, type)

if (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1 && length(type_sel) == 1)
    name = "";
    % sub_title = type2name(type) + " " + int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
elseif (length(wing_freq_sel) == 1 && length(wind_speed_sel) == 1)
    name = type2name(type);
    % sub_title = int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
elseif (length(wing_freq_sel) == 1 && length(type_sel) == 1)
    name = int2str(wind_speed) + " m/s";
    % sub_title = type2name(type) + " " + int2str(wing_freq) + " Hz";
elseif (length(wind_speed_sel) == 1 && length(type_sel) == 1)
    name = int2str(wing_freq) + " Hz";
    % sub_title = type2name(type) + " " + int2str(wind_speed) + " m/s";
elseif (length(wing_freq_sel) == 1)
    name = type2name(type) + " " + int2str(wind_speed) + " m/s";
    % sub_title = int2str(wing_freq) + " Hz";
elseif (length(wind_speed_sel) == 1)
    name = type2name(type) + " " + int2str(wing_freq) + " Hz";
    % sub_title = int2str(wind_speed) + " m/s";
elseif (length(type_sel) == 1)
    name = int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
    % sub_title = type2name(type);
else
    name = type2name(type) + " " + int2str(wind_speed) + " m/s " + int2str(wing_freq) + " Hz";
    % sub_title = "";
end

end

function name = type2name(type)
    name = type;
    if (type == "blue wings")
        name = "Wings";
    elseif (type == "blue wings with tail")
        name = "Wings with Tail";
    elseif (type == "no wings with tail")
        name = "No Wings with Tail";
    elseif (type == "no wings")
        name = "No Wings";
    elseif (type == "inertial")
        name = "Skeleton Wings";
    end
end