% particle_field_single_pair.m
% Velocity and vorticity on a regular in-plane grid from the particles of
% ONE STB image pair, using particleGradientFit (local weighted least
% squares: linear in-plane, cubic through the slab depth).
%
% Start with the fixed anisotropic kernel (uniform, known resolution).
% Set opts.kNN = 20 to compare with the adaptive k-nearest-neighbour kernel.

clear
cd(fileparts(mfilename('fullpath')));
addpath(genpath('../'))

%% ---- settings ---------------------------------------------------------
setPath = "F:\VC7 Data\September\x2\x2_wings_20deg_8Hz\ShakeTheBox 2-pulse.set";
block   = 1;

opts = struct();
opts.depthAxis    = 1;     % slab normal in the analysis frame (x = -z_DaVis, see loadSTBParticles)
opts.depthOrder   = 3;     % 1 = DaVis-like linear; 3 = removes most depth-gradient bias
opts.inPlaneSigma = 1.5;   % mm, Gaussian in-plane kernel width
opts.gridSpacing  = 1;     % mm
opts.minParticles = 20;
opts.kNN          = 0;     % e.g. 20 for adaptive kernel

%% ---- load & fit -------------------------------------------------------
P = loadSTBParticles(setPath, block);
D = P.data;
pAx = setdiff(1:3, opts.depthAxis);
area = range(D(:, pAx(1))) * range(D(:, pAx(2)));
fprintf('%d tracks, in-plane density %.2f particles/mm^2 (through the whole slab)\n', ...
        size(D, 1), size(D, 1) / area);

tic
F = particleGradientFit(D, opts);
fprintf('Fit on %d x %d grid in %.1f s (depth plane at %.2f mm)\n', ...
        size(F.A1, 1), size(F.A1, 2), toc, F.depthEval);

%% ---- plots ------------------------------------------------------------
ax = 'xyz';
lab1 = sprintf('%s (mm)', ax(pAx(1)));  lab2 = sprintf('%s (mm)', ax(pAx(2)));
Vcomp = {F.U, F.V, F.W};

figure('Name', 'Single-pair particle fit', 'Color', 'w');
tl = tiledlayout(2, 3, 'TileSpacing', 'compact');
title(tl, sprintf('Block %d, \\sigma_{in-plane} = %.1f mm, depth order %d', ...
      block, opts.inPlaneSigma, opts.depthOrder));

panel(F, Vcomp{opts.depthAxis}, sprintf('%s velocity (m/s)', ax(opts.depthAxis)), lab1, lab2, false);
panel(F, F.omega_x, '\omega_x (1/s)', lab1, lab2, true);
panel(F, F.omega_y, '\omega_y (1/s)', lab1, lab2, true);
panel(F, F.omega_z, '\omega_z (1/s)', lab1, lab2, true);
panel(F, F.N, 'Particles per node', lab1, lab2, false);
panel(F, F.resid, 'Fit residual (m/s)', lab1, lab2, false);

function panel(F, C, ttl, l1, l2, diverging)
    nexttile
    pcolor(F.A1, F.A2, C); shading flat; axis equal tight
    xlabel(l1); ylabel(l2); title(ttl); colorbar
    if diverging
        lim = prctile(abs(C(:)), 99.5);
        if isfinite(lim) && lim > 0, caxis([-lim lim]); end
        colormap(gca, redblue());
    end
end

function c = redblue(n)
    if nargin < 1, n = 256; end
    t = linspace(0, 1, n)';
    c = [min(1, 2*t), 1 - abs(2*t - 1), min(1, 2*(1 - t))];   % blue - white - red
end
