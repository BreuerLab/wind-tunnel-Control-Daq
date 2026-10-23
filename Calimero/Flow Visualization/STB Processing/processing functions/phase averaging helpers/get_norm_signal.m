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
    case 2
        disp("Using time for phase, re-anchored to the encoder every cycle")
        norm_signal = reanchored_time_phase(results, pulsesPerRev);
end

% wrap values so only expressed between 0 and 1
norm_signal = mod(norm_signal, 1);

% phase averaging STB fields requires laser firing info
if nargin > 4
% find signal value corresponding to laser pulse
norm_signal = norm_signal(laser_ind);

disp("Cropped off " + (length(norm_signal) - num_images) + " extra laser pulses from beginning")
% crop off first few extra pulses
norm_signal = norm_signal(end-(num_images - 1):end);
end

end

function phase = reanchored_time_phase(results, pulsesPerRev)
% Time-based phase that restarts at every encoder zero crossing:
%   phase = (t - t_start of this cycle) / (period of this cycle)
% Within a cycle, phase is proportional to time, so equal phase bins are
% equal time slices (undistorted frozen-flow spacing). Because it is
% re-anchored to the wing at the start of every cycle, errors in the
% assumed frequency or slow frequency drift cannot accumulate over the
% recording, unlike mod(time * cycle_freq, 1).

time = results(:,1);
enc_phase = mod(results(:,11) / pulsesPerRev, 1); % OC pulse count -> cycles

% cycle starts: encoder phase wraps from ~1 back to ~0
wrap_idx = find(diff(enc_phase) < -0.5);
if numel(wrap_idx) < 2
    error("get_norm_signal:fewCycles", "Fewer than 2 encoder cycles found; cannot re-anchor the time phase.")
end

% interpolate the crossing time between the samples either side of the wrap
p0 = enc_phase(wrap_idx);
p1 = enc_phase(wrap_idx + 1) + 1;
t0 = time(wrap_idx);
t1 = time(wrap_idx + 1);
t_start = t0 + (1 - p0) ./ (p1 - p0) .* (t1 - t0);

% ignore spurious crossings (encoder count jittering back across zero):
% keep only starts at least half a typical period after the previous one
typical_period = median(diff(t_start));
keep = [true; diff(t_start) > 0.5 * typical_period];
t_start = t_start(keep);

periods = diff(t_start);
mean_period = mean(periods);

% cycle each sample belongs to (0 = before the first crossing)
cycle_idx = discretize(time, [-inf; t_start; inf]) - 1;

phase = NaN(size(time));
in_full_cycle = cycle_idx >= 1 & cycle_idx <= numel(periods);
k = cycle_idx(in_full_cycle);
phase(in_full_cycle) = (time(in_full_cycle) - t_start(k)) ./ periods(k);

% partial cycles at the start / end of the recording: use the mean period
before = cycle_idx == 0;
phase(before) = 1 - (t_start(1) - time(before)) / mean_period;
after = cycle_idx > numel(periods);
phase(after) = (time(after) - t_start(end)) / mean_period;

disp("Re-anchored over " + numel(periods) + " cycles; period " + ...
    sprintf("%.5f s mean, %.2f%% std", mean_period, 100*std(periods)/mean_period))
end