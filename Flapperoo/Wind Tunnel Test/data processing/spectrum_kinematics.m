clear
close all

addpath modeling\

wing_freq = 4;
CAD_bool = true;
[time, ang_disp, ang_vel, ang_acc] = get_kinematics(wing_freq, CAD_bool);

figure
plot(time, ang_acc)
xlabel("Time (s)")
ylabel("Angular Acceleration (rad / s^2)")

ang_acc = repmat(ang_acc, 100, 1);

% min freq is 1 / ((1 / freq) * (180 wingbeats))
% = freq / 180

frame_rate = 202*wing_freq;
f_min = 0.2;
window = frame_rate / f_min;
num_windows = round(length(ang_acc) / window);
noverlap = window/2;

% note mean knows to take the mean of the columns
signal = ang_acc - mean(ang_acc);
[pxx, f] = pwelch(signal, window, noverlap, window, frame_rate);
% [pxx, f] = pwelch(signal);
power = 10*log10(pxx);

figure
plot(f, power)
xlabel("Frequency (Hz)")
ylabel("Power (dB / Hz)")
xlim([0 100])

figure
plot(f / wing_freq, power)
xlabel("Normalized Frequency")
ylabel("Power (dB / Hz)")
grid on
xlim([0 20])

r = 0:0.001:10;
T_d = abs(1 ./ (1 - r.^2)); % displacement transmissibility
figure
plot(r, T_d)
xlabel("Frequency Ratio r = \omega / \omega_n")
ylabel("Amplification Ratio")
ylim([0 2])
xlim([0 4])