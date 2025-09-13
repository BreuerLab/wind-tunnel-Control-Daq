function trimmed_results = trim_data(results, rec_wingbeats, num_wingbeats, rate)

enc_pulse = results(:,10);
long_rises_orig_idx = get_idx_wingbeats(enc_pulse, rate);
% disp("Number of long rises: " + length(long_rises_orig_idx))
% There is no long pulse at beginning of trial or at end of trial

padding = (rec_wingbeats - num_wingbeats) / 2;
startIdx = long_rises_orig_idx(padding);
endIdx = long_rises_orig_idx(end - (padding - 1));
trimmed_results = results(startIdx:endIdx,:);

% Confirm that number of wingbeats now matches expectation
disp_str = "Number of wingbeats in trimmed data: ";
mid_idx = num_wingbeats/2;
frames_per_beat = (long_rises_orig_idx(mid_idx+1) - long_rises_orig_idx(mid_idx));
disp_calc = length(trimmed_results) / frames_per_beat;
disp(disp_str + disp_calc)

% if trigger malfunctioned, alert user that data was not trimmed
if (length(results) == length(trimmed_results))
    disp("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    disp("--------------Data was not trimmed.---------------")
    disp("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
end
end