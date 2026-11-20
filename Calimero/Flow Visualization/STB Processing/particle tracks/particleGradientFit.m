function F = particleGradientFit(D, opts)
% PARTICLEGRADIENTFIT  Velocity and velocity-gradient field on a regular
% in-plane grid from scattered STB particles, by a weighted local
% least-squares fit at every grid node.
%
%   F = particleGradientFit(D)
%   F = particleGradientFit(D, opts)
%
% D : N x >=6 matrix [x y z u v w ...] (mm, m/s), e.g. P.data from
%     loadSTBParticles (positions are pulse midpoints).
%
% LOCAL MODEL (per velocity component, about the node r0 = (d0, a1, a2)):
%   u(r) = c0 + Gd*(d-d0) + G1*(a1-a1n) + G2*(a2-a2n)
%            + sum_{p=2..depthOrder} cp*(d-d0)^p
%   d = depth (out-of-plane) coordinate, a1/a2 = in-plane coordinates.
%   Linear in-plane, polynomial in depth. Because w (and u) vary with
%   odd symmetry through a vortex cut by the slab, the ODD depth terms
%   (cubic, quintic) remove the bias in the depth gradient; even terms do
%   almost nothing for it (verified on a synthetic Lamb-Oseen vortex).
%   c0 is the velocity at the node, Gd/G1/G2 the gradients there.
%
% WEIGHTS: Gaussian in-plane, sigma = opts.inPlaneSigma (or, with kNN, an
%   adaptive sigma = half the distance to the k-th in-plane neighbour).
%   Optional Gaussian depth weight, sigma = opts.depthSigma (Inf = none).
%
% MASK: by default ("auto") only nodes inside the main illuminated region
%   are fitted. The region is found per call from the particles themselves
%   (coarse occupancy -> largest connected region -> holes filled), so it
%   follows the laser sheet if it shifts during a trial, and isolated
%   islands of particles outside it are skipped. Nodes whose fit residual
%   exceeds opts.maxResid are also set to NaN.
%
% OPTIONS (defaults):
%   depthAxis      1      out-of-plane axis (1=x, 2=y, 3=z)
%   depthEval      []     depth at which to evaluate (mm); [] = median depth
%   depthOrder     3      polynomial order in depth (1 to 7). 3 suits vortices
%                         larger than ~10 mm along the slab normal; thinner
%                         structures need 5 or 7 (integrated omega_y on a
%                         synthetic Lamb-Oseen vortex, sigma_beam 2.5 mm, 16
%                         pooled pairs, extent along the slab normal):
%                           12 mm: order 1 86%, 3 98%, 5 100%
%                            8 mm: order 1 75%, 3 93%, 5 99%
%                            6 mm: order 3 86%, 5 95%, 7 100%
%                            4 mm: order 3 70%, 5 85%, 7 94%
%                            3 mm: order 3 57%, 5 73%, 7 85%
%                         High orders lean on the sparse particles at the
%                         slab edges: check them against a frozen-flow
%                         estimate (overshoot = overfitting) and keep
%                         robustPasses on.
%   depthSigma     Inf    Gaussian depth weight sigma (mm)
%   inPlaneSigma   1.5    Gaussian in-plane weight sigma (mm)
%   cutoff         3      neighbourhood radius in units of the in-plane sigma
%   kNN            0      0 = fixed kernel; k>0 = adaptive kernel with k neighbours
%   gridSpacing    1      in-plane grid spacing (mm)
%   gridLimits     []     [a1min a1max a2min a2max] (mm); [] = particle extent
%   minParticles   20     nodes with fewer particles are NaN
%   maxCond        1e4    nodes with a worse-conditioned fit are NaN
%   mask           "auto" "auto", "none", or a logical array the size of the grid
%   maskCell       5      coarse cell size for the auto mask (mm)
%   maskMinDensity []     particles/mm^2 for a coarse cell to count as lit;
%                         [] = 0.75 * minParticles / (pi*(cutoff*sigma)^2)
%   maskKeepFrac   0.1    also keep connected regions >= this fraction of the largest
%   maxResid       0.5    nodes with fit residual above this (m/s) are NaN
%   robustPasses   1      outlier-rejection refits per node (0 = plain least
%                         squares). Each pass drops particles whose residual
%                         in any component exceeds robustK robust std (MAD)
%                         and refits; one pass removes most of the effect of
%                         ghost/false tracks, a second adds little.
%   robustK        3      rejection threshold in robust standard deviations
%   parallel       false  parfor over nodes (leave false inside a parfor over blocks)
%
% OUTPUT F:
%   A1, A2        in-plane grid (ndgrid), axes F.inPlaneAxes (e.g. [2 3] = y,z)
%   depthEval     depth of the evaluation plane (mm)
%   U, V, W       velocity components along x, y, z at the nodes (m/s)
%   G             3 x 3 x n1 x n2, G(i,j,:,:) = du_i/dx_j in GLOBAL x,y,z (1/s)
%   omega_x/y/z   vorticity (1/s)
%   N             particles used per node (after rejection), sigmaUsed (mm),
%                 cond, resid (m/s, of the kept particles)
%   mask          nodes that were fitted
%   opts          options used
%
% Example:
%   P = loadSTBParticles(setPath, 1);
%   F = particleGradientFit(P.data, struct('inPlaneSigma', 1.5));
%   pcolor(F.A1, F.A2, F.omega_y); shading flat; axis equal; colorbar

    if nargin < 2, opts = struct(); end
    o = defaults(opts);

    dAx = o.depthAxis;
    pAx = setdiff(1:3, dAx);                     % in-plane axes, ascending
    X   = D(:, 1:3);
    Vel = D(:, 4:6);
    good = all(isfinite([X Vel]), 2);
    X = X(good, :);  Vel = Vel(good, :);

    if isempty(o.depthEval), o.depthEval = median(X(:, dAx)); end
    dd = X(:, dAx) - o.depthEval;                % centred depth coordinate
    p1 = X(:, pAx(1));  p2 = X(:, pAx(2));

    % ---- grid ----------------------------------------------------------
    if isempty(o.gridLimits)
        lim = [min(p1) max(p1) min(p2) max(p2)];
    else
        lim = o.gridLimits;
    end
    g1 = lim(1):o.gridSpacing:lim(2);
    g2 = lim(3):o.gridSpacing:lim(4);
    [A1, A2] = ndgrid(g1, g2);
    sz = size(A1);

    % ---- mask ----------------------------------------------------------
    if isstring(o.mask) || ischar(o.mask)
        switch lower(string(o.mask))
            case "auto", M = autoMask(p1, p2, A1, A2, o);
            case "none", M = true(sz);
            otherwise,   error('particleGradientFit:mask', 'mask must be "auto", "none" or logical.');
        end
    else
        M = logical(o.mask);
        if ~isequal(size(M), sz)
            error('particleGradientFit:mask', 'mask must be %d x %d.', sz(1), sz(2));
        end
    end
    nodes = find(M);

    % ---- spatial hash of in-plane positions (dense, no toolbox) --------
    if o.kNN > 0
        cellSz = max(o.gridSpacing, 1);          % search grows ring by ring
    else
        cellSz = o.cutoff * o.inPlaneSigma;
    end
    H.b1 = min(p1);  H.b2 = min(p2);  H.cs = cellSz;
    c1 = floor((p1 - H.b1) / cellSz) + 1;
    c2 = floor((p2 - H.b2) / cellSz) + 1;
    H.n1 = max(c1);  H.n2 = max(c2);
    lin = sub2ind([H.n1 H.n2], c1, c2);
    [lin, H.ord] = sort(lin);
    nC = H.n1 * H.n2;
    H.first = ones(nC, 1);  H.last = zeros(nC, 1);   % empty cell: last < first
    [ul, ia] = unique(lin, 'first');
    [~,  ib] = unique(lin, 'last');
    H.first(ul) = ia;  H.last(ul) = ib;

    % ---- fit masked nodes ----------------------------------------------
    nOut = 16;                                   % [U(3) Gd(3) G1(3) G2(3) N sig cond resid]
    a1n = A1(nodes);  a2n = A2(nodes);
    out = nan(numel(nodes), nOut);
    if o.parallel
        parfor q = 1:numel(nodes)
            out(q, :) = fitNode(a1n(q), a2n(q), p1, p2, dd, Vel, H, o);
        end
    else
        for q = 1:numel(nodes)
            out(q, :) = fitNode(a1n(q), a2n(q), p1, p2, dd, Vel, H, o);
        end
    end
    bad = out(:, 16) > o.maxResid;
    out(bad, 1:12) = NaN;

    allOut = nan(numel(A1), nOut);
    allOut(nodes, :) = out;
    allOut(isnan(allOut(:, 13)), 13) = 0;

    % ---- assemble outputs in global x,y,z order ------------------------
    F.A1 = A1;  F.A2 = A2;  F.inPlaneAxes = pAx;  F.depthAxis = dAx;
    F.depthEval = o.depthEval;
    F.U = reshape(allOut(:, 1), sz);  F.V = reshape(allOut(:, 2), sz);  F.W = reshape(allOut(:, 3), sz);

    G = nan(3, 3, numel(A1));                     % (m/s)/mm -> 1/s
    G(:, dAx,    :) = permute(allOut(:, 4:6),   [2 3 1]) * 1e3;
    G(:, pAx(1), :) = permute(allOut(:, 7:9),   [2 3 1]) * 1e3;
    G(:, pAx(2), :) = permute(allOut(:, 10:12), [2 3 1]) * 1e3;
    F.G = reshape(G, [3 3 sz]);

    g = @(i, j) reshape(G(i, j, :), sz);
    F.omega_x = g(3, 2) - g(2, 3);                % dw/dy - dv/dz
    F.omega_y = g(1, 3) - g(3, 1);                % du/dz - dw/dx
    F.omega_z = g(2, 1) - g(1, 2);                % dv/dx - du/dy

    F.N = reshape(allOut(:, 13), sz);  F.sigmaUsed = reshape(allOut(:, 14), sz);
    F.cond = reshape(allOut(:, 15), sz);  F.resid = reshape(allOut(:, 16), sz);
    F.mask = M;
    F.opts = o;
