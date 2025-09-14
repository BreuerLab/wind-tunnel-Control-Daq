clear
close all

d = 20; % mm
r = 7.27; % mm
numRevs = 5;
numPts = 1000;
% init_theta = atan2(3.451, 6.399);
% theta = linspace(init_theta, init_theta + numRevs*2*pi, numPts);

% init_theta only pertains to backwards case
% this wasn't working initially because phi should actually have had a
% negative sign to match CAD data
init_theta = atan(-3.451/6.399);
theta = linspace(init_theta, init_theta - numRevs*2*pi, numPts);

% init_theta = atan(3.451/6.399);
% theta = linspace(init_theta, init_theta + numRevs*2*pi, numPts);
time_eqt = linspace(0, numRevs, numPts);

data_path_F = "R:\ENG_Breuer_Shared\rgissler\Solidworks\Calimero\Data\wing_angle_data_1Hz.csv";
data_path_R = "R:\ENG_Breuer_Shared\rgissler\Solidworks\Calimero\Data\wing_angle_data_1Hz_rev.csv";

phi_eqt = -atand((r*sin(theta)) ./ (d + r*cos(theta)));

data_F = readmatrix(data_path_F,"NumHeaderLines",2);
time_F = data_F(:,1);
phi_F = data_F(:,2);

data_R = readmatrix(data_path_R,"NumHeaderLines",2);
time_R = data_R(:,1);
phi_R = data_R(:,2);

figure
hold on
plot(time_F, phi_F, DisplayName="SolidWorks Forward", LineWidth=2)
plot(time_R, phi_R, DisplayName="SolidWorks Reverse", LineWidth=2)
plot(time_eqt, phi_eqt, DisplayName="Equation", LineWidth=2)
xlim([0 1])
legend()

dt = time_eqt(2) - time_eqt(1);
time_eqt_trimmed = time_eqt(time_eqt <= 1);

sine_data = max(phi_eqt)*sin(2*pi*time_eqt);
sine_data_trimmed = sine_data(time_eqt <= 1);
sine_dot_data = gradient(sine_data_trimmed, dt);

init_theta = 0;
theta_F = linspace(init_theta, init_theta + numRevs*2*pi, numPts);
phi_eqt_F = atand((r*sin(theta_F)) ./ (d + r*cos(theta_F)));
phi_eqt_F_trimmed = phi_eqt_F(time_eqt <= 1);
phi_eqt_F_dot = gradient(phi_eqt_F_trimmed, dt);
zc_idx_F = find(phi_eqt_F_dot(1:end-1) .* phi_eqt_F_dot(2:end) < 0);
% zc_dir_F = sign(phi_eqt_F_dot(zc_idx_F+1) - phi_eqt_F_dot(zc_idx_F));
downstroke_count_F = zc_idx_F(2) - zc_idx_F(1);
D_U_ratio_F = downstroke_count_F / (length(phi_eqt_F_dot) - downstroke_count_F);

init_theta = pi;
theta_R = linspace(init_theta, init_theta - numRevs*2*pi, numPts);
phi_eqt_R = atand((r*sin(theta_R)) ./ (d + r*cos(theta_R)));
phi_eqt_R_trimmed = phi_eqt_R(time_eqt <= 1);
phi_eqt_R_dot = gradient(phi_eqt_R_trimmed, dt);
zc_idx_R = find(phi_eqt_R_dot(1:end-1) .* phi_eqt_R_dot(2:end) < 0);
% zc_dir_R = sign(phi_eqt_R_dot(zc_idx_R+1) - phi_eqt_R_dot(zc_idx_R));
downstroke_count_R = zc_idx_R(2) - zc_idx_R(1);
D_U_ratio_R = downstroke_count_R / (length(phi_eqt_R_dot) - downstroke_count_R);

