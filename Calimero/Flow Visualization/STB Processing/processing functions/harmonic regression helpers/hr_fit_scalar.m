function [fit, c, resid_std, resid_std_phase] = hr_fit_scalar(y, phi, H, phi_eval)
% HR_FIT_SCALAR Harmonic regression of one per-frame time series.
%
%   [fit, c, resid_std, resid_std_phase] = hr_fit_scalar(y, phi, H, phi_eval)
%
%   y        - one value per frame (e.g. lift computed on each frame)
%   phi      - phase of each frame, in cycles
%   H        - number of harmonics
%   phi_eval - phases to evaluate the fit at (e.g. bin centres)
%
%   fit             - fitted values at phi_eval (row vector)
%   c               - K x 1 coefficients of harmonic_basis
%   resid_std       - standard deviation of y about the fit (cycle-to-cycle
%                     variability plus noise), NaN frames skipped
%   resid_std_phase - the same resolved in phase: RMS of the residuals
%                     y - fit(phi) of the frames nearest each phi_eval
%                     (periodic; with bin centres these are the frames of
%                     each bin), row vector like fit. The counterpart of
%                     the bin SD of a bin average, but about the fitted
%                     curve rather than the bin mean, so the phase spread
%                     within a bin isn't counted as scatter. NaN where no
%                     frame is nearest.

y = double(y(:));
phi = double(phi(:));
ok = isfinite(y) & isfinite(phi);
K = 2*H + 1;
nphi = numel(phi_eval);
if sum(ok) < 3*K
    fit = NaN(1, nphi);
    c = NaN(K, 1);
    resid_std = NaN;
    resid_std_phase = NaN(1, nphi);
    return
end

A = harmonic_basis(phi(ok), H);
c = A \ y(ok);
fit = (harmonic_basis(phi_eval, H) * c).';
r = y(ok) - A*c;
resid_std = std(r);

% residuals grouped by the nearest evaluation phase (periodic distance)
phi_ok = phi(ok);
d = abs(mod(phi_ok - double(phi_eval(:)).' + 0.5, 1) - 0.5);   % nframes x nphi
[~, nearest] = min(d, [], 2);
n_near = accumarray(nearest, 1, [nphi 1]);
ss_near = accumarray(nearest, r.^2, [nphi 1]);
resid_std_phase = sqrt(ss_near ./ n_near).';
resid_std_phase(n_near == 0) = NaN;
end
