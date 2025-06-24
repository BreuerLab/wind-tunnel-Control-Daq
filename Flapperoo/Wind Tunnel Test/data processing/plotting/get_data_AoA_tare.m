function [avg_forces, err_forces, names, sub_title] = get_data_AoA_tare(selected_vars, processed_data_path)

names = strings(1);
sub_title = strings(1);

AoA_sel = selected_vars.AoA;
type_sel = selected_vars.type;

% Initialize variables
avg_forces = zeros(6, length(AoA_sel));
avg_forces_temp = zeros(6, length(AoA_sel));
err_forces = zeros(6, length(AoA_sel));
cases_final = strings(length(AoA_sel),1);

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

% Go through each file, grab its data, take the mean over all results to
% produce a "dot" (i.e. a single point value) for each force and moment
for i = 1 : length(theFiles)
    baseFileName = theFiles(i).name;
    [case_name, type, AoA] = parse_filename_tare(baseFileName);
    type = convertCharsToStrings(type);
    
    pitch = deg2rad(-(1.03*AoA - 0.5));
    yaw = deg2rad(205); % or AoA, XYZ, tranposes
%         q = angle2quat(0, pitch, 0);
    dcm_F = angle2dcm(yaw, pitch, 0,'ZYX');
%         dcm_F = angle2dcm(0, pitch, yaw,'XYZ');
    dcm_M = angle2dcm(yaw, 0, 0, 'ZYX');
%         dcm_M = angle2dcm(0, pitch, yaw, 'XYZ');
%         dcm_M2 = angle2dcm(0, pitch, 0, 'ZYX');
%         dcm_F = [cos(pitch),0,-sin(pitch); 0,1,0; sin(pitch),0,cos(pitch);];
    
    if (ismember(AoA, AoA_sel) && ismember(type, type_sel))        
        load(processed_data_path + baseFileName);
        
        for k = 1:6
            avg_forces_temp(k, AoA_sel == AoA) = mean(filtered_data(:, k));
            err_forces(k, AoA_sel == AoA) = std(filtered_data(:, k));
        end
        
        cases_final(AoA_sel == AoA) = baseFileName;
        
        avg_forces(1:3, AoA_sel == AoA) = (dcm_F * avg_forces_temp(1:3, AoA_sel == AoA));
%         avg_forces(AoA_sel == AoA, 1:3) = quatrotate(q, avg_forces_temp(AoA_sel == AoA, 1:3));
        avg_forces(4:6, AoA_sel == AoA) = (1 * dcm_M * avg_forces_temp(4:6, AoA_sel == AoA));
    end
end

end

