function [f, power, dominant_freq] = freq_spectrum(results, frame_rate)
    [pxx, f] = pwelch(results, frame_rate*2, 50, frame_rate*2, frame_rate);
    power = 10*log10(pxx);

    % drop higher frequency data where not much is going on anyways
    f = f(1:500);
    power = power(1:500, :);

    [M,I] = max(power);
    dominant_freq = f(I);
end