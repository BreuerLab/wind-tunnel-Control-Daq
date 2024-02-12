% Author: Ronan Gissler
% Last updated: October 2023

% Trim off portion of data where wings are motionless or accelerating using
% the "trigger data". The "trigger" is a digital output on the galil DMC
% wired to an analog input on the DAQ. When the galil has brought the motor
% up to speed, it pulls the digital output low. Just before the galil
% begins decelerating the motor, it pulls the digital output high. Since we
% only want the data when the wings are flapping at speed, we only take the
% data for which the galil's digital output is low.

% Inputs:
% results - (n x 7) time and force transducer data
% trigger_data - signal from trigger channel on DAQ over experiment
% wing_freq - wingbeat frequency, parsed from filename earlier

% Returns:
% trimmed_results - results for which the trigger voltage was low
function trimmed_results = trim_data(results, trigger_data, wing_freq)
    trimmed_results = zeros(size(results));
    low_trigs_indices = find(trigger_data < 2); % <2 Volts = Digital Low

    % if voltage was pulled low as expected during a flapping trial, trim
    % data using trigger signal
    if ~(isempty(low_trigs_indices) || low_trigs_indices(1) == 1 ...
            || low_trigs_indices(end) == length(trigger_data))
        trigger_start_frame = low_trigs_indices(1);
        trigger_end_frame = low_trigs_indices(end);
    % if voltage was not pulled low because this is a non-flapping trial,
    % just trim off first quarter and last quarter of trial
    elseif (wing_freq == 0)
        trigger_start_frame = round(length(results)*(1/4));
        trigger_end_frame = round(length(results)*(3/4));
    end

    % trim all data
    trimmed_results = results(trigger_start_frame:trigger_end_frame, :);
    % make time start at t = 0
    trimmed_results(:,1) = trimmed_results(:,1) - trimmed_results(1,1);

    % if trigger malfunctioned, alert user that data was not trimmed
    if (length(results) == length(trimmed_results))
        disp("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        disp("--------------Data was not trimmed.---------------")
        disp("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    end
end