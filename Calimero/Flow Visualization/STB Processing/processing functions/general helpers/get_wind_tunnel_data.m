function d = get_wind_tunnel_data(DAQ_path, DAQ_file, new_bool)

des_case_name = extractBefore(DAQ_file, "_experiment");

if new_bool
WT_path = strrep(DAQ_path, "experiment data", "wind tunnel data");
WT_file = "";

files = dir(WT_path);
for i = 1:length(files)
    case_name = extractBefore(files(i).name, "_wind");
    if strcmp(case_name, des_case_name)
        WT_file = files(i).name;
    end
end

temp = load(WT_path + WT_file);
d = temp.AFAM_Tunnel;

else
% ----------------------------------------------------------------------
% -------------------- Get date from file name -------------------------
% ----------------------------------------------------------------------
string_end = extractAfter(des_case_name, "Hz");

% Extract all digits
matches = regexp(string_end, '\d+', 'match');
timeArray = str2double(matches); % 1 x 6 array of date and time

targetDT = datetime(timeArray);

% Rewrite date string in American format
date = string(targetDT, "MM_dd_uuuu");

wind_tunnel_filepath = get_wind_tunnel_paths(date);

% ----------------------------------------------------------------------
% ------ Get data from the row with timestamp closest to DAQ_file ------
% ----------------------------------------------------------------------

data = readtable(wind_tunnel_filepath);

% Get datetime for each row of csv file
windTunnelDT = datetime(data.Year, data.Month, data.Day, ...
                data.Hour, data.Min, data.Sec);

% Calculate the absolute time difference
timeDiffs = abs(windTunnelDT - targetDT);

% Find the index of the minimum difference
[minDiff, minIdx] = min(timeDiffs);

% Extract the full row
bestMatchRow = data(minIdx, :);

% Store row in struct to return
d = table2struct(bestMatchRow, 'ToScalar', true);
end
end