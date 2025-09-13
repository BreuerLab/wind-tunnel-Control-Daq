% % --- parameters ---
% numRevs  = 3;
% numPts   = 2000;
% r        = 1.2;
% d        = 2.0;
% 
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
% 
% % Validate: make sure φ(θ_smooth) still matches the target
% phi_back  = phi_of(theta);
% phi_back2 = phi_of(theta_smooth);
% 
% fprintf('RMS error (unsmoothed): %g rad\n', rms(phi_back - phi_target));
% fprintf('RMS error (smoothed)  : %g rad\n', rms(phi_back2 - phi_target));
% 
% figure
% plot(theta_smooth)














% % --- Parameters ---
% numRevs  = 3;
% numPts   = 2000;
% r        = 1.2;
% d        = 2.0;
% 
% % Define forward mapping: φ(θ)
% phi_of = @(th) atan2(r*sin(th), d + r*cos(th));  % radians
% 
% % --- Step 1. Target sinusoid within reachable amplitude ---
% Amax = asin(min(1, r/d));      % max |φ| in radians
% A    = 0.9*Amax;               % pick safe amplitude
% phi_target = A * sin(linspace(0, numRevs*2*pi, numPts));
% 
% % --- Step 2. Invert numerically with continuation ---
% theta = zeros(size(phi_target));
% theta(1) = 0;  % seed
% for k = 2:numPts
%     f = @(th) phi_of(th) - phi_target(k);
%     theta(k) = fzero(f, theta(k-1));  % continuation: start near last θ
% end
% 
% % --- Step 3. Unwrap to enforce continuous increase across 2π ---
% theta_unw = unwrap(theta);
% 
% % --- Step 4. Fit a monotone spline (pchip preserves monotonic trends) ---
% idx = 1:numPts;
% theta_fit = pchip(idx, theta_unw, idx);
% 
% % --- Step 5. Enforce strict monotonicity (no decreases allowed) ---
% theta_monotone = cummax(theta_fit);
% 
% % --- Diagnostics ---
% phi_back = phi_of(theta_monotone);
% fprintf('RMS error vs target: %g rad\n', rms(phi_back - phi_target));
% 
% % --- Plot for verification ---
% figure;
% subplot(2,1,1);
% plot(idx, phi_target, 'k--', 'LineWidth',1.2); hold on;
% plot(idx, phi_back, 'r', 'LineWidth',1.2);
% legend('Target \phi','Backcomputed \phi(\theta)');
% ylabel('\phi (rad)');
% title('Check inversion');
% 
% subplot(2,1,2);
% plot(idx, theta_unw, 'b--'); hold on;
% plot(idx, theta_monotone, 'r','LineWidth',1.2);
% legend('Raw \theta','Monotone \theta');
% ylabel('\theta (rad)'); xlabel('Sample index');
% title('Theta should always increase');







% % Inputs (example)
% numRevs = 3;
% numPts  = 2000;
% r = 1.2;
% d = 2.0;
% 
% % target phi (must satisfy domain)
% phi_target = 0.9 * asin(min(1,r/d)) * sin(linspace(0,numRevs*2*pi,numPts));  % radians
% 
% % check domain
% arg = (d .* sin(phi_target)) ./ r;
% if any(abs(arg) > 1)
%     error('phi_target outside reachable domain: |d*sin(phi)/r| must <= 1');
% end
% 
% % principal phi (safe principal angle) - use atan2 to get a principal angle equal to phi modulo 2pi
% phi_princ = atan2(sin(phi_target), cos(phi_target));  % equal to phi_target wrapped to (-pi,pi]
% 
% % compute the two algebraic branches (principal values)
% theta_branch1 = phi_princ + asin(arg);              % θ1 = atan(tanφ) + asin(d sinφ / r)
% theta_branch2 = phi_princ + (pi - asin(arg));       % θ2 = atan(tanφ) + π - asin(...)
% 
% % Build continuous θ by choosing at each step the branch+2π that stays closest to the previous θ
% theta = zeros(size(phi_target));
% % initialize (pick the branch closest to 0)
% c1 = theta_branch1(1);
% c2 = theta_branch2(1);
% if abs(c1) <= abs(c2)
%     theta(1) = c1;
% else
%     theta(1) = c2;
% end
% 
% for k = 2:numPts
%     % for each branch, shift by integer multiples of 2π to bring near previous value
%     prev = theta(k-1);
%     % candidate from branch1 adjusted by an integer multiple of 2pi
%     cand1 = theta_branch1(k) - round((theta_branch1(k)-prev)/(2*pi))*2*pi;
%     cand2 = theta_branch2(k) - round((theta_branch2(k)-prev)/(2*pi))*2*pi;
%     % choose the candidate closest to prev (continuation)
%     if abs(cand1 - prev) <= abs(cand2 - prev)
%         theta(k) = cand1;
%     else
%         theta(k) = cand2;
%     end
% end
% 
% % enforce strict monotonic increase: whenever a sample would be <= previous,
% % add multiples of 2π until it is strictly greater.
% for k = 2:numPts
%     if theta(k) <= theta(k-1)
%         theta(k) = theta(k) + ceil((theta(k-1)-theta(k)+1e-12)/(2*pi))*2*pi;
%     end
% end
% 
% % Optional: tiny smoothing on theta derivative if absolutely needed,
% % but after this theta will be strictly increasing.
% % theta = smoothdata(theta,'sgolay',31);  % use with caution (may violate monotonicity)
% theta = unwrap(theta);  % make continuous (not strictly required after the loop)
% 
% % Validate
% phi_back = atan2(r*sin(theta), d + r*cos(theta));  % should match phi_target (mod 2pi)
% rms_err = rms( wrapToPi(phi_back - phi_target) );
% fprintf('RMS φ error: %g rad\n', rms_err);
% 
% % quick plots
% figure;
% subplot(2,1,1);
% plot(phi_target,'k--'); hold on; plot(phi_back,'r'); legend('phi_{target}','phi_{back}');
% ylabel('\phi (rad)');
% subplot(2,1,2);
% plot(theta); ylabel('\theta (rad)'); xlabel('sample index');
% title('Computed monotonic \theta');








