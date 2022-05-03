% TODO: Update this method's documentation.

function [offsets] = get_offsets(case_name, rate, session_duration)

% Create DAq session.
offsets_daq = daq("ni");

offsets_daq.addinput("Dev1", 0, "Voltage");
offsets_daq.addinput("Dev1", 1, "Voltage");
offsets_daq.addinput("Dev1", 2, "Voltage");
offsets_daq.addinput("Dev1", 3, "Voltage");
offsets_daq.addinput("Dev1", 4, "Voltage");
offsets_daq.addinput("Dev1", 5, "Voltage");

offsets_daq.Rate = rate;

% Get offsets for current trial.
offsets_daq.start;
[bias, ~] = read(offsets_daq, seconds(session_duration));

% Preallocate an array to hold the offsets.
offsets = zeros(2, 6);

for i = 1:6
    offsets(1, i) = mean(bias(:, i));
    offsets(2, i) = std(bias(:, i)) / sqrt(rate * session_duration);
end

% Write the offsets to a MAT file.
trial = case_name + "_offsets.mat";
writematrix(offsets, trial);

end