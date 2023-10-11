% I made this code to estimate the number of cycles to run the motor
% and the time to run the DAQ to best capture a 100 revolutions of
% force data (measure_revs = 100)

% Ronan Gissler January 2022

function [distance, session_duration, trigger_pos] = estimate_duration...
         (rev_ticks, acc, vel, measure_revs, padding_revs, wait_time, hold_time)
    
    time_to_speed = vel / acc;
    disp("It will take " + time_to_speed + ...
         " seconds, for the system to reach " + (vel/rev_ticks) ...
         + " Hz")

    at_speed_pos = (0.5 * acc * (time_to_speed^2));
    disp("By the time it reaches " + (vel/rev_ticks) ...
         + " Hz, it will have travelled " + (at_speed_pos/rev_ticks) ...
         + " revolutions")

    % round up to nearest integer (ex: 0.4 -> 1)
    trigger_pos = rev_ticks*round((at_speed_pos/rev_ticks) + 0.5);
    % Add another revolution for good measure
    trigger_pos = trigger_pos + padding_revs*rev_ticks;

    if (vel == 0)
        num_revs = 0;
        distance = 0;
        session_duration = hold_time; % for stationary test
    else
        num_revs = measure_revs + 2*(trigger_pos/rev_ticks);
        distance = round(num_revs*rev_ticks);
        session_duration = round((measure_revs)/(vel/rev_ticks) ...
                        + 2*time_to_speed + 2*(wait_time/1000));
    end
    disp(num_revs ...
         + " revs will be recorded over a total session duration of " ...
         + session_duration + " seconds")
end