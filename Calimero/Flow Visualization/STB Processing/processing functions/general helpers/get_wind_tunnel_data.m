function d = get_wind_tunnel_data(DAQ_file)

% ----------------------------------------------------------------------
% -------------------- Get date from file name -------------------------
% ----------------------------------------------------------------------
string_end = extractAfter(extractBefore(DAQ_file, "experiment"), "Hz");

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