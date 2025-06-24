clear
close all

% determined from min and max of array given by birds in Harvey...
I = 1e-5:1e-4:0.13;
% k = 2*10^(-3); % dM / da, for half wings was between -0.5 and -4 * 10^(-3)
% w_n = (k ./ I).^(1/2);

% dM / da as a function of COM is given by the following equation
% for a case at 4 m/s and 5 Hz
x1 = -100.1;
y1 = -0.00900086;
x2 = 249.6;
y2 = 0.00580765;
x = -100:1:200; % CoM positions
k = (y2 - y1) / (x2 - x1) * (x - x1) + y1;
k = -k';

w_n = (k ./ I).^(1/2);

% Identify elements with non-zero imaginary parts
idx = imag(w_n) ~= 0;

% Replace those elements with 0
w_n(idx) = NaN;

figure
clims = [0 1];
h = imagesc(I, x, w_n, clims);
xlabel("Pitch Inertia I_y")
ylabel("CoM Position (% chord)")
title("w_n")
set(gca, FontSize=14)
set(gca, 'YDir', 'normal');
colorbar

% Set the alpha data: 1 for real numbers, 0 for NaNs
set(h, 'AlphaData', ~isnan(w_n));

% Figure with f / w_n ratio
ratio = 5 ./ w_n;

figure
clims = [0 10];
h = imagesc(I, x, ratio, clims);
xlabel("Pitch Inertia I_y")
ylabel("CoM Position (% chord)")
title("f / w_n")
set(gca, FontSize=14)
set(gca, 'YDir', 'normal');
colorbar

% Set the alpha data: 1 for real numbers, 0 for NaNs
set(h, 'AlphaData', ~isnan(w_n));

% Isolate front at ratio of 10
[xGrid, yGrid] = meshgrid(I, x);  % standard grid

% Define a mask for values near 10
threshold = 0.02;
mask = abs(ratio - 10) < threshold;

% Extract coordinates of front
x_front = xGrid(mask);
y_front = yGrid(mask);

% Plot just those points
figure;
scatter(x_front, y_front, 10, 'r', 'filled');  % red dots for front
xlabel("Pitch Inertia I_y")
ylabel("CoM Position (% chord)")
title('Extracted Front (Values ~10)');
set(gca, FontSize=14)

% Plot just those points
figure;
plot(x_front, y_front, 'r');  % red dots for front
xlabel("Pitch Inertia I_y")
ylabel("CoM Position (% chord)")
title('Extracted Front (Values ~10)');
set(gca, FontSize=14)