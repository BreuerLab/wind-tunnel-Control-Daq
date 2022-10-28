% TODO: Update this method's documentation.

function [offsets] = get_offsets( rate, session_duration, case_name)

% Create a DAq session.
offsets_daq = daq("ni");

offsets_daq.addinput("Dev1", 0, "Voltage");
offsets_daq.addinput("Dev1", 1, "Voltage");
offsets_daq.addinput("Dev1", 2, "Voltage");
offsets_daq.addinput("Dev1", 3, "Voltage");
offsets_daq.addinput("Dev1", 4, "Voltage");
offsets_daq.addinput("Dev1", 5, "Voltage");

offsets_daq.Rate = rate;

% Get the offsets for current trial.
start(offsets_daq, "Duration", session_duration);
[bias_timetable, ~] = read(offsets_daq, seconds(session_duration));
bias_table = timetable2table(bias_timetable);
bias_array = table2array(bias_table(:,2:7));

% Preallocate an array to hold the offsets.
offsets = zeros(2, 6);

for i = 1:6
    offsets(1, i) = mean(bias_array(:, i));
    offsets(2, i) = std(bias_array(:, i)) / sqrt(rate * session_duration);
end

% Write the offsets to a .csv file.
if nargin>2
trial_name = strjoin([case_name, "offsets", datestr(now, "mmddyy")], "_");
trial_file_name = trial_name + ".csv";
writematrix(offsets, trial_file_name);
end
% Clear the DAq object.
clear offsets_daq;

end