figure
hold on
plot(time_eqt, phi_eqt_F, DisplayName="Actual - Forward", LineWidth=2)
plot(time_eqt, phi_eqt_R, DisplayName="Actual - Reverse", LineWidth=2)
plot(time_eqt, sine_data, DisplayName="Sinusoidal", LineWidth=2)
xlabel("Time (sec)")
ylabel("Wing Angle (deg)")
xlim([0 1])
legend()

figure
hold on
plot(time_eqt_trimmed, phi_eqt_F_dot, DisplayName="Actual - Forward", LineWidth=2)
plot(time_eqt_trimmed, phi_eqt_R_dot, DisplayName="Actual - Reverse", LineWidth=2)
plot(time_eqt_trimmed, sine_dot_data, DisplayName="Sinusoidal", LineWidth=2)
xlabel("Time (sec)")
ylabel("Wing Angular Speed (deg/sec)")
legend()

% expr1 = (r*cot(sine_data)) / (d - r);
% expr2 = (cot(sine_data).*sqrt(r^2 + (r^2 - d^2)*(tan(sine_data)).^2)) / (d - r);
% new_theta = 2*atan(expr1 + expr2);
% phi_eqt_mod = atand((r*sin(new_theta)) ./ (d + r*cos(new_theta)));
% 
% figure
% hold on
% plot(time_eqt, phi_eqt_mod, DisplayName="Actual", LineWidth=2)
% plot(time_eqt, sine_data, DisplayName="Sinusoidal", LineWidth=2)
% legend()

% phi_target = sine_data;
% theta_new = zeros(size(phi_target));
% 
% for k = 1:numPts
%     f = @(th) atand((r*sin(th))/(d + r*cos(th))) - phi_target(k);
%     theta_new(k) = fzero(f, (k-1)/numPts * numRevs*2*pi);  % initial guess
% end
% 
% theta_fix = unwrap(theta_new);
% theta_smooth = smoothdata(theta_fix, 'sgolay', 31);  % or csaps with p≈0.99
% % phi_err   = phi_of(theta_fit) - phi_target;

% ChatGPT solution 2

% % Use radians + atan2 for continuity
% theta_lin = linspace(0, numRevs*2*pi, numPts);  % only for initial guesses if needed
% phi_of    = @(th) atan2(r*sin(th), d + r*cos(th));  % radians
% 
% % Pick a sinusoidal target that is reachable:
% % When r <= d, |phi| <= asin(r/d). Stay inside that.
% Amax = asin(min(1, r/d));             % reachable half-amplitude (rad) for r<=d
% A    = 0.9*Amax;                       % choose something safely inside
% phi_target = A * sin(linspace(0, numRevs*2*pi, numPts));
% 
% % --- continuation-based inversion φ(θ)=φ_target ---
% theta = zeros(size(phi_target));
% theta(1) = 0;                          % seed
% for k = 2:numPts
%     % Root for current k, bracket around previous θ to avoid distant roots.
%     f = @(th) phi_of(th) - phi_target(k);
%     % Bracket ±pi around the previous solution; this strongly discourages jumps.
%     bracket = theta(k-1) + [-pi, pi];
%     % fzero needs the function to change sign in the bracket in general;
%     % If it doesn’t, fall back to a single-point initial guess.
%     try
%         if sign(f(bracket(1))) ~= sign(f(bracket(2)))
%             theta(k) = fzero(f, bracket);
%         else
%             theta(k) = fzero(f, theta(k-1));  % fallback: continuation start
%         end
%     catch
%         % If a rare failure happens (e.g., target slightly out of range),
%         % keep continuity by reusing previous θ.
%         theta(k) = theta(k-1);
%     end
% end
% 
% % Unwrap to enforce continuity over many revolutions
% theta = unwrap(theta);
% 
% % --- (Optional) gentle smoothing of θ over sample index ---
% % Only if you *really* need to smooth; keep it light to preserve φ(θ).
% theta_smooth = smoothdata(theta, 'sgolay', 31);    % tweak window as needed
% % Or a smoothing spline:
% % pp = csaps(1:numPts, theta, 0.99); theta_smooth = fnval(pp, 1:numPts);



% ChatGPT solution 3
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

