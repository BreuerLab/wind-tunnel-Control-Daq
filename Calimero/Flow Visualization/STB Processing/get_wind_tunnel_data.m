function d = get_wind_tunnel_data(force_file)

string_end = extractAfter(force_file, "experiment");

 % Extract all digits
matches = regexp(string_end, '\d+', 'match');
timeArray = str2double(matches); % 1 x 6 array of date and time

targetDT = datetime(timeArray);

% Rewrite date string in American format
date = string(targetDT, "MM_dd_uuuu");

map = {
        '02_08_2026',  "AFAM_2026_02_08_11_21_48_log_file.csv"
        '02_09_2026',  "AFAM_2026_02_09_09_11_01_log_file.csv"
        '02_11_2026',  "AFAM_2026_02_11_10_04_52_log_file.csv"
        '02_12_2026',  "AFAM_2026_02_12_08_50_09_log_file.csv"
        '02_15_2026',  "AFAM_2026_02_15_09_06_19_log_file.csv"
    };

% Convert to Map and Retrieve
WT_dict = containers.Map(map(:,1), map(:,2));

wind_tunnel_file = WT_dict(date);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

root_path = "R:\ENG_Breuer_Shared\rgissler\Calimero Force Data\STB Final\";
folder = "STB_" + date;
params_path = "\data\params";

files = dir(root_path + folder + params_path);

% Remove the '.' and '..' (which are always present in file systems)
% and filter for actual folders
files = files(~ismember({files.name}, {'.', '..'}));

for i = 1:length(files)
    name = files(i).name;
    % Extract all digits
    matches = regexp(name, '\d+', 'match');
    timeArray = str2double(matches); % 1 x 6 array of date and time

    % find properties at that time from wind tunnel log file
    if ~isempty(timeArray)
        targetDT = datetime(timeArray);

        data = readtable(root_path + wind_tunnel_file);

        % Get datetime for each row of csv file
        windTunnelDT = datetime(data.Year, data.Month, data.Day, ...
                        data.Hour, data.Min, data.Sec);

        % Calculate the absolute time difference
        timeDiffs = abs(windTunnelDT - targetDT);
        
        % Find the index of the minimum difference
        [minDiff, minIdx] = min(timeDiffs);
        
        % Extract the full row
        bestMatchRow = data(minIdx, :);
    end
end