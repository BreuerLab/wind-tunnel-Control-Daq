function wing_freq = getFreq(enc_data, rate, session_duration)
    % Compute Power Density Spectrum (using pwelch)
    [freq, freq_power, ~, ~] = freq_spectrum(enc_data, rate, session_duration);

     [~, locs] = findpeaks(freq_power, freq, 'SortStr', 'descend');
    wing_freq = locs(1) / 9; % Most dominant frequency in z direction (vertical)
    % divided by 9 since gearbox ratio is 9
end