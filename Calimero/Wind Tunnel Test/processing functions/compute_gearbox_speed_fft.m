function gearbox_speed = compute_gearbox_speed_fft(time, voltage)
    % compute_gearbox_speed_fft - Estimate gearbox speed using FFT of encoder signal
    % Syntax: gearbox_speed = compute_gearbox_speed_fft(time, voltage)
    % Inputs:
    %   time    - Vector of time samples (in seconds)
    %   voltage - Vector of analog encoder voltage values (ramp 0-3.3V)
    % Output:
    %   gearbox_speed - Estimated output speed of the gearbox (Hz)    % Ensure column vectors
    time = time(:);
    voltage = voltage(:);    % Remove DC component (mean voltage)
    voltage = voltage - mean(voltage);    % Sampling parameters

    dt = mean(diff(time));      % Time step
    Fs = 1 / dt;                % Sampling frequency
    N = length(voltage);        % Number of samples    % Apply Hanning window to reduce spectral leakage
    window = hann(N);
    voltage_windowed = voltage .* window;    % FFT computation
    V = fft(voltage_windowed);
    f = (0:N-1) * (Fs / N);     % Frequency axis    % Compute magnitude spectrum
    magnitude = abs(V) / N;    % Consider only first half of the spectrum (positive frequencies)
    half_N = floor(N / 2);
    f = f(1:half_N);
    magnitude = magnitude(1:half_N);    % Ignore very low frequencies (e.g., DC and near-zero noise)
    
    min_freq = 0.1; % Hz
    valid_idx = f > min_freq;    % Find index of peak frequency
    [~, idx_max] = max(magnitude(valid_idx));
    freq_motor = f(valid_idx);
    dominant_freq = freq_motor(idx_max); % Motor rotation frequency    % Divide by 9 for gearbox output speed
    gearbox_speed = dominant_freq / 9;
end
