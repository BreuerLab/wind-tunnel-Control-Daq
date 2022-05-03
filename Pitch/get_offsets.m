% TODO: Update this method's documentation.

function [offsets] = get_offsets(case_name, rate, session_duration)

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
offsets_daq.start;
[bias, ~] = read(offsets_daq, seconds(session_duration));

% Preallocate an array to hold the offsets.
offsets = zeros(2, 6);

for i = 1:6
    offsets(1, i) = mean(bias(:, i));
    offsets(2, i) = std(bias(:, i)) / sqrt(rate * session_duration);
end

% Write the offsets to a .csv file.
trial_name = strjoin([case_name, "offsets", datestr(now, "mmddyy")], "_");
trial_file_name = trial_name + ".csv";
writematrix(offsets, trial_file_name);

% Clear the DAq object.
clear offsets_daq;

end