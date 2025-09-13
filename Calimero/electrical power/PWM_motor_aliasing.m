% Parameters
f_signal = 5000;      % Signal frequency in Hz
fs = 10000;           % Sampling frequency in Hz
T = 1 / f_signal;     % Period of the signal
duration = 10 * T;     % Simulate 3 periods
dt_fine = 1e-6;       % High-res time step for continuous signal

% Time vectors
t_fine = 0:dt_fine:duration;       % High-res for original waveform

% Square wave: 0 to 2V
ideal_square = 0.5 * (square(2*pi*f_signal*t_fine) + 1) * 2;

% Add a peak before the falling edge (2V to 5V)
peak_width = round(10e-6 / dt_fine);  % width in points (~10 µs)
fall_edge_idx = find(diff(ideal_square) < -1);  % detect 2V to 0V transitions
for i = fall_edge_idx
    if i - peak_width > 0
        ideal_square(i - peak_width:i) = ...
            ideal_square(i - peak_width:i) + linspace(0, 3, peak_width + 1); % 2V to 5V
    end
end
ideal_square = min(ideal_square, 5);  % Clip to max 5V

% Sampling with phase offset
phase_offset = 300e-6;  % 20 µs offset
t_sampled = phase_offset:1/fs:duration + phase_offset;

% Sample the distorted waveform
sampled_signal = interp1(t_fine, ideal_square, t_sampled, 'nearest', 'extrap');

% Plot
figure;
subplot(2,1,1);
plot(t_fine*1e3, ideal_square, 'LineWidth', 1.2);
title('Modified 5 kHz Signal (0-2V with 2-5V Peak)');
xlabel('Time (ms)');
ylabel('Voltage (V)');

subplot(2,1,2);
stem(t_sampled*1e3, sampled_signal, 'filled');
title('Sampled Signal at 10 kHz with Phase Offset (Aliasing Visible)');
xlabel('Time (ms)');
ylabel('Voltage (V)');

sgtitle('Effect of Sampling Phase Offset on Aliased Waveform');
