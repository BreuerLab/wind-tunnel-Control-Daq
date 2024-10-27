clear
close all

% manual processing of oscillations in signal
% for 2 Hz, 3 Hz, 4 Hz, and 5 Hz at 4 m/s 0 deg wings with body
data = load("test.mat");
data = data.curves;

% Reproduce old curve
f = figure;
f.Position = [200, 200, 1200, 800];
hold on
for i = 2:5
    struct_name = "v" + i + "Hz";
    x = data.(struct_name)(1,:);
    y = data.(struct_name)(2,:);
    line = plot(x, y);
    line.LineWidth = 2;
    [pks,locs,w,p] = findpeaks(y);
    s = scatter(x(locs), pks, 100, 'black', 'filled');

    zeta_vals = [];
    T_d_vals = [];
    T_vals = [];
    for j = 2:length(pks)
        d = log(pks(j-1) / pks(j));
        T_d = x(locs(j)) - x(locs(j-1));

        % Correcting for damping
        zeta = d / sqrt(4*pi^2 + d^2);
        T = T_d/sqrt(1 - zeta^2);

        zeta_vals = [zeta_vals, zeta];
        T_d_vals = [T_d_vals, T_d];
        T_vals = [T_vals, T];
    end

    % Imaginary values occur when the damping ratio is calculated
    % between a positive peak and negative peak
    disp(struct_name)
    % disp("Zeta values: ")
    % disp(zeta_vals)
    disp("Damped Natural Frequency values: ")
    disp(1 ./ T_d_vals)
    % disp("Natural Frequency values: ")
    % disp(1 ./ T_vals)
    disp(" ")
end
hold off
xlabel("Time (s)")
ylabel("Force (N)")

% Typical mathematical expression for response to impulse:
% an exponentially decreasing sinusoidal wave
omega_n = 24*2*pi;
omega_d = 24*2*pi;
zeta = 0.08;

m = 1;
t = 0:0.001:0.2;
resp = (1 / (m*omega_d)) * exp(-zeta*omega_n*t) .* sin(omega_d*t);
figure
plot(t, resp, LineWidth=2)
xlabel("Time")
ylabel("Force")
set(gca,'XTick',[], 'YTick', [])