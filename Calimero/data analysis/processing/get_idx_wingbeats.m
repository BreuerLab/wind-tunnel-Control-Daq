function [beat_idx] = get_idx_wingbeats(enc_pulse, rate)
    % digitize pulses sent by galil
    enc_pulse_digital = zeros(size(enc_pulse));
    enc_pulse_digital(enc_pulse > 2.5) = 1;
    
    % Find rising and falling edges
    rise_idx = find(diff([0; enc_pulse_digital]) == 1);  % indices where 0 -> 1
    fall_idx = find(diff([enc_pulse_digital; 0]) == -1); % indices where 1 -> 0
    beat_idx = sort([rise_idx; fall_idx]);
    
    % Measure pulse widths
    pulse_widths = fall_idx - rise_idx;
    samples_per_ms = round(rate) / 1000;
    pulse_widths = pulse_widths / samples_per_ms; % convert to ms

    plot_bool = true;
    if (plot_bool)
    time = 0:1:length(enc_pulse)-1;
    time = time / rate;

    figure
    hold on
    yyaxis left
    plot(time, enc_pulse)
    ylabel("Analog Galil Timing Pulse")
    yyaxis right
    plot(time, enc_pulse_digital)
    scatter(time(beat_idx), enc_pulse_digital(beat_idx),40,"black", "filled")
    ylabel("Digitized Galil Timing Pulse")
    xlabel("Time (seconds)")

    figure
    histogram(pulse_widths,100)
    xlabel("Pulse width (ms)")
    ylabel("Frequency")
    end
end