function norm_signal = get_norm_signal(results, phase_type, pulsesPerRev, cycle_freq, laser_ind, num_images)

switch phase_type
    case 0
        disp("Using motor position for phase")

        % motor position is recorded using OC pulses sent by galil
        % 1 revolution of the motor corresponds to pulsesPerRev
        % pulses
        OC_pulse_count = results(:,11);
        
        % normalized signal where 1 now represents 1 full rotation/wingbeat
        norm_signal = OC_pulse_count / pulsesPerRev;
    case 1
        disp("Using time for phase")

        time = results(:,1);

        % normalized signal where 1 now represents 1 full rotation/wingbeat
        norm_signal = time * cycle_freq;
end

% find signal value corresponding to laser pulse
norm_signal = norm_signal(laser_ind);

disp("Cropped off " + (length(norm_signal) - num_images) + " extra laser pulses from beginning")
% crop off first few extra pulses
norm_signal = norm_signal(end-(num_images - 1):end);

% wrap values so only expressed between 0 and 1
norm_signal = mod(norm_signal, 1);

end