% test_particleGradientFit.m
% Synthetic check of particleGradientFit: a spanwise Lamb-Oseen vortex
% (axis along y) cut by a thin Gaussian slab normal to x, sampled by random
% particles with velocity noise, mimicking one 2-pulse STB snapshot.
%
% Set the four "match your data" values from particle_stats_single_pair /
% particle_field_single_pair output, then compare how much of the true
% peak omega_y each setting recovers.
%
% Reference result (same model in Python, 60k particles, 4.2 /mm^2,
% sigma_beam 2.5 mm, noise 0.1 m/s, 12 mm core): peak omega_y recovered
%   depthOrder 1, sigma 1.5 mm : ~81 %   (-dw/dx term alone ~78 %)
%   depthOrder 3, sigma 1.5 mm : ~89 %   (-dw/dx term alone ~95 %)
%   depthOrder 3, kNN = 20     : ~96 %   (noisier, ~8 % scatter)

clear
rng(0)

%% ---- match your data ---------------------------------------------------
density   = 4.2;    % tracked particles per mm^2 in-plane (whole slab)
sigBeam   = 2.5;    % mm, std of particle depth distribution
noise     = 0.1;    % m/s, per-component velocity noise of a 2-pulse track
coreDiam  = 12;     % mm, diameter at peak swirl velocity
Uinf      = 4;      % m/s
vtMax     = 1;      % m/s, peak swirl velocity

%% ---- synthetic particles ----------------------------------------------
L  = 120;                                  % in-plane box (mm)
N  = round(density * L^2);
x  = sigBeam * randn(3*N, 1);  x = x(abs(x) < 2.4*sigBeam);  x = x(1:N);
y  = (rand(N,1) - 0.5) * L;
z  = (rand(N,1) - 0.5) * L;

rc    = (coreDiam/2) / 1.121;              % Lamb-Oseen radius parameter
Gam   = 2*pi * vtMax * (coreDiam/2) / (1 - exp(-1.121^2));   % m/s*mm
r2    = x.^2 + z.^2 + 1e-12;  r = sqrt(r2);
vt    = Gam ./ (2*pi*r) .* (1 - exp(-r2 / rc^2));
u     = Uinf - vt .* z ./ r + noise*randn(N,1);
v     =                     noise*randn(N,1);
w     =        vt .* x ./ r + noise*randn(N,1);
wyExact = @(xx, zz) -Gam / (pi*rc^2) * exp(-(xx.^2 + zz.^2) / rc^2) * 1e3;   % 1/s

D = [x y z u v w];

%% ---- fits ---------------------------------------------------------------
cases = {struct('depthOrder', 1, 'inPlaneSigma', 1.5), ...
         struct('depthOrder', 3, 'inPlaneSigma', 1.5), ...
         struct('depthOrder', 3, 'inPlaneSigma', 1.5, 'kNN', 20, 'gridSpacing', 2)};
names = {'linear depth, sigma 1.5', 'cubic depth, sigma 1.5', 'cubic depth, kNN 20'};

ex = wyExact(0, 0);
fprintf('Exact peak omega_y = %.0f 1/s\n', ex);
figure('Color', 'w'); hold on
zz = linspace(-20, 20, 200);
plot(zz, wyExact(0, zz), 'k-', 'LineWidth', 2, 'DisplayName', 'Exact');
for c = 1:numel(cases)
    o = cases{c};
    o.gridLimits = [-40 40 -20 20];
    if ~isfield(o, 'gridSpacing'), o.gridSpacing = 1; end
    F = particleGradientFit(D, o);
    % average along the vortex axis (y = A1) to get a clean profile in z
    prof = mean(F.omega_y, 1, 'omitnan');
    [~, j0] = min(abs(F.A2(1, :)));
    fprintf('%-26s: %.0f %% of exact peak, scatter along axis %.0f %%\n', names{c}, ...
            100 * prof(j0) / ex, 100 * std(F.omega_y(:, j0), 'omitnan') / abs(ex));
    plot(F.A2(1, :), prof, 'o-', 'MarkerSize', 3, 'DisplayName', names{c});
end
xlabel('z (mm)'); ylabel('\omega_y (1/s) at slab centre');
title('Synthetic spanwise vortex: recovered \omega_y profile');
legend('Location', 'best'); grid on; box on
