function R = particleHarmonicSmooth(R, H, bin_placement)
% PARTICLEHARMONICSMOOTH  Harmonic regression across phase bins of a
% particlePhaseAverage result: at every grid node each field's bin-to-bin
% series is fitted with a Fourier series of H wingbeat harmonics
% (harmonic_basis, as harmonic_regression_STB) and replaced by the fit.
%
%   R = particleHarmonicSmooth(R, H)
%   R = particleHarmonicSmooth(R, H, bin_placement)
%
%   R             : from particlePhaseAverage (all bins, R.bins = 1:num_bins)
%   H             : number of harmonics (10 as bools.num_harmonics)
%   bin_placement : mean frame phase minus bin centre, % of a bin width
%                   (saved in the binned *_phase_avg.mat). The fit uses
%                   each bin's actual mean phase (bin_times) and is
%                   evaluated there, so bin times are unchanged downstream.
%
% Bins are weighted by their number of image pairs (empty bins drop out).
% Nodes keep NaN in bins where the fit was NaN (outside the lit region),
% so the mask is unchanged. Nodes valid in fewer than 3*(2H+1) bins, or
% whose valid bins don't cover the cycle well, are left as they were.
%
% Linear in the data, so integrals over the plane are smoothed the same
% way as the fields: force time series lose content above H x the
% wingbeat frequency (bin-to-bin jitter) and keep the rest.
% Applied to U, V, W, omega_x/y/z, N and (if present) the gradients G.

    nb = numel(R.bins);
    if any(R.bins(:)' ~= 1:nb)
        error('particleHarmonicSmooth:bins', 'R must hold all bins 1..num_bins.');
    end
    if nargin < 3, bin_placement = []; end
    phi = bin_times(nb, 1, bin_placement);       % phases in cycles (period 1)
    A   = harmonic_basis(phi, H);                % nb x K
    K   = size(A, 2);
    w   = double(R.nPairs(:));                   % weight per bin
    minValid = 3 * K;

    names = {'U', 'V', 'W', 'omega_x', 'omega_y', 'omega_z', 'N'};
    sz = size(R.U);  sz = sz(1:2);
    for k = 1:numel(names)
        F = reshape(double(R.(names{k})), [], nb);
        R.(names{k}) = single(reshape(fitSeries(F, A, w, minValid), [sz nb]));
    end
    if isfield(R, 'G')
        Gs = size(R.G);                          % [3 3 n1 n2 nb]
        G = reshape(double(R.G), [], nb);
        R.G = single(reshape(fitSeries(G, A, w, minValid), Gs));
    end
    R.hr = struct('H', H, 'phases', phi, 'weights', w);
end

% -------------------------------------------------------------------------
function F = fitSeries(F, A, w, minValid)
% weighted least-squares Fourier fit of every row of F (points x bins)
    valid = isfinite(F) & (w' > 0);
    nv = sum(valid, 2);

    % points valid in every bin that has pairs: one shared solve (empty
    % bins, NaN for every point, get the fitted value)
    full = nv == nnz(w > 0);
    if any(full)
        M  = A' * (A .* w);
        Ff = F(full, :);  Ff(:, w <= 0) = 0;     % weight 0 there anyway
        C  = (M \ (A' * (Ff .* w')'))';          % points x K
        F(full, :) = C * A';
    end

    % points with some missing bins: individual solves
    part = find(~full & nv >= minValid);
    for i = part'
        v  = valid(i, :)';
        Av = A(v, :);  wv = w(v);
        M  = Av' * (Av .* wv);
        if rcond(M / sum(wv)) < 1e-3, continue; end   % valid bins don't cover the cycle
        c  = M \ (Av' * (F(i, v)' .* wv));
        fi = (A * c)';
        fi(~valid(i, :)) = NaN;                      % keep the mask
        F(i, :) = fi;
    end
    % points with too few valid bins are left unchanged
end
