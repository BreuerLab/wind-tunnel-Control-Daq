% I made this code to estimate the number of cycles to run the motor
% and the time to run the DAQ to best capture a 100 revolutions of
% force data (measure_revs = 100)

% Ronan Gissler
% July 2025

function [num_revs, session_duration, time_to_speed, at_speed_pos] = ...
    estimate_duration(vel, acc, measure_revs, padding_revs, hold_time, wait_time, print_bool)

    time_to_speed = vel / acc;
    if (print_bool)
    disp("It will take " + time_to_speed + ...
         " seconds, for the system to reach " + vel ...
         + " Hz")
    end

    at_speed_pos = (0.5 * acc * (time_to_speed^2));
    if (print_bool)
    disp("By the time it reaches " + vel ...
         + " Hz, it will have travelled " + at_speed_pos ...
         + " revolutions")
    end

    if (vel == 0) % for stationary glide test
        num_revs = 0;
        session_duration = hold_time;
    else
        num_revs = measure_revs + 2*(padding_revs + round((at_speed_pos) + 0.5));
        session_duration = round((num_revs / vel) + 2*time_to_speed) + (wait_time/1000);
    end
    if (print_bool)
    disp(num_revs ...
         + " revs will be recorded over a total session duration of " ...
         + session_duration + " seconds")
    end
end