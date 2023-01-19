% I made this code to estimate what acceleration and number of cycles
% would be necessary to get the stepper motor up to speed.
% Ronan Gissler January 2022

rev_ticks = 53000;
init_pos = 0;
init_vel = 0;
acc = 2500; % 2000 counts/sec
desired_vel = 2*rev_ticks; % 1  rev/sec
desired_pos = 100*rev_ticks;

time_to_speed = desired_vel / acc;
at_speed_pos = init_pos + (init_vel * time_to_speed) ...
             + (0.5 * acc * (time_to_speed^2));
disp("By the time it reached " + (desired_vel/rev_ticks) ...
     + " Hz, it would have travelled " + (at_speed_pos/rev_ticks) ...
     + " revolutions")
