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
%   odd symmetry through a vortex cut by the slab, a CUBIC depth term is
%   what removes most of the bias in the depth gradient; a quadratic alone
%   does almost nothing for it (verified on a synthetic Lamb-Oseen vortex).
%   c0 is the velocity at the node, Gd/G1/G2 the gradients there.
%
% WEIGHTS: Gaussian in-plane, sigma = opts.inPlaneSigma (or, with kNN, an
%   adaptive sigma = half the distance to the k-th in-plane neighbour).
%   Optional Gaussian depth weight, sigma = opts.depthSigma (Inf = none).
%
% OPTIONS (defaults):
%   depthAxis     1      out-of-plane axis (1=x, 2=y, 3=z)
%   depthEval     []     depth at which to evaluate (mm); [] = median depth
%   depthOrder    3      polynomial order in depth (1, 2 or 3)
%   depthSigma    Inf    Gaussian depth weight sigma (mm)
%   inPlaneSigma  1.5    Gaussian in-plane weight sigma (mm)
%   cutoff        3      neighbourhood radius in units of the in-plane sigma
%   kNN           0      0 = fixed kernel; k>0 = adaptive kernel with k neighbours
%   gridSpacing   1      in-plane grid spacing (mm)
%   gridLimits    []     [a1min a1max a2min a2max] (mm); [] = particle extent
%   minParticles  20     nodes with fewer particles are NaN
%   maxCond       1e4    nodes with a worse-conditioned fit are NaN
%
% OUTPUT F:
%   A1, A2        in-plane grid (ndgrid), axes F.inPlaneAxes (e.g. [2 3] = y,z)
%   depthEval     depth of the evaluation plane (mm)
%   U, V, W       velocity components along x, y, z at the nodes (m/s)
%   G             3 x 3 x n1 x n2, G(i,j,:,:) = du_i/dx_j in GLOBAL x,y,z (1/s)
%   omega_x/y/z   vorticity (1/s)
%   N             particles used per node, sigmaUsed (mm), cond, resid (m/s)
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
    nNode = numel(A1);

    % ---- spatial hash of in-plane positions (no toolbox needed) --------
    if o.kNN > 0
        cellSz = max(o.gridSpacing, 1);          % search grows ring by ring
    else
        cellSz = o.cutoff * o.inPlaneSigma;
    end
    b1 = min(p1);  b2 = min(p2);                 % hash origin = particle extent
    c1 = floor((p1 - b1) / cellSz);
    c2 = floor((p2 - b2) / cellSz);
    n1c = max(c1) + 2;  c1 = c1 + 1;  c2 = c2 + 1;   % 1-based, room for -1
    key = c1 + n1c * c2;
    [key, ord] = sort(key);
    first = containers.Map('KeyType', 'double', 'ValueType', 'any');
    [uk, ia] = unique(key, 'first');
    ib = [ia(2:end) - 1; numel(key)];
    for q = 1:numel(uk), first(uk(q)) = [ia(q) ib(q)]; end

    % ---- fit every node ------------------------------------------------
    nP = 4 + max(o.depthOrder - 1, 0);            % c0, Gd, G1, G2, depth^2..
    Uo = nan(nNode, 3);  Gd = nan(nNode, 3);  G1 = nan(nNode, 3);  G2 = nan(nNode, 3);
    Nn = zeros(nNode, 1);  sig = nan(nNode, 1);  cnd = nan(nNode, 1);  res = nan(nNode, 1);

    for n = 1:nNode
        a1n = A1(n);  a2n = A2(n);
        nc1 = floor((a1n - b1) / cellSz) + 1;
        nc2 = floor((a2n - b2) / cellSz) + 1;

        if o.kNN > 0
            % grow the ring of cells until the k-th neighbour is certainly inside
            ring = 1;
            while true
                idx = gather(first, ord, n1c, nc1, nc2, ring);
                if numel(idx) >= o.kNN
                    r2 = (p1(idx) - a1n).^2 + (p2(idx) - a2n).^2;
                    [r2s, so] = sort(r2);
                    if sqrt(r2s(o.kNN)) <= ring * cellSz, break; end
                end
                ring = ring + 1;
                if ring * cellSz > 20 * max(o.inPlaneSigma, cellSz), idx = []; break; end
            end
            if isempty(idx), continue; end
            idx = idx(so(1:o.kNN));
            s   = max(sqrt(r2s(o.kNN)) / 2, eps);
            w   = ones(o.kNN, 1);
        else
            idx = gather(first, ord, n1c, nc1, nc2, 1);
            if isempty(idx), continue; end
            r2  = (p1(idx) - a1n).^2 + (p2(idx) - a2n).^2;
            in  = r2 <= (o.cutoff * o.inPlaneSigma)^2;
            idx = idx(in);  r2 = r2(in);
            s   = o.inPlaneSigma;
            w   = exp(-r2 / (2 * s^2));
        end

        dz = dd(idx);
        if isfinite(o.depthSigma), w = w .* exp(-dz.^2 / (2 * o.depthSigma^2)); end
        Nn(n) = numel(idx);  sig(n) = s;
        if Nn(n) < max(o.minParticles, nP + 1), continue; end

        A = [ones(Nn(n), 1), dz, p1(idx) - a1n, p2(idx) - a2n];
        for pw = 2:o.depthOrder, A = [A, dz.^pw]; end %#ok<AGROW>
        sw = sqrt(w);
        Aw = A .* sw;
        [Q, R] = qr(Aw, 0);
        cR = cond(R);
        cnd(n) = cR;
        if ~isfinite(cR) || cR > o.maxCond, continue; end
        C = R \ (Q' * (Vel(idx, :) .* sw));       % nP x 3
        Uo(n, :) = C(1, :);
        Gd(n, :) = C(2, :);  G1(n, :) = C(3, :);  G2(n, :) = C(4, :);
        rr = Vel(idx, :) - A * C;
        res(n) = sqrt(sum(w .* sum(rr.^2, 2)) / (3 * sum(w)));
    end

    % ---- assemble outputs in global x,y,z order ------------------------
    sz = size(A1);
    F.A1 = A1;  F.A2 = A2;  F.inPlaneAxes = pAx;  F.depthAxis = dAx;
    F.depthEval = o.depthEval;
    F.U = reshape(Uo(:, 1), sz);  F.V = reshape(Uo(:, 2), sz);  F.W = reshape(Uo(:, 3), sz);

    G = nan(3, 3, nNode);                         % (m/s)/mm -> 1/s
    G(:, dAx,    :) = permute(Gd, [2 3 1]) * 1e3;
    G(:, pAx(1), :) = permute(G1, [2 3 1]) * 1e3;
    G(:, pAx(2), :) = permute(G2, [2 3 1]) * 1e3;
    F.G = reshape(G, [3 3 sz]);

    g = @(i, j) reshape(G(i, j, :), sz);
    F.omega_x = g(3, 2) - g(2, 3);                % dw/dy - dv/dz
    F.omega_y = g(1, 3) - g(3, 1);                % du/dz - dw/dx
    F.omega_z = g(2, 1) - g(1, 2);                % dv/dx - du/dy

    F.N = reshape(Nn, sz);  F.sigmaUsed = reshape(sig, sz);
    F.cond = reshape(cnd, sz);  F.resid = reshape(res, sz);
    F.opts = o;
end

% -------------------------------------------------------------------------
function idx = gather(first, ord, n1c, nc1, nc2, ring)
% particle indices in the (2*ring+1)^2 hash cells around cell (nc1, nc2)
    idx = [];
    for a = nc1-ring : nc1+ring
        if a < 1 || a > n1c, continue; end
        for b = nc2-ring : nc2+ring
            k = a + n1c * b;
            if isKey(first, k)
                r = first(k);
                idx = [idx; ord(r(1):r(2))]; %#ok<AGROW>
            end
        end
    end
end

function o = defaults(opts)
    d = struct('depthAxis', 1, 'depthEval', [], 'depthOrder', 3, ...
               'depthSigma', Inf, 'inPlaneSigma', 1.5, 'cutoff', 3, ...
               'kNN', 0, 'gridSpacing', 1, 'gridLimits', [], ...
               'minParticles', 20, 'maxCond', 1e4);
    o = d;
    f = fieldnames(opts);
    for i = 1:numel(f)
        if ~isfield(d, f{i}), error('particleGradientFit:opt', 'Unknown option "%s".', f{i}); end
        o.(f{i}) = opts.(f{i});
    end
    if ~ismember(o.depthOrder, 1:3), error('particleGradientFit:order', 'depthOrder must be 1, 2 or 3.'); end
end
