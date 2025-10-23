function motor_model(time_data, voltAdj, curAdj, freq)

% Motor Parameters
R = 51.4; % Ohms
L = 1.8e-3; % H, should be 1.8 mH but 0.8 H seems to work fairly well
k = 28.46e-3; % Nm/A, torque constant
gR = 9; % gear ratio
eff = 0.81; % gearbox efficiency

% thetaMod = unwrap(theta) / (gR*2*pi);
% speed = -gradient(thetaMod, 1/frame_rate);

frame_rate = 1 / (time_data(2) - time_data(1));
step = round(frame_rate / freq);

% ---------------------------------------

figure
hold on
yyaxis left
plot(time_data(step:2*step), curAdj(step:2*step))
xlabel("Time (sec)")
ylabel("Current (mA)")

yyaxis right
plot(time_data(step:2*step), voltAdj(step:2*step))
ylabel("Voltage (V)")
set(gca, FontSize=14)
set(findall(gca, 'Type', 'line'), 'LineWidth', 2)

% -------------------

fc = 100; % cutoff frequency
fs = frame_rate;
[b,a] = butter(6, fc/(fs/2));
curAdjFilt = filtfilt(b,a,curAdj);
voltAdjFilt = filtfilt(b,a,voltAdj);

% fc = 30; % cutoff frequency
% fs = frame_rate;
% [b,a] = butter(6, fc/(fs/2));
% speedFilt = filtfilt(b,a,speed);

% ----------------------

% figure
% plot(time_data(step:2*step), speedFilt(step:2*step))
% xlabel("Time (sec)")
% ylabel("Hz")
% title("Filtered Speed (6 Hz commanded) f_c = 30 Hz")
% set(gca, FontSize=14)
% set(findall(gca, 'Type', 'line'), 'LineWidth', 2)


startIdx = 1*step;
endIdx = 2*step;
% -------------------

figure
hold on
yyaxis left
plot(time_data(startIdx:endIdx), curAdjFilt(startIdx:endIdx))
xlabel("Time (sec)")
ylabel("Current (mA)")

yyaxis right
plot(time_data(startIdx:endIdx), voltAdjFilt(startIdx:endIdx))
ylabel("Voltage (V)")
title("Filtered Current and Voltage f_c = 100 Hz")
set(gca, FontSize=14)
set(findall(gca, 'Type', 'line'), 'LineWidth', 2)

% -------------------
speedFilt = freq*ones(size(curAdjFilt));
% voltMod = k*(freq*2*pi*gR) + R*(curAdjFilt/1000) + L*gradient(curAdjFilt/1000, 1/frame_rate);
mechTerm = k*(speedFilt*2*pi*gR); % Nm/A = V/(speed in rad/s)
resTerm = R*(curAdjFilt/1000);
indTerm = L*gradient(curAdjFilt/1000, 1/frame_rate);
voltMod = mechTerm + resTerm + indTerm;

% voltAdjFilt = voltAdjFilt - 2.2*(curAdjFilt/1000); % just interested in voltage drop across motor, not CLR

% cur_dt = gradient(curAdjFilt/1000, 1/frame_rate);
% figure
% plot(time_data(step:2*step), cur_dt(step:2*step))

figure
hold on
plot(time_data(step:2*step), voltAdjFilt(step:2*step), DisplayName="Voltage Measured")
plot(time_data(step:2*step), voltMod(step:2*step), DisplayName="Voltage Predicted")
xlabel("Time (sec)")
ylabel("Voltage (V)")
legend()
set(gca, FontSize=14)
set(findall(gca, 'Type', 'line'), 'LineWidth', 2)

figure
hold on
plot(time_data(step:2*step), mechTerm(step:2*step), DisplayName="Mechanical Term")
plot(time_data(step:2*step), resTerm(step:2*step), DisplayName="Resistance Term")
plot(time_data(step:2*step), indTerm(step:2*step), DisplayName="Inductance Term")
xlabel("Time (sec)")
ylabel("Voltage (V)")
legend()
set(gca, FontSize=14)
set(findall(gca, 'Type', 'line'), 'LineWidth', 2)

torque = k*(curAdjFilt/1000)*1000;
outTorque = torque*gR*eff;
figure
hold on
plot(time_data(step:2*step), torque(step:2*step), DisplayName="Motor Torque")
plot(time_data(step:2*step), outTorque(step:2*step), DisplayName="Output Torque")
xlabel("Time (sec)")
ylabel("Torque (mNm)")
legend()
set(gca, FontSize=14)
set(findall(gca, 'Type', 'line'), 'LineWidth', 2)
