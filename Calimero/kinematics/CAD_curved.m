clear
close all

data_path_F = "R:\ENG_Breuer_Shared\rgissler\Solidworks\Calimero\Data\flat_slot_motion.csv";
data_path_C = "R:\ENG_Breuer_Shared\rgissler\Solidworks\Calimero\Data\curved_down_slot_motion.csv";

data_F = readmatrix(data_path_F,"NumHeaderLines",2);
time_F = data_F(:,1);
phi_F = data_F(:,2);

% Find peaks
[peaks, locs] = findpeaks(phi_F);

% Get index of first peak
firstPeakIdx = locs(1);

% Trim signal and time vector
time_F_trimmed = time_F(firstPeakIdx:end);
time_F_trimmed = time_F_trimmed - time_F_trimmed(1); % reset zero time
phi_F_trimmed = phi_F(firstPeakIdx:end);

data_C = readmatrix(data_path_C,"NumHeaderLines",2);
time_C = data_C(:,1);
phi_C = data_C(:,2);

% Find peaks
[peaks, locs] = findpeaks(phi_C);

% Get index of first peak
firstPeakIdx = locs(1);

% Trim signal and time vector
time_C_trimmed = time_C(firstPeakIdx:end);
time_C_trimmed = time_C_trimmed - time_C_trimmed(1); % reset zero time
phi_C_trimmed = phi_C(firstPeakIdx:end);

% --------------------------------------------------------
% Plotting angular velocity of motion from equation compared with motion
% measured from CAD, validates the equation
% --------------------------------------------------------
figure
hold on
plot(time_F, phi_F, DisplayName="Flat Slot", LineWidth=2)
plot(time_C, phi_C, DisplayName="Curved Slot", LineWidth=2)
xlim([0 1])
title("Wing angle calculated from SolidWorks Motion Analysis")
legend()

figure
hold on
plot(time_F_trimmed, phi_F_trimmed, DisplayName="Flat Slot", LineWidth=2)
plot(time_C_trimmed, phi_C_trimmed, DisplayName="Curved Slot", LineWidth=2)
xlim([0 1])
title("Wing angle calculated from SolidWorks Motion Analysis")
legend()

figure
hold on
plot(time_F_trimmed, phi_F_trimmed - phi_F_trimmed(1), DisplayName="Flat Slot", LineWidth=2)
plot(time_C_trimmed, phi_C_trimmed - phi_C_trimmed(1), DisplayName="Curved Slot", LineWidth=2)
xlim([0 1])
title("Wing angle calculated from SolidWorks Motion Analysis")
legend()