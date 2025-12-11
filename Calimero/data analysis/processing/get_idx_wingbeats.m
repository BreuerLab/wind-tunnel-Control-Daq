function [nextRev_idx] = get_idx_wingbeats(OC_pulse_count)
    OC_pulse_step = 4; % in ticks
    pulsesPerStep = 18432 / OC_pulse_step;
    
    idx_first_change = find(diff(OC_pulse_count) ~= 0, 1, 'first');
    idx_last_change = find(diff(OC_pulse_count) ~= 0, 1, 'last') + 1;
    trimmed_OC_pulse_count = OC_pulse_count(idx_first_change:idx_last_change);

    whole_idx = find(mod(trimmed_OC_pulse_count, pulsesPerStep) < 3);
    diff_idx = diff(whole_idx);
    nextRev_whole_idx = find(diff_idx ~= 1) + 1; % add 1 because diff shortens size of array
    nextRev_idx = whole_idx(nextRev_whole_idx);
end