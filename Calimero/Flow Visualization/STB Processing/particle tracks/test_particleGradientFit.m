% test_particleGradientFit.m
% Synthetic check of particleGradientFit: a spanwise Lamb-Oseen vortex
% (axis along y) cut by a thin Gaussian slab normal to x, sampled by random
% particles with velocity noise, mimicking one 2-pulse STB snapshot.
%
% Set the four "match your data" values from particle_stats_single_pair /
% particle_field_single_pair output, then compare how much of the true
% peak omega_y each setting recovers.
%
% Reference results (same model in Python; sigma_beam 2.5 mm, 12 mm core,
% 0.1 m/s noise). Peak omega_y recovered / scatter along the vortex axis:
%   density 4.2 /mm^2 : order 1, sigma 1.5 mm ~81 %;  order 3 ~89 %
%   density 0.56 /mm^2 (measured, block 1 of x2_wings_20deg_8Hz):
%       order 3, sigma 1.5 mm : ~90 %, scatter ~6 %
%       order 3, sigma 2.5 mm : ~82 %, scatter ~3 %
%       order 3, sigma 3.5 mm : ~72 %, scatter ~2 %
%       order 1, sigma 1.5 mm : ~82 %, scatter ~5 %
%   Away from the vortex the omega_y noise floor (0.56 /mm^2, sigma 1.5 mm,
%   order 3) is ~4 % of peak at 0.1 m/s noise and ~13 % at 0.3 m/s.

clear
rng(0)

%% ---- match your data ---------------------------------------------------
density   = 0.56;   % tracked particles per mm^2 in-plane (whole slab), measured
sigBeam   = 2.5;    % mm, std of particle depth distribution
noise     = 0.1;    % m/s, per-component velocity noise of a 2-pulse track
coreDiam  = 12;     % mm, diameter at peak swirl velocity
Uinf      = 3.93;   % m/s (1.57 mm in 400 us)
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
