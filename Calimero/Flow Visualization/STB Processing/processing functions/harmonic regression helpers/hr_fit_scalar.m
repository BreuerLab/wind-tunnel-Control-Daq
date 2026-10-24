function [fit, c, resid_std] = hr_fit_scalar(y, phi, H, phi_eval)
% HR_FIT_SCALAR Harmonic regression of one per-frame time series.
%
%   [fit, c, resid_std] = hr_fit_scalar(y, phi, H, phi_eval)
%
%   y        - one value per frame (e.g. lift computed on each frame)
%   phi      - phase of each frame, in cycles
%   H        - number of harmonics
%   phi_eval - phases to evaluate the fit at (e.g. bin centres)
%
%   fit       - fitted values at phi_eval (row vector)
%   c         - K x 1 coefficients of harmonic_basis
%   resid_std - standard deviation of y about the fit (cycle-to-cycle
%               variability plus noise), NaN frames skipped

y = double(y(:));
phi = double(phi(:));
ok = isfinite(y) & isfinite(phi);
K = 2*H + 1;
if sum(ok) < 3*K
    fit = NaN(1, numel(phi_eval));
    c = NaN(K, 1);
    resid_std = NaN;
    return
end

A = harmonic_basis(phi(ok), H);
c = A \ y(ok);
fit = (harmonic_basis(phi_eval, H) * c).';
resid_std = std(y(ok) - A*c);
end
