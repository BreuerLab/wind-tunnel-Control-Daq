% particle_stats_single_pair.m
% Load the particles of ONE STB image pair (one 2-pulse block) and plot
%   (1) number of particles vs out-of-plane coordinate, per pulse
%   (2) particle intensity vs out-of-plane coordinate, per pulse
%
% Out-of-plane = streamwise here (Trefftz plane), so particles move a lot
% along it between pulses (~U*dt). Each pulse's own position is therefore
% reconstructed from the midpoint and velocity returned by loadSTBParticles:
%   x1 = x_mid - u*dt/2,   x2 = x_mid + u*dt/2
% Only tracked particles (seen in both pulses) are included.

clear
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../'))

%% ---- settings ---------------------------------------------------------
setPath = "F:\VC7 Data\September\x2\x2_wings_20deg_8Hz\ShakeTheBox 2-pulse.set";
block   = 1;      % 1-based image-pair index
oop     = 1;      % out-of-plane axis: 1 = x, 2 = y, 3 = z
binW    = 0.25;   % bin width along out-of-plane axis (mm)
nScatter = 2e4;   % max points drawn per pulse in the scatter plot

%% ---- load -------------------------------------------------------------
P  = loadSTBParticles(setPath, block);
D  = P.data;                       % [x y z u v w I1 I2 trackID block]
t  = P.info.times(block, :);
dt = t(2) - t(1);                  % s

axName = 'xyz';
xMid = D(:, oop);                  % mm
uOop = D(:, oop + 3);              % m/s
half = uOop * dt/2 * 1e3;          % mm
x1 = xMid - half;   I1 = D(:, 7);
x2 = xMid + half;   I2 = D(:, 8);

fprintf('Block %d: %d tracks, dt = %.1f us\n', block, size(D,1), dt*1e6);
fprintf('Mean %s-displacement between pulses: %.2f mm (std %.2f mm)\n', ...
        axName(oop), mean(2*half), std(2*half));

%% ---- (1) particle count vs out-of-plane coordinate ---------------------
edges = floor(min([x1; x2])) : binW : ceil(max([x1; x2]));
ctrs  = edges(1:end-1) + binW/2;
n1 = histcounts(x1, edges);
n2 = histcounts(x2, edges);

[mu1, s1] = deal(mean(x1), std(x1));
[mu2, s2] = deal(mean(x2), std(x2));
g = @(x, mu, s, N) N*binW/(s*sqrt(2*pi)) * exp(-(x - mu).^2/(2*s^2));

figure('Name', 'Particle count vs out-of-plane coordinate', 'Color', 'w');
hold on
stairs(edges, [n1 n1(end)], 'LineWidth', 1.5, 'DisplayName', 'Pulse 1');
stairs(edges, [n2 n2(end)], 'LineWidth', 1.5, 'DisplayName', 'Pulse 2');
xx = linspace(edges(1), edges(end), 400);
plot(xx, g(xx, mu1, s1, numel(x1)), '--', 'Color', [0 0.447 0.741], ...
     'DisplayName', sprintf('Gaussian, \\mu=%.2f, \\sigma=%.2f mm', mu1, s1));
plot(xx, g(xx, mu2, s2, numel(x2)), '--', 'Color', [0.85 0.325 0.098], ...
     'DisplayName', sprintf('Gaussian, \\mu=%.2f, \\sigma=%.2f mm', mu2, s2));
xlabel(sprintf('%s (mm)', axName(oop)));
ylabel(sprintf('Particles per %.2f mm bin', binW));
title(sprintf('Block %d: particle distribution through the slab', block));
legend('Location', 'best'); grid on; box on

%% ---- (2) intensity vs out-of-plane coordinate --------------------------
[med1, q1a, q1b] = binnedStats(x1, I1, edges);
[med2, q2a, q2b] = binnedStats(x2, I2, edges);

figure('Name', 'Particle intensity vs out-of-plane coordinate', 'Color', 'w');
tiledlayout(1, 2, 'TileSpacing', 'compact');
plotPulse(1, x1, I1, ctrs, med1, q1a, q1b, nScatter, [0 0.447 0.741]);
plotPulse(2, x2, I2, ctrs, med2, q2a, q2b, nScatter, [0.85 0.325 0.098]);
linkaxes(findobj(gcf, 'Type', 'axes'), 'xy');

figure('Name', 'Median intensity profiles', 'Color', 'w');
hold on
plot(ctrs, med1, '-o', 'MarkerSize', 3, 'DisplayName', 'Pulse 1');
plot(ctrs, med2, '-o', 'MarkerSize', 3, 'DisplayName', 'Pulse 2');
xlabel(sprintf('%s (mm)', axName(oop))); ylabel('Median intensity (raw)');
title(sprintf('Block %d: median particle intensity through the slab', block));
legend('Location', 'best'); grid on; box on

%% ---- local functions ---------------------------------------------------
function [med, qlo, qhi] = binnedStats(x, I, edges)
    nb  = numel(edges) - 1;
    idx = discretize(x, edges);
    [med, qlo, qhi] = deal(nan(1, nb));
    for k = 1:nb
        v = I(idx == k);
        if numel(v) >= 10
            q = prctile(v, [25 50 75]);
            [qlo(k), med(k), qhi(k)] = deal(q(1), q(2), q(3));
        end
    end
end

function plotPulse(p, x, I, ctrs, med, qlo, qhi, nMax, col)
    nexttile; hold on
    k = randperm(numel(x), min(nMax, numel(x)));
    scatter(x(k), I(k), 2, col, 'filled', 'MarkerFaceAlpha', 0.15, ...
            'DisplayName', 'Particles');
    ok = ~isnan(med);
    fill([ctrs(ok) fliplr(ctrs(ok))], [qlo(ok) fliplr(qhi(ok))], 'k', ...
         'FaceAlpha', 0.15, 'EdgeColor', 'none', 'DisplayName', 'IQR');
    plot(ctrs(ok), med(ok), 'k-', 'LineWidth', 1.5, 'DisplayName', 'Median');
    xlabel('Out-of-plane coordinate (mm)'); ylabel('Intensity (raw)');
    title(sprintf('Pulse %d', p)); legend('Location', 'best'); grid on; box on
end
