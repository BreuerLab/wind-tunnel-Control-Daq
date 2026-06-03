function [f, power, num_windows, f_min] = freq_spectrum(results, frame_rate, session_duration)
    f_min = 1/session_duration;
    window = frame_rate / f_min;
    num_windows = round(length(results) / window);
    noverlap = window/2;

    [pxx, f] = pwelch(detrend(results'), window, noverlap, window, frame_rate);
    power = 10*log10(pxx);
end