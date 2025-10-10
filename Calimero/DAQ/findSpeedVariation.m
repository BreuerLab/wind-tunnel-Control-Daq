function findSpeedVariation(TimeArr, ActVel)

dt = TimeArr(2) - TimeArr(1);
fc = 1;
fs = round(1 / dt);
[b,a] = butter(6,fc/(fs/2));
filtered_vel = filtfilt(b,a,ActVel);
accel = abs(gradient(filtered_vel, dt));

tol = 0.1;
filtered_velTrimmed = filtered_vel(accel < 0.05);
timeTrimmed = TimeArr(accel < 0.05);

figure
hold on
scatter(timeTrimmed, filtered_velTrimmed, DisplayName="Filtered Speed")
legend()

% Only include values at a speed greater than 0.5 Hz
filtered_velTrimmedG = filtered_velTrimmed(filtered_velTrimmed > 0.5);
timeTrimmedG = timeTrimmed(filtered_velTrimmed > 0.5);

figure
hold on
scatter(timeTrimmedG, filtered_velTrimmedG, DisplayName="Filtered Speed")
legend()

% Trim off lits remnants of acceleration at beginning and end with simple
% time cutoff
cutoff_time = 6/mean(filtered_velTrimmedG);
filtered_velTrimmedF = filtered_velTrimmedG(timeTrimmedG > timeTrimmedG(1) + cutoff_time &...
                                            timeTrimmedG < timeTrimmedG(end) - cutoff_time);
timeTrimmedF = timeTrimmedG(timeTrimmedG > timeTrimmedG(1) + cutoff_time &...
                            timeTrimmedG < timeTrimmedG(end) - cutoff_time);

figure
hold on
scatter(timeTrimmedF, filtered_velTrimmedF, DisplayName="Filtered Speed")
legend()

startIdx = round(timeTrimmedF(1) / dt) + 1;
endIdx = round(timeTrimmedF(end) / dt) + 1;

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