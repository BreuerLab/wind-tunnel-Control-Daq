function [se, sigma] = hr_curve_uncertainty(y_raw, y_fit, phi, w, H, Hs)
% HR_CURVE_UNCERTAINTY  Standard error of a harmonic-regression curve
% through phase-binned estimates, with noise that varies through the cycle.
%
%   [se, sigma] = hr_curve_uncertainty(y_raw, y_fit, phi, w, H, Hs)
%
%   y_raw  1 x nb  per-bin estimates (e.g. a force from the unsmoothed fit)
%   y_fit  1 x nb  the H-harmonic curve through them (what is plotted)
%   phi    phase of each bin, cycles (bin_times(nb, 1, bin_placement))
%   w      bin weights used by the fit (image pairs per bin); 0 = empty bin
%   H      harmonics of the curve (20)
%   Hs     harmonics of the noise model (default 3)
%
%   se     1 x nb  standard error of the curve at each bin (1 sigma); a 95%
%          band is +/- 1.96*se
%   sigma  1 x nb  noise of a single bin's estimate (its scatter about the
%          curve)
%
% Method
%   1. Residuals r = y_raw - y_fit. A bin with w image pairs is assumed to
%      have noise variance g(phi)/w: g is the noise per image pair, which
%      may vary smoothly through the cycle.
%   2. g is estimated by fitting w*r^2/(1-h) with Hs harmonics (h: the
%      fit's leverage at that bin, the weight the curve gives the bin's own
%      value; dividing by 1-h undoes the curve having pulled itself toward
%      the bin, which makes raw residuals too small).
%   3. The curve is y_fit = L*y_raw, with L the weighted least-squares
%      "hat" matrix A (A'WA)^-1 A'W (each curve value is a weighted
%      combination of all bins). So var(y_fit_i) = sum_j L_ij^2 sigma_j^2.
%
% Random error only: biases common to all bins (e.g. depth resolution of
% omega_y, trim region) are not in the residuals.

    if nargin < 6 || isempty(Hs), Hs = 3; end
    y_raw = double(y_raw(:));  y_fit = double(y_fit(:));
    w = double(w(:));  phi = double(phi(:));
    nb = numel(y_raw);
    se = nan(1, nb);  sigma = nan(1, nb);

    ok = isfinite(y_raw) & isfinite(y_fit) & w > 0;
    K = 2*H + 1;
    if nnz(ok) < 3*K, return; end

    A = harmonic_basis(phi, H);              % nb x K
    Ao = A(ok, :);  wo = w(ok);
    M = Ao' * (Ao .* wo);
    if rcond(M / sum(wo)) < 1e-6, return; end
    L = A * (M \ (Ao .* wo)');               % nb x n_ok: curve = L * y_raw(ok)

    r = y_raw(ok) - y_fit(ok);
    h = diag(L(ok, :));                      % leverage of each bin
    z = wo .* r.^2 ./ max(1 - h, 0.05);      % noise per image pair, sample

    B = harmonic_basis(phi, Hs);
    c = B(ok, :) \ z;                        % smooth model of the noise
    g = B * c;
    g = max(g, 0.1 * mean(z));               % keep it positive

    s2 = g(ok) ./ wo;                        % noise variance of each bin
    se = sqrt(L.^2 * s2)';
    sig2 = g ./ max(w, eps);
    sig2(w <= 0) = NaN;
    sigma = sqrt(sig2)';
end
