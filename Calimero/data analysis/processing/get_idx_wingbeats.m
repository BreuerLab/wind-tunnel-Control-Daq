function [nextRev_idx] = get_idx_wingbeats(OC_pulse_count)
    OC_pulse_step = 4; % in ticks
    pulsesPerStep = 18432 / OC_pulse_step;
    
    idx_first_change = find(diff(OC_pulse_count) ~= 0, 1, 'first');
    idx_last_change = find(diff(OC_pulse_count) ~= 0, 1, 'last') + 1;
    trimmed_OC_pulse_count = OC_pulse_count(idx_first_change:idx_last_change);

    % accurate to 3 / 4608 (pulsesPerStep)
    % At 12 kHz and 2 Hz (2*4608 pulsesPerSec), we'd expect 12000 / (2*4608)
    % = 1.3 samples per pulse. At 10 Hz, we'd expect 12000 / (10*4608) = 
    % 0.26 samples per pulse or 3.84 pulses for every sample. If it moved
    % at a perfectly constant speed which of course it doesn't
    wingbeat_rem = mod(trimmed_OC_pulse_count, pulsesPerStep);
    dist_from_wingbeat = min(wingbeat_rem, pulsesPerStep - wingbeat_rem);
    whole_idx = find(dist_from_wingbeat < 8);

    diff_idx = diff(whole_idx);
    nextRev_whole_idx = find(diff_idx ~= 1 & diff_idx > 1000) + 1; % add 1 because diff shortens size of array
    % "& diff_idx > 1000" added since noise in encoder signal resulted in jump
    nextRev_idx = whole_idx(nextRev_whole_idx);
end