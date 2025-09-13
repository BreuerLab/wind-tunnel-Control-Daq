function long_rises_orig_idx = get_idx_wingbeats(enc_pulse, rate)
    enc_pulse_digital = zeros(size(enc_pulse));
    enc_pulse_digital(enc_pulse > 2) = 1;
    
    % Find rising and falling edges
    rise_idx = find(diff([0; enc_pulse_digital]) == 1);  % indices where 0 -> 1
    fall_idx = find(diff([enc_pulse_digital; 0]) == -1); % indices where 1 -> 0
    
    % Measure pulse widths
    pulse_widths = fall_idx - rise_idx;
    samples_per_ms = round(rate) / 1000;
    pulse_widths = pulse_widths / samples_per_ms; % convert to seconds
    
    % Select rising edges of "long" pulses
    long_rises_orig_idx = rise_idx(pulse_widths > 3.5);
    long_rises_pulses_idx = find(pulse_widths > 3.5);
end