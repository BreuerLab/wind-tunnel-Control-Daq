clear
close all

file_path = "R:\ENG_Breuer_Shared\rgissler\Solidworks\CalimeroV3\MotorTorque_gearsZoomed_08_07_2025_03_42_PM.csv";

T = readtable(file_path);
torque = T.MotorTorque3_newton_mm_;
time = T.Time_sec_;

framesPerWingbeat = round(length(time) / time(end));

[M, I] = min(abs(time - 0.2));
start = I;

figure
plot(time(1:1+framesPerWingbeat), torque(1:1+framesPerWingbeat))
xlabel("Time")
ylabel("Torque")
set(gca, FontSize=14)
set(findall(gca, 'Type', 'line'), 'LineWidth', 2)

figure
plot(time(I:I+framesPerWingbeat), torque(I:I+framesPerWingbeat))
xlabel("Time")
ylabel("Torque")
set(gca, FontSize=14)
set(findall(gca, 'Type', 'line'), 'LineWidth', 2)