function R = particlePhaseAverage(setPath, bin_ind_arr, fitOpts, opts)
% PARTICLEPHASEAVERAGE  Phase-averaged velocity and vorticity from STB
% particle tracks, using particleGradientFit on the image pairs of each
% phase bin.
%
%   R = particlePhaseAverage(setPath, bin_ind_arr)
%   R = particlePhaseAverage(setPath, bin_ind_arr, fitOpts, opts)
%
%   setPath     : DaVis particle set (as for loadSTBParticles)
%   bin_ind_arr : phase bin of every image pair, e.g. from the phase-avg
%                 .mat saved by phase_avg_STB (pair k = vc7 file k = block k)
%   fitOpts     : options for particleGradientFit (struct, may be empty).
%                 depthEval and gridLimits are fixed from the first pair if
%                 not given, so every bin shares one grid and depth plane.
%   opts        : (defaults)
%     mode          "average"  "average" = fit each pair, then average the
%                              fields (per node, NaN-aware);
%                   "pool"     = put all particles of a bin together, then
%                              fit once (denser, allows a smaller sigma)
%     bins          []         bins to process; [] = all
%     numWorkers    0          parallel workers over bins (0 = serial)
%     binsPerChunk  24         bins whose particles are held in memory at once
%     gridMargin    5          mm added around the first pair's extent
%     saveGradients false      also return the 9 gradient components
%
% R (fields stored as single, size n1 x n2 x nBins, bin order = R.bins):
%   A1, A2, inPlaneAxes, depthEval  grid and evaluation plane
%   U, V, W, omega_x, omega_y, omega_z
%   nValid         pairs with a valid fit at each node ("average"), or
%                  1/0 valid ("pool")
%   N              mean particles in each node's fit neighbourhood
%   omega_*_std    std over pairs at each node ("average" only)
%   G              3 x 3 x n1 x n2 x nBins if saveGradients
%   nPairs         image pairs per bin; mode, fitOpts, opts, setPath

    if nargin < 3 || isempty(fitOpts), fitOpts = struct(); end
    if nargin < 4, opts = struct(); end
    o = struct('mode', "average", 'bins', [], 'numWorkers', 0, ...
               'binsPerChunk', 24, 'gridMargin', 5, 'saveGradients', false);
    f = fieldnames(opts);
    for i = 1:numel(f)
        if ~isfield(o, f{i}), error('particlePhaseAverage:opt', 'Unknown option "%s".', f{i}); end
        o.(f{i}) = opts.(f{i});
    end
    o.mode = lower(string(o.mode));
    if ~ismember(o.mode, ["average", "pool"])
        error('particlePhaseAverage:mode', 'mode must be "average" or "pool".');
    end

    % ---- binning vs particle set ---------------------------------------
    P0 = loadSTBParticles(setPath);
    bin_ind_arr = bin_ind_arr(:);
    if numel(bin_ind_arr) ~= P0.info.n_blocks
        error('particlePhaseAverage:count', ...
            'bin_ind_arr has %d entries but the particle set has %d image pairs.', ...
            numel(bin_ind_arr), P0.info.n_blocks);
    end
    if isempty(o.bins), o.bins = 1:max(bin_ind_arr); end
    bins = o.bins(:)';
    nB = numel(bins);

    % ---- common grid and depth plane from the first pair --------------
    P1 = loadSTBParticles(setPath, 1);
    if ~isfield(fitOpts, 'depthAxis'), fitOpts.depthAxis = 1; end
    if ~isfield(fitOpts, 'gridSpacing'), fitOpts.gridSpacing = 1; end
    dAx = fitOpts.depthAxis;  pAx = setdiff(1:3, dAx);
    if ~isfield(fitOpts, 'depthEval') || isempty(fitOpts.depthEval)
        fitOpts.depthEval = median(P1.data(:, dAx));
    end
    if ~isfield(fitOpts, 'gridLimits') || isempty(fitOpts.gridLimits)
        gs = fitOpts.gridSpacing;  m = o.gridMargin;
        a1 = P1.data(:, pAx(1));  a2 = P1.data(:, pAx(2));
        fitOpts.gridLimits = [gs*floor((min(a1)-m)/gs), gs*ceil((max(a1)+m)/gs), ...
                              gs*floor((min(a2)-m)/gs), gs*ceil((max(a2)+m)/gs)];
    end
    fitOpts.parallel = false;                    % parallelism is over bins here
    lim = fitOpts.gridLimits;
    [A1, A2] = ndgrid(lim(1):fitOpts.gridSpacing:lim(2), lim(3):fitOpts.gridSpacing:lim(4));
    sz = size(A1);

    % ---- preallocate ---------------------------------------------------
    names = ["U" "V" "W" "omega_x" "omega_y" "omega_z"];
    for nm = names, R.(char(nm)) = nan([sz nB], 'single'); end
    R.nValid = zeros([sz nB], 'uint16');
    R.N = nan([sz nB], 'single');                % mean particles per node (fit neighbourhood)
    if o.mode == "average"
        for nm = ["omega_x" "omega_y" "omega_z"], R.(char(nm + "_std")) = nan([sz nB], 'single'); end
    end
    if o.saveGradients, R.G = nan([3 3 sz nB], 'single'); end
    R.nPairs = arrayfun(@(b) nnz(bin_ind_arr == b), bins);

    nw = start_pool(o.numWorkers);

    % ---- process bins in chunks ----------------------------------------
    t0 = tic;
    for c0 = 1:o.binsPerChunk:nB
        cIdx = c0 : min(c0 + o.binsPerChunk - 1, nB);
        data = cell(numel(cIdx), 1);
        for k = 1:numel(cIdx)                    % Python I/O stays on the client
            frames = find(bin_ind_arr == bins(cIdx(k)));
            if isempty(frames), continue; end
            P = loadSTBParticles(setPath, frames);
            data{k} = P.data;
        end

        res = cell(numel(cIdx), 1);
        mode = o.mode;  saveG = o.saveGradients;
        parfor (k = 1:numel(cIdx), nw)
            res{k} = fitBin(data{k}, fitOpts, mode, saveG, sz);
        end

        for k = 1:numel(cIdx)
            j = cIdx(k);  B = res{k};
            if isempty(B), continue; end
            for nm = names, R.(char(nm))(:, :, j) = B.(char(nm)); end
            R.nValid(:, :, j) = B.nValid;
            R.N(:, :, j) = B.N;
            if o.mode == "average"
                for nm = ["omega_x" "omega_y" "omega_z"], R.(char(nm + "_std"))(:, :, j) = B.(char(nm + "_std")); end
            end
            if saveG, R.G(:, :, :, :, j) = B.G; end
        end
        fprintf('bins %d-%d of %d done (%.0f s elapsed)\n', c0, cIdx(end), nB, toc(t0));
    end

    R.A1 = A1;  R.A2 = A2;  R.inPlaneAxes = pAx;  R.depthAxis = dAx;
    R.depthEval = fitOpts.depthEval;  R.bins = bins;
    R.mode = o.mode;  R.fitOpts = fitOpts;  R.opts = o;  R.setPath = string(setPath);