end

% -------------------------------------------------------------------------
function row = fitNode(a1n, a2n, p1, p2, dd, Vel, H, o)
% weighted local fit at one node; returns
% [U(1:3) Gd(1:3) G1(1:3) G2(1:3) N sigma cond resid], NaN where not fitted
    row = nan(1, 16);
    nc1 = floor((a1n - H.b1) / H.cs) + 1;
    nc2 = floor((a2n - H.b2) / H.cs) + 1;

    if o.kNN > 0
        ring = 1;  idx = [];
        while ring * H.cs <= 20 * max(o.inPlaneSigma, H.cs)
            cand = gatherCells(H, nc1, nc2, ring);
            if numel(cand) >= o.kNN
                r2 = (p1(cand) - a1n).^2 + (p2(cand) - a2n).^2;
                [r2s, so] = sort(r2);
                if sqrt(r2s(o.kNN)) <= ring * H.cs
                    idx = cand(so(1:o.kNN));
                    s   = max(sqrt(r2s(o.kNN)) / 2, eps);
                    break
                end
            end
            ring = ring + 1;
        end
        if isempty(idx), row(13) = 0; return; end
        w = ones(numel(idx), 1);
    else
        idx = gatherCells(H, nc1, nc2, 1);
        if isempty(idx), row(13) = 0; return; end
        r2  = (p1(idx) - a1n).^2 + (p2(idx) - a2n).^2;
        in  = r2 <= (o.cutoff * o.inPlaneSigma)^2;
        idx = idx(in);  r2 = r2(in);
        s   = o.inPlaneSigma;
        w   = exp(-r2 / (2 * s^2));
    end

    dz = dd(idx);
    if isfinite(o.depthSigma), w = w .* exp(-dz.^2 / (2 * o.depthSigma^2)); end
    n = numel(idx);
    row(13) = n;  row(14) = s;
    nP = 4 + max(o.depthOrder - 1, 0);
    if n < max(o.minParticles, nP + 1), return; end

    A = [ones(n, 1), dz, p1(idx) - a1n, p2(idx) - a2n];
    for pw = 2:o.depthOrder, A = [A, dz.^pw]; end %#ok<AGROW>
    Vn = Vel(idx, :);
    keep = true(n, 1);
    for pass = 0:o.robustPasses
        [C, cR] = wls(A(keep, :), Vn(keep, :), w(keep), o.maxCond);
        row(15) = cR;
        if isempty(C), return; end
        if pass == o.robustPasses, break; end
        % reject particles whose residual in any component exceeds
        % robustK robust standard deviations (MAD), then refit
        rr = Vn - A * C;
        sMad = 1.4826 * median(abs(rr(keep, :) - median(rr(keep, :), 1)), 1);
        newKeep = all(abs(rr) <= o.robustK * max(sMad, eps), 2);
        if isequal(newKeep, keep) || nnz(newKeep) < max(o.minParticles, nP + 1), break; end
        keep = newKeep;
    end
    rr = Vn(keep, :) - A(keep, :) * C;
    wk = w(keep);
    row(13) = nnz(keep);
    row(1:12) = [C(1, :), C(2, :), C(3, :), C(4, :)];
    row(16) = sqrt(sum(wk .* sum(rr.^2, 2)) / (3 * sum(wk)));