% Robust monotonic analytic inversion of phi->theta
clearvars; close all;

% --- Example parameters (change as needed) ---
% numRevs = 3;
% numPts  = 2000;
% r = 1.2;
% d = 2.0;

d = 20; % mm
r = 7.27; % mm
numRevs = 5;
numPts = 1000;

% --- Target phi (radians) - keep inside reachable amplitude ---
Amax = asin(min(1, r/d));
% A = 0.9 * Amax;
A = Amax;
tgrid = linspace(0, numRevs*2*pi, numPts);
phi_target = A * sin(tgrid);

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

% Theta is now strictly increasing. Quick check:
if any(diff(theta) <= 0)
    warning('theta not strictly increasing (unexpected).');
else
    disp('theta is strictly increasing.');
end

% --- Validate by computing phi from theta and reporting RMS error ---
phi_back = atan2( r.*sin(theta), d + r.*cos(theta) );
% compute wrapped error (principal difference)
phi_err = atan2( sin(phi_back - phi_target), cos(phi_back - phi_target) );
rms_err = sqrt(mean(phi_err.^2));
fprintf('RMS φ error after analytic inversion: %g rad\n', rms_err);

% --- Optional: smooth the increments (monotone smoothing) ---
smooth_window = 31;  % odd integer, adjust to taste
dtheta = diff(theta);
dtheta_smooth = movmean(dtheta, smooth_window);   % movmean keeps positive values nearer original
% ensure positivity after smoothing (set floor to small positive number)
dtheta_smooth = max(dtheta_smooth, 1e-9);
theta_smooth = [theta(1), theta(1) + cumsum(dtheta_smooth)];

% Evaluate smoothed phi and error
phi_back_smooth = atan2( r.*sin(theta_smooth), d + r.*cos(theta_smooth) );
phi_err_smooth = atan2(sin(phi_back_smooth - phi_target), cos(phi_back_smooth - phi_target));
rms_err_smooth = sqrt(mean(phi_err_smooth.^2));
fprintf('RMS φ error after smoothing increments: %g rad\n', rms_err_smooth);

% --- Plots ---
figure('Units','normalized','Position',[.1 .1 .7 .6]);
subplot(3,1,1);
plot(tgrid, phi_target, 'k--','LineWidth',1.2); hold on;
plot(tgrid, phi_back, 'r','LineWidth',1.0);
plot(tgrid, phi_back_smooth, 'b','LineWidth',1.0);
legend('phi_{target}','phi_{back}','phi_{back\_smoothed}');
ylabel('\phi (rad)'); title('Target vs backcomputed \phi');

subplot(3,1,2);
plot(theta,'r'); hold on;
plot(theta_smooth,'b');
ylabel('\theta (rad)'); legend('theta (raw)','theta (smoothed increments)');
title('Monotonic \theta (increasing)');

subplot(3,1,3);
plot(diff(theta),'r'); hold on;
plot(dtheta_smooth,'b');
ylabel('\Delta\theta (rad)'); xlabel('index');
legend('raw \Delta\theta','smoothed \Delta\theta');
title('Increments (always > 0 after smoothing-floor)');
