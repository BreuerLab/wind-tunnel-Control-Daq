clearvars -except results

fc = 100;
fs = 10000;
[b,a] = butter(6,fc/(fs/2));
time = results(:,1);
data = results(:,2:end);
data = data';
filtered_data = zeros(size(data));
for i = 1:9
		filtered_data(i, :) = filtfilt(b,a,data(i, :));
end

% var1 = data(7,:) * 7;
% var2 = filtered_data(7,:) * 7;

var1 = data(8,:) / 2.2;
var2 = filtered_data(8,:) / 2.2;

figure
hold on
plot(time, var1)
plot(time, var2)
disp("Avg of raw data: " + mean(var1))
disp("Avg of filtered data: " + mean(var2))
