% Ronan Gissler June 2023
clear
close all
addpath 'process trial'
addpath 'process trial/functions'
addpath 'plotting'
addpath '../../offsets data'

% -----------------------------------------------------------------
% The parameter combinations for which you'd like to see the data
% -----------------------------------------------------------------
wing_freq_sel = [0];
wind_speed_sel = [4];
type_sel = ["body"];
names = ["Body 4 m/s"];
% type_sel = ["mylar", "body"];
% names = ["Body 4 m/s", "Body + Wings 4 m/s"];
sub_title = "Taring (No Wind, No Flapping)";

% path to folder where all processed data (.mat files) are stored
processed_data_path = "../../offsets data/";

calibration_filepath = "C:\Users\rgissler\Desktop\Ronan Lab Documents\Force Transducer\Files\Calibration Files\FT43243.cal"; 

% -----------------------------------------------------------------
AoA_sel = -14:2:14; % you can narrow this range if you like

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(processed_data_path, '*.csv'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

% Shorten list of filenames based on parameter requirements
cases = "";
for k = 1 : length(theFiles)
    baseFileName = theFiles(k).name;
    [case_name, type, wing_freq, AoA, wind_speed] = parse_filename(baseFileName);

    if (ismember(wing_freq, wing_freq_sel) && ismember(AoA, AoA_sel) ...
            && ismember(wind_speed, wind_speed_sel) && ismember(type, type_sel) ...
            && contains(case_name, "before"))
        if (cases == "")
            cases = convertCharsToStrings(case_name);
        else
            cases = [cases, case_name];
        end
    end
end

clearvars -except processed_data_path cases names sub_title ...
    wing_freq_sel AoA_sel wind_speed_sel type_sel calibration_filepath
AoA = AoA_sel;

colors = [[0, 0.4470, 0.7410]; [0.8500, 0.3250, 0.0980]; ...
            [0.9290, 0.6940, 0.1250]; [0.4940, 0.1840, 0.5560]; ...
            [0.4660, 0.6740, 0.1880]; [0.3010, 0.7450, 0.9330]; ...
            [0.6350, 0.0780, 0.1840]; [0.25, 0.25, 0.25]];

    avg_forces = zeros(length(AoA), length(names), 6);
    std_forces = zeros(length(AoA), length(names), 6);
    cases_final = strings(length(AoA), length(names));
    
    for i = 1:length(AoA)
        for j = 1:length(names)
            file_name = strrep(cases((i-1)*length(names) + j),' ','_');
            [case_name, type, wing_freq, curAoA, wind_speed] = parse_filename(file_name);
            
            path = processed_data_path + file_name;
            data = readmatrix(path);
            % volts to forces
            cal_matrix = obtain_cal(calibration_filepath);
            forces = cal_matrix * data';
            forces = forces';
            % transform coordinate frame
%             results = forces;
            results = coordinate_transformation(forces, AoA);
            for k = 1:6
                avg_forces(find(AoA == curAoA), j, k) = (results(1, k));
                std_forces(find(AoA == curAoA), j, k) = (results(2, k));
            end
            cases_final(find(AoA == curAoA),j) = file_name;
        end
    end
    
    x_label = "Angle of Attack (deg)";
    y_label_F = "Trial Average Force (N)";
    y_label_M = "Trial Average Moment (N*m)";
    axes_labels = [x_label, y_label_F, y_label_M];
    
    % Open a new figure.
    f = figure;
    f.Position = [200 50 900 560];
    tcl = tiledlayout(2,3);
        
    % Create three subplots to show the force time histories. 
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 1) - avg_forces(round(length(AoA)/2), j, 1), 25, colors(j,:), "filled", HandleVisibility="off");
    end
    hold off
    title(["F_x (streamwise)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 2) - avg_forces(round(length(AoA)/2), j, 2), 25, colors(j,:), "filled", HandleVisibility="off");
    end
    hold off
    title(["F_y (transverse)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 3) - avg_forces(round(length(AoA)/2), j, 3), 25, colors(j,:), "filled", HandleVisibility="off");
    end
    hold off
    title(["F_z (vertical)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(2));
    
    % Create three subplots to show the moment time histories.
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 4) - avg_forces(round(length(AoA)/2), j, 4), 25, colors(j,:), "filled", HandleVisibility="off");
    end
    hold off
    title(["M_x (roll)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 5) - avg_forces(round(length(AoA)/2), j, 5), 25, colors(j,:), "filled", HandleVisibility="off");
    end
    hold off
    title(["M_y (pitch)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    nexttile(tcl)
    hold on
    for j = 1:length(names)
        scatter(AoA, avg_forces(:, j, 6) - avg_forces(round(length(AoA)/2), j, 6), 25, colors(j,:), "filled");
    end
    hold off
    title(["M_z (yaw)"]);
    xlabel(axes_labels(1));
    ylabel(axes_labels(3));
    
    hL = legend(names);
    hL.Layout.Tile = 'East';

    % Label the whole figure.
    sgtitle(["Force and Moment Means vs. Angle of Attack" sub_title]);
    
function cal_mat = obtain_cal(calibration_filepath)

    % Preallocate space for calibration matrix
    cal_mat = zeros(6,6);

    file_id = fopen(calibration_filepath);
    
    % Get first line from file
    tline = convertCharsToStrings(fgetl(file_id));
    
    % Counter for each measurement axis (6 total: Fx, Fy, Fz, Mx, My, Mz)
    axis_count = 1;
    
    % Loop through each line until reaching the end of the file
    while isstring(tline)
        
        % Lines with "UserAxis Name" have the calibration values
        if contains(tline, "UserAxis Name")
            split_line = split(tline);
            
            % Counter for each calibration value (six values for each axis)
            value_count = 1;
            
            for i = 1:length(split_line)
                % Check if phrase is numeric
                [num, status] = str2num(split_line(i));
                if status
                    % add that calibration value to matrix
                    cal_mat(axis_count, value_count) = num;
                    
                    % move on to the next value
                    value_count = value_count + 1;
                end
            end
            
            % move on to the next measurement axis
            axis_count = axis_count + 1;
        end
        
        % get next line
        tline = convertCharsToStrings(fgetl(file_id));
    end
    
    fclose(file_id);

end