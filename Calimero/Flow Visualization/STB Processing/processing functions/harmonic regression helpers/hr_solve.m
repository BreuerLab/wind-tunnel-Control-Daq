function [coef, info] = hr_solve(acc, opts)
% HR_SOLVE Harmonic regression coefficients from accumulated sums.
%
%   [coef, info] = hr_solve(acc)
%   [coef, info] = hr_solve(acc, opts)
%
%   acc  - from hr_accumulate / hr_merge
%   opts.min_count  - fewest valid frames a point needs to be fitted
%                     (default 3*K); fewer gives NaN, like an empty bin
%   opts.rcond_tol  - points with missing frames are also NaN when their
%                     normal matrix (scaled by the frame count) has
%                     rcond below this, i.e. the valid frames don't cover
%                     the cycle well enough to pin down K coefficients
%                     (default 1e-3; uniform coverage gives about 0.5)
%
%   coef - npts x K x nf, coefficients of harmonic_basis for every point
%          and field. Evaluate with harmonic_eval.
%   info - fields: H, K, N (frames), rcond (all frames), num_nan (points
%          left NaN per field), num_corrected (points with missing frames
%          per field)

if nargin < 2, opts = struct(); end
K = acc.K;
if ~isfield(opts, 'min_count'), opts.min_count = 3*K; end
if ~isfield(opts, 'rcond_tol'), opts.rcond_tol = 1e-3; end
block = 5000;      % points per page solve, limits memory
well_frac = 0.9;   % >= this fraction of frames present: skip the rcond check

G = acc.G;
rc = rcond(G / acc.N);
if rc < opts.rcond_tol
    error("hr_solve: the frame phases can't support %d harmonics (rcond %.2g). " + ...
        "Use fewer harmonics.", acc.H, rc)
end

coef = zeros(acc.npts, K, acc.nf);
info.H = acc.H; info.K = K; info.N = acc.N; info.rcond = rc;
info.num_nan = zeros(1, acc.nf);
info.num_corrected = zeros(1, acc.nf);

% Fields with no missing data anywhere: one shared solve
for f = find(acc.grp == 0)
    coef(:,:,f) = (G \ acc.rhs(:,:,f).').';
end

[lin_up, lin_lo] = packed_index(acc.pairs, K);
use_pages = exist('pagemldivide', 'builtin') > 0 || exist('pagemldivide', 'file') > 0;

for g = 1:numel(acc.C)
    fg = find(acc.grp == g);
    Cg = acc.C{g};
    corrected = any(Cg ~= 0, 2);

    % points of this group that never had missing frames
    full_pts = find(~corrected);
    for f = fg
        coef(full_pts,:,f) = (G \ acc.rhs(full_pts,:,f).').';
    end

    % points with missing frames: their own normal matrix G - C_p
    pts = find(corrected);
    cnt = acc.cnt(pts, fg(1));          % same for every field in the group
    too_few = cnt < opts.min_count;
    well = ~too_few & cnt >= well_frac * acc.N;
    sparse_pts = ~too_few & ~well;

    coef(pts(too_few),:,fg) = NaN;

    % well covered: batched solves
    idx = pts(well);
    for b0 = 1:block:numel(idx)
        ib = idx(b0:min(b0+block-1, end));
        Gp = G - unpack(Cg(ib,:), lin_up, lin_lo, K);
        Rp = permute(acc.rhs(ib,:,fg), [2 3 1]);   % K x nfg x m
        if use_pages
            X = pagemldivide(Gp, Rp);
        else
            X = zeros(size(Rp));
            for j = 1:numel(ib)
                X(:,:,j) = Gp(:,:,j) \ Rp(:,:,j);
            end
        end
        coef(ib,:,fg) = permute(X, [3 1 2]);
    end

    % sparsely covered: check conditioning point by point
    idx = pts(sparse_pts);
    nc = cnt(sparse_pts);
    for b0 = 1:block:numel(idx)
        ib = idx(b0:min(b0+block-1, end));
        Gp = G - unpack(Cg(ib,:), lin_up, lin_lo, K);
        Rp = permute(acc.rhs(ib,:,fg), [2 3 1]);
        X = NaN(size(Rp));
        for j = 1:numel(ib)
            Gj = Gp(:,:,j);
            if rcond(Gj / nc(b0 + j - 1)) >= opts.rcond_tol
                X(:,:,j) = Gj \ Rp(:,:,j);
            end
        end
        coef(ib,:,fg) = permute(X, [3 1 2]);
    end

    info.num_corrected(fg) = numel(pts);
end

for f = 1:acc.nf
    info.num_nan(f) = sum(any(isnan(coef(:,:,f)), 2));
end
end

function [lin_up, lin_lo] = packed_index(pairs, K)
lin_up = sub2ind([K K], pairs(:,1), pairs(:,2));
lin_lo = sub2ind([K K], pairs(:,2), pairs(:,1));
end

function M = unpack(V, lin_up, lin_lo, K)
% packed rows (m x P) -> symmetric K x K x m
m = size(V, 1);
B = zeros(K*K, m);
B(lin_up, :) = V.';
B(lin_lo, :) = V.';
M = reshape(B, K, K, m);
end
