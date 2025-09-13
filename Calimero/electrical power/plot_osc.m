clear
close all

% CH1_file = "C:\Users\rgissler\Downloads\Galil\Galil\035_setting\F0003CH1.csv";
% CH3_file = "C:\Users\rgissler\Downloads\Galil\Galil\035_setting\F0003CH3.csv";

% CH1_file = "C:\Users\rgissler\Downloads\Galil\Galil\050_setting\F0002CH1.csv";
% CH3_file = "C:\Users\rgissler\Downloads\Galil\Galil\050_setting\F0002CH3.csv";

CH1_file = "C:\Users\rgissler\Downloads\Galil\Galil\ALL0000\F0000CH1.csv";
CH3_file = "C:\Users\rgissler\Downloads\Galil\Galil\ALL0000\F0000CH3.csv";

CH1_data = readmatrix(CH1_file);
CH1_time = CH1_data(:,4);
CH1_signal = CH1_data(:,5);

CH3_data = readmatrix(CH3_file);
CH3_time = CH3_data(:,4);
CH3_signal = CH3_data(:,5);

fc = 5 / (1e-06); % Hz
fs = 1 / (1e-08); % 100 MHz
[b,a] = butter(6,fc/(fs/2));
CH1_filt = filtfilt(b,a,CH1_signal);
CH3_filt = filtfilt(b,a,CH3_signal);

[pks,locs,w,p] = findpeaks(gradient(CH1_filt));
pks = pks(p > 1);
locs = locs(p > 1);
pk_times = CH1_time(locs);

figure
hold on
yyaxis left
plot(CH1_time, CH1_signal)
yyaxis right
plot(CH3_time, CH3_signal)

figure
hold on
yyaxis left
plot(CH1_time, gradient(CH1_filt))
yyaxis right
plot(CH3_time, gradient(CH3_filt))

CH1_time_trim = CH1_time(locs(1):locs(2));
CH1_signal_trim = -CH1_signal(locs(1):locs(2)) + 24;
CH3_time_trim = CH3_time(locs(1):locs(2));
CH3_signal_trim = CH3_signal(locs(1):locs(2));

figure
hold on
yyaxis left
plot(CH1_time_trim, CH1_signal_trim)
yyaxis right
plot(CH3_time_trim, CH3_signal_trim)
title(["Mean Voltage: " + mean(CH1_signal_trim) + " V" ...
       "Mean Current: " + mean(CH3_signal_trim) + " A"])