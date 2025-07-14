% I made this code to estimate the number of cycles to run the motor
% and the time to run the DAQ to best capture a 100 revolutions of
% force data (measure_revs = 100)

% Ronan Gissler
% July 2025

function session_duration = estimate_duration(vel, measure_revs, padding_revs, hold_time)

    if (vel == 0) % for stationary glide test
        num_revs = 0;
        session_duration = hold_time;
    else
        num_revs = measure_revs + 2*padding_revs;
        session_duration = round((num_revs / vel)*10);
    end
    disp(num_revs ...
         + " revs will be recorded over a total session duration of " ...
         + session_duration + " seconds")
end