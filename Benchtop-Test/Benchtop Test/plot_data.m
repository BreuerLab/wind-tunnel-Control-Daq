clear
close all

% Ronan Gissler January 2023

% This file is used to analyze the data from the experiments Sakthi
% and I ran with the 1 DOF flapper robot outfitted with
% Polydimethylsiloxane (PDMS) and Carbon Black (CB) wings on December
% 2nd 2022. We tested flapping speeds between 1 Hz and 3 Hz (or so we
% thought, this was set by adjusting the speed command to the motor).
% It doesn't appear that the flapper got much faster than 1.5 Hz
% though and for large portions of the recorded data the flapper is
% accelerating up to the set speed since we used a small acceleration
% value to reduce stress on the system. During part of the wingbeat
% which corresponds to a full rotation of the bevel gears, the gears
% make a grinding noise. There seemed to be a resonant frequency of
% the system that amplified this grinding making it painful to listen
% to. This peak in grinding occurred twice for most tests leading me
% to believe this was as a result of the system hitting the resonant
% frequency once on acceleration and once on deceleration.

% Next steps: 
% - Can I monitor actual wingbeat occurence from stepper code (rather
% than frequency analysis of force data as I'm doing now)? 
% - Why are wings not beating at the prescribed frequency? I think the
% acceleration is much too slow. With the current setup it would take
% 80 seconds to accelerate to 3 Hz, so the flapper starts decelerating
% back to zero long before then given the relatively short measurement
% period. So either I increase the acceleration or the measurement
% period.
% - What can I do to mitigate the grinding? Would it help if I mounted
% a rubber pad to the system to dissipate vibrations?
% - How is the speed and noise affected if I try running fast
% frequency tests without wings attached?

%%

% ----------------------------------------------------------------
% ------------------------Plot All Data---------------------------
% ----------------------------------------------------------------

% files = ["12_02_2022_benchtop_test/1Hz_25cycles_PDMSwing_experiment_120222.csv"
%          "12_02_2022_benchtop_test/1Hz_100cycles_CBwing_2000acc_experiment_120222.csv"
%          "12_02_2022_benchtop_test/2.5Hz_50cycles_PDMSwing_2000acc_experiment_120222.csv"
%          "12_02_2022_benchtop_test/2.5Hz_100cycles_CBwing_2000acc_experiment_120222.csv"
%          "12_02_2022_benchtop_test/2.5Hz_100cycles_PDMSwing_2000acc_experiment_120222.csv"
%          "12_02_2022_benchtop_test/2Hz_50cycles_PDMSwing_4000acc_experiment_120222.csv"
%          "12_02_2022_benchtop_test/2Hz_50cycles_PDMSwing_experiment_120222.csv"
%          "12_02_2022_benchtop_test/2Hz_100cycles_CBwing_2000acc_experiment_120222.csv"
%          "12_02_2022_benchtop_test/3Hz_100cycles_CBwing_2000acc_experiment_120222.csv"
%          "12_02_2022_benchtop_test/3Hz_100cycles_PDMSwing_2000acc_experiment_120222.csv"];
% 
% for i = 1:length(files)
%     %%
%     
%     % Get case name from file name
%     case_name = erase(files(i), ["12_02_2022_benchtop_test/", "_experiment_120222.csv"]);
%     case_name = strrep(case_name,'_',' ');
%     
%     % Get data from file
%     data = readmatrix(files(i));
% 
%     times = data(1:end,1);
%     force_vals = data(1:end,2:7);
%     
%     % Open a new figure.
%     f = figure;
%     f.Position = [200 50 900 560];
% 
%     % Create three subplots to show the force time histories. 
%     subplot(2, 3, 1);
%     plot(times, force_vals(:, 1));
%     title("F_x");
%     xlabel("Time (s)");
%     ylabel("Force (N)");
%     subplot(2, 3, 2);
%     plot(times, force_vals(:, 2));
%     title("F_y");
%     xlabel("Time (s)");
%     ylabel("Force (N)");
%     subplot(2, 3, 3);
%     plot(times, force_vals(:, 3));
%     title("F_z");
%     xlabel("Time (s)");
%     ylabel("Force (N)");
% 
%     % Create three subplots to show the moment time histories.
%     subplot(2, 3, 4);
%     plot(times, force_vals(:, 4));
%     title({"M_x" ""});
%     xlabel("Time (s)");
%     ylabel("Torque (N m)");
%     subplot(2, 3, 5);
%     plot(times, force_vals(:, 5));
%     title({"M_y" ""});
%     xlabel("Time (s)");
%     ylabel("Torque (N m)");
%     subplot(2, 3, 6);
%     plot(times, force_vals(:, 6));
%     title({"M_z" ""});
%     xlabel("Time (s)");
%     ylabel("Torque (N m)");
%     
%     % Label the whole figure.
%     sgtitle("Force Transducer Measurement for " + case_name);
% end

%%

% ----------------------------------------------------------------
% ----------------------Plot Carbon Black Data--------------------
% -----during perceived speed peak between 34 and 38 seconds------
% --------determined by watching video of 3 Hz CB trial-----------
% ----------------------------------------------------------------

files = ["12_02_2022_benchtop_test/3Hz_100cycles_CBwing_2000acc_experiment_120222.csv"
         "12_02_2022_benchtop_test/2.5Hz_100cycles_CBwing_2000acc_experiment_120222.csv"
         "12_02_2022_benchtop_test/2Hz_100cycles_CBwing_2000acc_experiment_120222.csv"
         "12_02_2022_benchtop_test/1Hz_100cycles_CBwing_2000acc_experiment_120222.csv"];
     
% files = ["12_02_2022_benchtop_test/3Hz_100cycles_CBwing_2000acc_experiment_120222.csv"];
% files = ["12_02_2022_benchtop_test/1Hz_25cycles_PDMSwing_experiment_120222.csv"
%          "12_02_2022_benchtop_test/2.5Hz_50cycles_PDMSwing_2000acc_experiment_120222.csv"
%          "12_02_2022_benchtop_test/2.5Hz_100cycles_PDMSwing_2000acc_experiment_120222.csv"
%          "12_02_2022_benchtop_test/2Hz_50cycles_PDMSwing_4000acc_experiment_120222.csv"
%          "12_02_2022_benchtop_test/2Hz_50cycles_PDMSwing_experiment_120222.csv"
%          "12_02_2022_benchtop_test/3Hz_100cycles_PDMSwing_2000acc_experiment_120222.csv"];

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction)");
xlabel("Time (s)");
ylabel("Force (N)");
hold on

