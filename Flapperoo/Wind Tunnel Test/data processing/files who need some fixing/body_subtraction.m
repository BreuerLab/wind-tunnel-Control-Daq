% path to folder where all processed data (.mat files) are stored
processed_data_path = "../processed data/";

frame_rate = 9000; % Hz
num_wingbeats = 180;

% Get a list of all files in the folder with the desired file name pattern.
filePattern = fullfile(processed_data_path, '*.mat'); % Change to whatever pattern you need.
theFiles = dir(filePattern);

% Shorten list of filenames based on parameter requirements
cases = "";
body_data = [];
wing_data = [];
for k = 1 : length(theFiles)
    baseFileName_body = theFiles(k).name;
    [case_name_body, type_body, wing_freq_body, AoA_body, wind_speed_body] = parse_filename(baseFileName_body);

    if (type_body == "body")
        load(processed_data_path + case_name_body + ".mat");
        body_data = wingbeat_avg_forces;

        % find same case for wing data
        for j = 1 : length(theFiles)
            baseFileName_wing = theFiles(j).name;
            [case_name_wing, type_wing, wing_freq_wing, AoA_wing, wind_speed_wing] = parse_filename(baseFileName_wing);

            if (type_wing == "mylar" && wing_freq_body == wing_freq_wing && AoA_body == AoA_wing && wind_speed_body == wind_speed_wing)
                load(processed_data_path + case_name_wing + ".mat");
                wing_data = wingbeat_avg_forces;

                % Check that body_data and wing_data have equal length
%                 if (length(body_data) < length(wing_data))
%                     length_diff = length(wing_data) - length(body_data);
%                     disp("body has " + length_diff + " fewer points")
%                     wing_data = wing_data(1:length(body_data),:);
%                 elseif (length(wing_data) < length(body_data))
%                     length_diff = length(body_data) - length(wing_data);
%                     disp("wing has " + length_diff + " fewer points")
%                     body_data = body_data(1:length(wing_data),:);
%                 end

%                 filtered_data = filter_data(wing_data - body_data, frame_rate);
% 
%                 [wingbeat_forces, frames, wingbeat_avg_forces, wingbeat_std_forces, ...
%                 wingbeat_rmse_forces, wingbeat_max_forces, wingbeat_min_forces, wingbeat_COP] ...
%                 = wingbeat_transformation(num_wingbeats, filtered_data);

                wingbeat_avg_forces = wing_data - body_data;

                shortened_name = erase(case_name_wing,"mylar");
                filename = shortened_name + ".mat";
                save(processed_data_path + "subtraction/" + filename, ...
                    'frames', 'wingbeat_avg_forces')
            end
        end
    end

    percent_complete = round((k / length(theFiles)) * 100, 2);
    disp(percent_complete + "% complete")
end
