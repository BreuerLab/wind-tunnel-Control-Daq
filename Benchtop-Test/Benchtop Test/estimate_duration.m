% I made this code to estimate the number of cycles to run the motor
% and the time to run the DAQ to best capture a 100 revolutions of
% force data (measure_revs = 100)

% Ronan Gissler January 2022

function [distance, session_duration] = estimate_duration(rev_ticks, acc, vel, measure_revs, padding_revs, wait_time)
    time_to_speed = vel / acc;
    disp("It will take " + time_to_speed + ...
         " seconds, for the system to reach " + (vel/rev_ticks) ...
         + " Hz")

    at_speed_pos = (0.5 * acc * (time_to_speed^2));
    disp("By the time it reached " + (vel/rev_ticks) ...
         + " Hz, it would have travelled " + (at_speed_pos/rev_ticks) ...
         + " revolutions")

    num_revs = measure_revs + 2*padding_revs + 2*(at_speed_pos/rev_ticks);
    distance = num_revs*rev_ticks;
    session_duration = (measure_revs + 2*padding_revs)/(vel/rev_ticks) ...
                     + 2*time_to_speed + 2*(wait_time/1000);
    disp("The session duration at the speed of " + ...
         (vel/rev_ticks) + " Hz, would be " + num_revs + ...
         " revs or " + session_duration + " seconds")
     
     distance = round(distance);
     session_duration = round(session_duration);
    
end