for i = 1:length(files)
    % Get case name from file name
    case_name = erase(files(i), ["12_02_2022_benchtop_test/", "_experiment_120222.csv"]);
    case_name = strrep(case_name,'_',' ');
    
    % Get data from file
    data = readmatrix(files(i));

    times = data(1:end,1);
    force_vals = data(1:end,2:7);

    % Plot lift force
    plot(times, force_vals(:, 3), 'DisplayName', case_name, "LineWidth",3);
end
legend("Location","Southwest");


% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Lift Force (z-direction)");
xlabel("Time (s)");
ylabel("Force (N)");
hold on

for i = 1:length(files)
    % Get case name from file name
    case_name = erase(files(i), ["12_02_2022_benchtop_test/", "_experiment_120222.csv"]);
    case_name = strrep(case_name,'_',' ');
    
    % Get data from file
    data = readmatrix(files(i));
    data = data(34*1000:38*1000,:);

    times = data(1:end,1);
    force_vals = data(1:end,2:7);

    % Plot lift force
    plot(times, force_vals(:, 3), 'DisplayName', case_name, "LineWidth",3);
end
legend("Location","Southwest");

%%

% ----------------------------------------------------------------
% -----------------Plot FILTERED Carbon Black Data----------------
% -----during perceived speed peak between 34 and 38 seconds------
% --------determined by watching video of 3 Hz CB trial-----------
% ----------------------------------------------------------------

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Filtered Lift Force (z-direction)");
xlabel("Time (s)");
ylabel("Force (N)");
hold on

for i = 1:length(files)
    % Get case name from file name
    case_name = erase(files(i), ["12_02_2022_benchtop_test/", "_experiment_120222.csv"]);
    case_name = strrep(case_name,'_',' ');
    
    % Get data from file
    data = readmatrix(files(i));
    data = data(34*1000:38*1000,:);

    times = data(1:end,1);
    force_vals = data(1:end,2:7);
    
    % Filtering force transducer data with a butterworth filter
    fc = 3; % cutoff frequency
    fs = 1000; % sample frequency

    [b,a] = butter(6,fc/(fs/2)); % 6th order
    force_vals = filter(b, a, force_vals);

    % Plot lift force
    plot(times, force_vals(:, 3), 'DisplayName', case_name, "LineWidth",3);
end
legend("Location","Southwest");

%%

% ----------------------------------------------------------------
% ---------------------------Trashed Code-------------------------
% ----------------------------------------------------------------

% Fast Fourier Transform stuff I was looking at for a bit...

% f = figure;
% f.Position = [200 50 900 560];
% %instfreq(force_vals(:, 3),fs)
% Y = fft(force_vals(:, 3));
% L = 2000;
% P2 = abs(Y/L);
% P1 = P2(1:L/2+1);
% P1(2:end-1) = 2*P1(2:end-1);
% 
% freqs = fs*(0:(L/2))/L;
% plot(freqs,P1) 
% title("Single-Sided Amplitude Spectrum of Force Transdcuer Data")
% xlabel("f (Hz)")
% ylabel("|P1(f)|")
% xlim([0,10])

% instantaneous frequency stuff I was trying...

% Open a new figure.
f = figure;
f.Position = [200 50 900 560];
title("Instantaneous Frequency of Force in z-direction");
xlabel("Time (s)");
ylabel("Force Frequency i.e. Wing Speed (Hz)");
hold on

for i = 1:length(files)
    % Get case name from file name
    case_name = erase(files(i), ["12_02_2022_benchtop_test/", "_experiment_120222.csv"]);
    case_name = strrep(case_name,'_',' ');
    
    % Get data from file
    data = readmatrix(files(i));

    times = data(1:end,1);
    force_vals = data(1:end,2:7);
    
    % Filtering force transducer data with a butterworth filter
    fc = 3; % cutoff frequency
    fs = 1000; % sample frequency

    [b,a] = butter(6,fc/(fs/2)); % 6th order
    force_vals = filter(b, a, force_vals);

%     [s,f,t] = stft(force_vals(:, 3),fs);
%     stft(s(64,:),fs);
%     force_vals(:, 3) = force_vals(:, 3) - mean(force_vals(:, 3));
%     stft(force_vals(:, 3),fs,'Window',kaiser(1024,5),'OverlapLength',500,'FFTLength',1024, 'FrequencyRange','centered');

%     pspectrum(force_vals(:, 3),fs,'spectrogram');
%     ylim([0,10]);

    [ifq,t] = instfreq(force_vals(:, 3),fs);
    
    % Filtering instantaneous frequency with a butterworth filter
    window = 100;
    b = 1/window*ones(window,1);
    ifq = filter(b, 1, ifq);
    
    plot(t, ifq, 'DisplayName', case_name, "LineWidth", 3)
end
legend("Location","Southwest");