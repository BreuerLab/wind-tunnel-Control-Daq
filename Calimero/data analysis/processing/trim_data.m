function trimmed_results = trim_data(results, rec_wingbeats, num_wingbeats, rate)

enc_pulse = results(:,10);
[beat_idx] = get_idx_wingbeats(enc_pulse, rate);
% disp("Number of long rises: " + length(long_rises_orig_idx))
% There is no long pulse at beginning of trial or at end of trial
% ^Wait, I don't think that's true. I think rec_wingbeats should equal
% length(long_rises_orig_idx)

num_pts = 48;
padding = ((rec_wingbeats - num_wingbeats) / 2)*num_pts;
startIdx = beat_idx(padding); % first padding revs ignored
endIdx = beat_idx(end - padding); % last padding revs ignored
trimmed_results = results(startIdx-1:endIdx-1,:); % shifted by 1 to include rising edge of first pulse and not rising edge of last pulse

time = beat_idx / rate;
pos = linspace(0,rec_wingbeats, length(beat_idx));
vel = gradient(pos, time);

figure
plot(time, vel)
xlabel("Time (seconds)")
ylabel("Wingbeat Frequency (Hz)")

plot_bool = true;
if plot_bool
figure
hold on
plot(results(:,1), enc_pulse)
xline(results(startIdx,1))
xline(results(endIdx,1))

figure
plot(trimmed_results(:,1), trimmed_results(:,10))
end

% Confirm that number of wingbeats now matches expectation
disp_str = "Number of wingbeats in trimmed data: ";
mid_idx = (num_wingbeats/2)*num_pts;
frames_per_beat = (beat_idx(mid_idx + num_pts) - beat_idx(mid_idx));
disp_calc = length(trimmed_results) / frames_per_beat;
disp(disp_str + disp_calc)

[beat_idx] = get_idx_wingbeats(trimmed_results(:,10), rate);

time = beat_idx / rate;
pos = linspace(0,num_wingbeats, length(beat_idx));
vel = gradient(pos, time);

figure
plot(time, vel)
xlabel("Time (seconds)")
ylabel("Wingbeat Frequency (Hz)")

% if trigger malfunctioned, alert user that data was not trimmed
if (length(results) == length(trimmed_results))
    disp("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    disp("--------------Data was not trimmed.---------------")
    disp("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
end
end