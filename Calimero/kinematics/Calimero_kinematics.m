clear
close all

d = 20; % mm
% r = 7.27; % mm
% r = 3.47; % 10 deg
r = 6.84; % 20 deg
% r = 10; % 30 deg
% r = 8.45; % 25 deg
numRevs = 1; % NEEDS TO BE 1, otherwise stuff gets funky
numPts = 1000;
% numPts = 48;

CAD_verification(r, d, numRevs, numPts);

theta = linspace(0, numRevs*2*pi, numPts);
phi_eqt = -atand((r*sin(theta)) ./ (d + r*cos(theta)));
disp("Amplitude is " + max(phi_eqt) + " deg")

dt = numRevs/numPts;
time_eqt = linspace(0, numRevs, numPts);

sine_data = max(phi_eqt)*sin(2*pi*time_eqt);
sine_dot_data = gradient(sine_data, dt);

% --------------------------------------------------------
% Wing kinematics for forward motor rotation
% --------------------------------------------------------
init_theta = 0;
theta_F = linspace(init_theta, init_theta + numRevs*2*pi, numPts);
phi_eqt_F = atand((r*sin(theta_F)) ./ (d + r*cos(theta_F)));
phi_eqt_F_dot = gradient(phi_eqt_F, dt);
zc_idx_F = find(phi_eqt_F_dot(1:end-1) .* phi_eqt_F_dot(2:end) < 0);
% zc_dir_F = sign(phi_eqt_F_dot(zc_idx_F+1) - phi_eqt_F_dot(zc_idx_F));
downstroke_count_F = zc_idx_F(2) - zc_idx_F(1);
D_U_ratio_F = downstroke_count_F / (length(phi_eqt_F_dot) - downstroke_count_F);
tau_ratio_F = downstroke_count_F / length(phi_eqt_F_dot);
disp("Downstroke-upstroke ratio moving forward is: " + D_U_ratio_F)
disp("Downstroke moving forward is " + round(tau_ratio_F*100) + "% of wingbeat")

% --------------------------------------------------------
% Wing kinematics for backward motor rotation
% --------------------------------------------------------
init_theta = pi;
theta_R = linspace(init_theta, init_theta - numRevs*2*pi, numPts);
phi_eqt_R = atand((r*sin(theta_R)) ./ (d + r*cos(theta_R)));
phi_eqt_R_dot = gradient(phi_eqt_R, dt);
zc_idx_R = find(phi_eqt_R_dot(1:end-1) .* phi_eqt_R_dot(2:end) < 0);
% zc_dir_R = sign(phi_eqt_R_dot(zc_idx_R+1) - phi_eqt_R_dot(zc_idx_R));
downstroke_count_R = zc_idx_R(2) - zc_idx_R(1);
D_U_ratio_R = downstroke_count_R / (length(phi_eqt_R_dot) - downstroke_count_R);
tau_ratio_R = downstroke_count_R / length(phi_eqt_R_dot);
disp("Downstroke-upstroke ratio moving backward is: " + D_U_ratio_R)
disp("Downstroke moving backward is " + round(tau_ratio_R*100) + "% of wingbeat")

% --------------------------------------------------------
% Plotting angular displacement of sinusoidal motion compared with forward
% and backward motion of mechanism based on equation
% --------------------------------------------------------
figure
hold on
plot(time_eqt, phi_eqt_F, DisplayName="Actual - Forward", LineWidth=2)
plot(time_eqt, phi_eqt_R, DisplayName="Actual - Reverse", LineWidth=2)
plot(time_eqt, sine_data, DisplayName="Sinusoidal", LineWidth=2)
xlabel("Time (sec)")
ylabel("Wing Angle (deg)")
xlim([0 1])
legend()

% --------------------------------------------------------
% Plotting angular velocity of sinusoidal motion compared with forward
% and backward motion of mechanism based on equation
% --------------------------------------------------------
figure
hold on
plot(time_eqt, phi_eqt_F_dot, DisplayName="Actual - Forward", LineWidth=2)
plot(time_eqt, phi_eqt_R_dot, DisplayName="Actual - Reverse", LineWidth=2)
plot(time_eqt, sine_dot_data, DisplayName="Sinusoidal", LineWidth=2)
xlabel("Time (sec)")
ylabel("Wing Angular Speed (deg/sec)")
legend()

%%
% --------------------------------------------------------
% Chat GPT gave me a numerical solution for finding what motor motion
% is required to achieve sinusoidal oscillation of the wings.
% --------------------------------------------------------

% desired sinusoidal kinematics
phi_target = deg2rad(sine_data);

% --- domain check ---
arg = (d .* sin(phi_target)) ./ r;
if any(abs(arg) > 1)
    error('phi_target outside reachable domain: |d*sin(phi)/r| must <= 1');
end

% --- principal phi (wrapped safely) and analytic base branches ---
phi_princ = atan2(sin(phi_target), cos(phi_target));  % principal angle equal to phi modulo 2pi
b1 = phi_princ + asin(arg);                % branch 1 (principal arcsin)
b2 = phi_princ + (pi - asin(arg));         % branch 2

% --- Build strictly increasing theta by choosing smallest candidate > previous ---
theta = zeros(1, numPts);
% initialize theta(1) to the smaller of the two base values (no shift)
theta(1) = min(b1(1), b2(1));

for k = 2:numPts
    prev = theta(k-1);
    % compute minimum integer shifts to make each base > prev
    % add a tiny eps to guard against floating equality
    n1 = ceil((prev - b1(k) + 1e-12) / (2*pi));
    cand1 = b1(k) + n1 * 2*pi;
    n2 = ceil((prev - b2(k) + 1e-12) / (2*pi));
    cand2 = b2(k) + n2 * 2*pi;
    % choose the smaller forward candidate (minimal forward step)
    if cand1 <= cand2
        theta(k) = cand1;
    else
        theta(k) = cand2;
    end
