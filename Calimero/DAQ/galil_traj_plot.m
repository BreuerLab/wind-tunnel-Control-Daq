function [TimeArr, Current, DesPos, ActPos, ActVel] = galil_traj_plot(g)
ticksPerRev = 18432;
AG = 0.4;
TM = 1000; % TM 1000 corresponds to 976 microseconds, 1 increment in TM for every 1000

TimeArr = g.arrayUpload('TimeArr');
TimeArr = cell2mat(TimeArr);
TimeArr = ((TimeArr - TimeArr(1)) * (TM / 1000) * 0.976) / 1000; % increments by 1 every 976 microseconds
dt = round(TimeArr(2) - TimeArr(1),4);
I = find(round(diff(TimeArr),4) ~= dt, 1, "first");
if isempty(I)
    disp("Oops, no ending index found...")
    I = length(TimeArr);
end

Torque = g.arrayUpload('Torque');
Torque = cell2mat(Torque);
VoltCommand = Torque * (10 / 32767); % motor command in volts, 10 V for every 32767 (see RD in command reference for Galil)
Current = AG * VoltCommand * 1000; % current in mA

DesPos = g.arrayUpload('DesPos');
DesPos = cell2mat(DesPos);
DesPos = DesPos / ticksPerRev;

ActPos = g.arrayUpload('ActPos');
ActPos = cell2mat(ActPos);
ActPos = ActPos / ticksPerRev;

ActVel = g.arrayUpload('ActVel');
ActVel = cell2mat(ActVel);
ActVel = (ActVel / ticksPerRev / 64) * (1000 / TM); % since multiplied by 64 for some reason in RD command

% Trimming
TimeArr = TimeArr(1:I);
Current = Current(1:I);
DesPos = DesPos(1:I);
ActPos = ActPos(1:I);
ActVel = ActVel(1:I);

fc = 100;
fs = round(1 / dt);
[b,a] = butter(6,fc/(fs/2));
filtered_vel = filtfilt(b,a,ActVel);
accel = abs(gradient(filtered_vel, dt));

figure
hold on
yyaxis left
plot(TimeArr, Current, DisplayName="TT")
ylabel("Current (mA)")
% ylim([0 0.05])
yyaxis right
plot(TimeArr, ActVel, DisplayName="TV")
ylabel("Revolutions per second")

xlabel("Time (s)")
legend(Location="best")
set(findall(gca, 'Type', 'Line'), 'LineWidth', 2);
set(gca, FontSize=14);

figure
hold on
plot(TimeArr, DesPos, DisplayName="Desired Position")
plot(TimeArr, ActPos, DisplayName="Actual Position")
xlabel("Time (s)")
ylabel("Revolutions")
legend(Location="best")
set(findall(gca, 'Type', 'Line'), 'LineWidth', 2);
set(gca, FontSize=14);

figure
hold on
plot(TimeArr, filtered_vel, DisplayName="Filtered Speed")
plot(TimeArr, accel, DisplayName="Acceleration")
legend()

% max_vel = max(filtered_vel);

tol = 0.1;
filtered_velTrimmed = filtered_vel(accel < 0.05);
timeTrimmed = TimeArr(accel < 0.05);

figure
hold on
scatter(timeTrimmed, filtered_velTrimmed, DisplayName="Filtered Speed")
legend()

filtered_velTrimmed = filtered_velTrimmed(filtered_velTrimmed > 1);
timeTrimmed = timeTrimmed(filtered_velTrimmed > 1);

figure
hold on
scatter(timeTrimmed, filtered_velTrimmed, DisplayName="Filtered Speed")
legend()

startIdx = round(timeTrimmed(1) / dt);
endIdx = round(timeTrimmed(end) / dt);

figure
hold on
yyaxis left
plot(TimeArr, Current, DisplayName="TT")
ylabel("Current (mA)")
% ylim([0 0.05])
yyaxis right
plot(TimeArr, ActVel, DisplayName="TV")
ylabel("Revolutions per second")
xline(timeTrimmed(1), DisplayName="At Speed Start")
xline(timeTrimmed(end), DisplayName="At Speed End")

xlabel("Time (s)")
legend(Location="best")
set(findall(gca, 'Type', 'Line'), 'LineWidth', 2);
set(gca, FontSize=14);

try
    trimmedVel = ActVel(startIdx:endIdx);
    trimmedTime = TimeArr(startIdx:endIdx);
catch
    disp("Trial too long, couldn't find end")
    trimmedVel = ActVel(startIdx:end);
    trimmedTime = TimeArr(startIdx:end);
end

disp("Velocity is " + mean(trimmedVel) + " +/- " + std(trimmedVel) + " (1 SD)")

figure
plot(trimmedTime, trimmedVel)
xlabel("Time (s)")
ylabel("Wingbeat Frequency (Hz)")
end