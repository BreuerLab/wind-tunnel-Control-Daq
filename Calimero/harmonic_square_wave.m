% Square wave reconstruction using Fourier series
clc; clear; close all;

% Time vector
t = linspace(0, 2*pi, 1000);  % one period from 0 to 2π

% Initialize signal
square_approx = zeros(size(t));

% Number of harmonics (use first 4 odd harmonics: n = 1,3,5,7)
num_harmonics = 4;
harmonics = 1:2:(2*num_harmonics-1);  % odd numbers

% Reconstruct the square wave
for k = 1:num_harmonics
    n = harmonics(k);
    component = (4/pi) * (1/n) * sin(n*t);  % Fourier sine component
    square_approx = square_approx + component;
    
    % Plot partial reconstruction after each harmonic
    subplot(num_harmonics,1,k);
    plot(t, square_approx, 'b', 'LineWidth', 1.5); hold on;
    plot(t, component, 'r--');  % individual harmonic
    ylim([-1.5 1.5]);
    grid on;
    title(['Approximation with first ' num2str(k) ' harmonics']);
    legend('Partial sum','Current harmonic');
end

% Compare with MATLAB's square() for reference
figure;
plot(t, square(t), 'k', 'LineWidth', 1.5); hold on;
plot(t, square_approx, 'b--', 'LineWidth', 1.5);
legend('Ideal square wave','Approximation with 4 harmonics');
title('Square Wave Reconstruction with 4 Sine Components');
grid on;