end

% --- Optional: smooth the increments (monotone smoothing) ---
smooth_window = 31;  % odd integer, adjust to taste
dtheta = diff(theta);
dtheta_smooth = movmean(dtheta, smooth_window);   % movmean keeps positive values nearer original
% ensure positivity after smoothing (set floor to small positive number)
dtheta_smooth = max(dtheta_smooth, 1e-9);
theta_smooth = [theta(1), theta(1) + cumsum(dtheta_smooth)];

phi_eqt_mod = atand((r*sin(theta_smooth)) ./ (d + r*cos(theta_smooth)));

figure
hold on
plot(time_eqt, theta_F, DisplayName="Constant Speed", LineWidth=2)
plot(time_eqt, theta_smooth, DisplayName="Speed Required for Sinusoidal Oscillation", LineWidth=2)
% ylim([-10 40])
xlabel("Time (sec)")
ylabel("Motor Angle (rad)")
legend()

dt = numRevs / numPts;

figure
hold on
plot(time_eqt, gradient(theta_F, dt), DisplayName="Constant Speed", LineWidth=2)
plot(time_eqt, gradient(theta_smooth, dt), DisplayName="Speed Required for Sinusoidal Oscillation", LineWidth=2)
% ylim([-10 40])
xlabel("Time (sec)")
ylabel("Motor Angular Speed (rad/s)")
legend()


figure
hold on
plot(time_eqt, phi_eqt_mod, DisplayName="Actual", LineWidth=2)
plot(time_eqt, sine_data, DisplayName="Sinusoidal", LineWidth=2)
legend()

%%
% --------------------------------------------------------
% Plotting the wingbeat amplitude and downstroke-upstroke ratio
% for a number of different values of d and r.
% --------------------------------------------------------
clear

d_vals = linspace(16,24,3);
% d = 20; % mm
r_vals = linspace(0.1,12,100); % mm
% r = 7.27; % mm

numPts = 10000;

theta = linspace(0, 2*pi, numPts);

time_eqt = linspace(0, 1, numPts);

amp_up_vals = zeros(length(d_vals), length(r_vals));
amp_down_vals = zeros(length(d_vals), length(r_vals));
D_U_ratio_vals = zeros(length(d_vals), length(r_vals));

for j = 1:length(d_vals)
    d = d_vals(j);
for i = 1:length(r_vals)
    r = r_vals(i);
    phi_eqt = -atand((r*sin(theta)) ./ (d + r*cos(theta)));
    amp_up_vals(j, i) = max(phi_eqt);
    amp_down_vals(j, i) = min(phi_eqt);
    
    dt = 1 / numPts;
    phi_eqt_dot = gradient(phi_eqt, dt);
    zc_idx = find(phi_eqt_dot(1:end-1) .* phi_eqt_dot(2:end) < 0);
    downstroke_count = zc_idx(2) - zc_idx(1);
    D_U_ratio_vals(j, i) = downstroke_count / (length(phi_eqt_dot) - downstroke_count);
end
end

figure
hold on

for j = 1:length(d_vals)
yyaxis left
plot(r_vals, amp_up_vals(j,:), LineWidth=2, DisplayName="d = " + d_vals(j) + " mm");
ylabel("Amplitude (deg)")

yyaxis right
plot(r_vals, D_U_ratio_vals(j,:), LineWidth=2, DisplayName="d = " + d_vals(j) + " mm");
end
xline(3, "k-", LineWidth=2, DisplayName="Lower Limit")
xline(10.5, "k-", LineWidth=2, DisplayName="Upper Limit")

ylabel("Downstroke-Upstroke Ratio")
xlabel("Radial position of crank (mm)")
legend(Location="best")
set(gca, FontSize=14)

% --------------------------------------------------------
% Wing kinematics for backward motor rotation
% --------------------------------------------------------
numRevs = 1; % NEEDS TO BE 1, otherwise stuff gets funky
numPts = 1000;
time_eqt = linspace(0, numRevs, numPts);

colors = ["#fdd49e", "#fc8d59", "#b30000"];

d = 20; % mm

r_vals = [3.47, 6.84, 10];
amps = [20, 40, 60];

% phi_eqt = atand((r*sin(theta_R)) ./ (d + r*cos(theta_R)));
sine_data = cos(2*pi*time_eqt);

figure
hold on
plot(time_eqt, sine_data, DisplayName="cosine", LineWidth=2, color='k')

for i = 1:length(r_vals)
    r = r_vals(i);

    init_theta = acos(-r/d);
    init_theta = pi;
    theta_R = linspace(init_theta, init_theta - numRevs*2*pi, numPts);
    phi_eqt_R = atand((r*sin(theta_R)) ./ (d + r*cos(theta_R)));
    phi_eqt_R = phi_eqt_R / max(phi_eqt_R);

    % Calculate downstroke-upstroke ratio
    phi_eqt_R_dot = gradient(phi_eqt_R, dt);
    zc_idx_R = find(phi_eqt_R_dot(1:end-1) .* phi_eqt_R_dot(2:end) < 0);
    D_U_ratio_R = zc_idx_R / (length(phi_eqt_R_dot) - zc_idx_R);
    disp("r = " + r + ", downstroke-upstroke ratio = " + D_U_ratio_R)

    plot(time_eqt, phi_eqt_R, DisplayName="\phi = " + amps(i), LineWidth=2, color=colors(i))
end
ylim([-1 1])
xlabel("t/T", FontSize=16)
ylabel("\phi / max(\phi)", FontSize=16)
legend(Location="southwest", FontSize=16)