end

% -------------------------------------------------------------------------
function B = fitBin(D, fitOpts, mode, saveG, sz)
    B = [];
    if isempty(D), return; end
    names = ["U" "V" "W" "omega_x" "omega_y" "omega_z"];

    if mode == "pool"
        F = particleGradientFit(D(:, 1:6), fitOpts);
        for nm = names, B.(char(nm)) = single(F.(char(nm))); end
        B.nValid = uint16(isfinite(F.U));
        B.N = single(F.N);
        if saveG, B.G = single(F.G); end
        return
    end

    % "average": fit each image pair, accumulate NaN-aware sums
    blocks = unique(D(:, 10));
    S = struct();  S2 = struct();
    for nm = names, S.(char(nm)) = zeros(sz); end
    for nm = ["omega_x" "omega_y" "omega_z"], S2.(char(nm)) = zeros(sz); end
    cnt = zeros(sz);  SN = zeros(sz);
    if saveG, SG = zeros([3 3 sz]); end
    for b = blocks'
        F = particleGradientFit(D(D(:, 10) == b, 1:6), fitOpts);
        ok = isfinite(F.U) & isfinite(F.omega_x) & isfinite(F.omega_y) & isfinite(F.omega_z);
        cnt = cnt + ok;
        SN  = SN + F.N;
        for nm = names
            v = F.(char(nm));  v(~ok) = 0;  S.(char(nm)) = S.(char(nm)) + v;
        end
        for nm = ["omega_x" "omega_y" "omega_z"]
            v = F.(char(nm));  v(~ok) = 0;  S2.(char(nm)) = S2.(char(nm)) + v.^2;
        end
        if saveG
            g = F.G;  g(:, :, ~ok) = 0;  SG = SG + g;
        end
    end
    c = cnt;  c(c == 0) = NaN;
    for nm = names, B.(char(nm)) = single(S.(char(nm)) ./ c); end
    for nm = ["omega_x" "omega_y" "omega_z"]
        m = S.(char(nm)) ./ c;
        v = (S2.(char(nm)) - c .* m.^2) ./ (c - 1);     % sample variance
        v(cnt < 2) = NaN;
        B.(char(nm + "_std")) = single(sqrt(max(v, 0)));
    end
    B.nValid = uint16(cnt);
    B.N = single(SN / numel(blocks));
    if saveG, B.G = single(SG ./ reshape(c, [1 1 sz])); end
end
