clear
close all

% Parameters
x = linspace(0, 4*pi, 1000);  % x-axis values
y_line = 1.0;                 % Height of horizontal line
offset = y_line - 0.2;        % Center of the sine waves (just below the line)

% Sine waves
y1 = 0.4 * sin(x) + offset;   % Larger amplitude, goes above line
y2 = 0.1 * sin(x) + offset;   % Smaller amplitude, stays below line

% Plot
figure;
hold on;
plot(x, y1, 'b-', 'LineWidth', 2);               % First sine wave (crosses line)
plot(x, y2, 'r-', 'LineWidth', 2);               % Second sine wave (doesn't cross)
yline(y_line, 'k--', 'LineWidth', 2);            % Horizontal dashed line
hold off;

% Formatting
xlabel('Time');
ylabel('Motor Torque');
legend('Flapping Mechanism - no spring', 'Flapping Mechanism - with spring', 'Motor Stall Torque', 'Location', 'northoutside');
axis tight;
set(gca, 'XTickLabel', [], 'YTickLabel', []);
set(gca, FontSize=16)