end

function [C, cR] = wls(A, V, w, maxCond)
% weighted least squares via normal equations on column-scaled A (much
% cheaper than QR for the tall systems of pooled data; scaled columns keep
% the Gram matrix well conditioned). C = [] if ill-conditioned.
    sw = sqrt(w);
    Aw = A .* sw;
    cn = sqrt(sum(Aw.^2, 1));                     % column scaling, so the
    cn(cn == 0) = 1;                              % condition number reflects
    As = Aw ./ cn;                                % geometry, not units
    M  = As' * As;
    rc = rcond(M);
    cR = 1 / sqrt(rc);                            % ~ condition number of As
    if ~(rc > 0) || cR > maxCond
        C = [];
        return
    end
    C = (M \ (As' * (V .* sw))) ./ cn';           % nP x 3
end

function idx = gatherCells(H, nc1, nc2, ring)
% particle indices in the (2*ring+1)^2 hash cells around cell (nc1, nc2)
    i1 = max(nc1 - ring, 1) : min(nc1 + ring, H.n1);
    i2 = max(nc2 - ring, 1) : min(nc2 + ring, H.n2);
    if isempty(i1) || isempty(i2), idx = zeros(0, 1); return; end
    [I1, I2] = ndgrid(i1, i2);
    k  = sub2ind([H.n1 H.n2], I1(:), I2(:));
    f  = H.first(k);  l = H.last(k);
    keep = l >= f;
    f = f(keep);  l = l(keep);
    if isempty(f), idx = zeros(0, 1); return; end
    len = l - f + 1;
    % concatenate the ranges f(i):l(i) without a loop
    starts = cumsum([1; len(1:end-1)]);
    step = ones(sum(len), 1);
    step(starts(2:end)) = f(2:end) - l(1:end-1);
    step(1) = f(1);
    idx = H.ord(cumsum(step));
end

function M = autoMask(p1, p2, A1, A2, o)
% main illuminated region from particle occupancy on a coarse grid
    cs = o.maskCell;
    e1 = floor(min(p1)) : cs : max(p1) + cs;
    e2 = floor(min(p2)) : cs : max(p2) + cs;
    Hc = histcounts2(p1, p2, e1, e2);
    if isempty(o.maskMinDensity)
        rhoMin = 0.75 * o.minParticles / (pi * (o.cutoff * o.inPlaneSigma)^2);
    else
        rhoMin = o.maskMinDensity;
    end
    lit = Hc >= rhoMin * cs^2;
    CC  = bwconncomp(lit, 8);
    if CC.NumObjects == 0, M = false(size(A1)); return; end
    nPix = cellfun(@numel, CC.PixelIdxList);
    keep = false(size(lit));
    for k = find(nPix >= o.maskKeepFrac * max(nPix))
        keep(CC.PixelIdxList{k}) = true;
    end
    keep = imfill(keep, 'holes');
    i1 = discretize(A1, e1);  i2 = discretize(A2, e2);
    M  = false(size(A1));
    ok = ~isnan(i1) & ~isnan(i2);
    M(ok) = keep(sub2ind(size(keep), i1(ok), i2(ok)));
end

function o = defaults(opts)
    d = struct('depthAxis', 1, 'depthEval', [], 'depthOrder', 3, ...
               'depthSigma', Inf, 'inPlaneSigma', 1.5, 'cutoff', 3, ...
               'kNN', 0, 'gridSpacing', 1, 'gridLimits', [], ...
               'minParticles', 20, 'maxCond', 1e4, ...
               'mask', "auto", 'maskCell', 5, 'maskMinDensity', [], ...
               'maskKeepFrac', 0.1, 'maxResid', 0.5, 'parallel', false, ...
               'robustPasses', 1, 'robustK', 3);
    o = d;
    f = fieldnames(opts);
    for i = 1:numel(f)
        if ~isfield(d, f{i}), error('particleGradientFit:opt', 'Unknown option "%s".', f{i}); end
        o.(f{i}) = opts.(f{i});
    end
    if ~ismember(o.depthOrder, 1:7), error('particleGradientFit:order', 'depthOrder must be 1 to 7.'); end
end
