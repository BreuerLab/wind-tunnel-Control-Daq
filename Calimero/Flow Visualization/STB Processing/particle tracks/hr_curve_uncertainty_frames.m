function se = hr_curve_uncertainty_frames(s, n, phi, w, H, M)
% HR_CURVE_UNCERTAINTY_FRAMES  Standard error of a harmonic-regression
% curve through phase-binned estimates, with each bin's noise taken from
% the frame-to-frame scatter of the per-frame values instead of from the
% curve's residuals (hr_curve_uncertainty).
%
%   se = hr_curve_uncertainty_frames(s, n, phi, w, H)
%   se = hr_curve_uncertainty_frames(s, n, phi, w, H, M)
%
%   s    1 x nb  frame-to-frame SD of the per-frame value in each bin
%                (binned processing: *_before_std, e.g. lift_before_std.vortX)
%   n    1 x nb  frames (image pairs) in each bin
%   phi  phase of each bin, cycles (bin_times(nb, 1, bin_placement))
%   w    bin weights used by the fit (image pairs per bin); 0 = empty bin
%   H    harmonics of the curve (20)
%   M    optional nb x nb linear operator applied to the fitted curve,
%        e.g. the time integral of a rate (lift_vortY_operator); default I
%
%   se   1 x nb  standard error (1 sigma) of M * curve at each bin; a 95%
%        band is +/- 1.96*se
%
% Method
%   A bin's estimate is a mean over its n_j frames, so its noise variance
%   is s_j^2 / n_j (frames independent). The curve is y_fit = L*y_raw with
%   L = A (A'WA)^-1 A'W the weighted least-squares "hat" matrix of the
%   harmonic basis A, and the plotted quantity is M*y_fit, so
%       var_i = sum_j (M L)_ij^2 s_j^2 / n_j.
%   With constant s this is about s * sqrt((2H+1) / N_total).
%
% Unlike hr_curve_uncertainty the noise level does not come from the
% scatter of the binned estimates about the curve, so it is not reduced if
% those estimates are smoother than a bin mean of independent frames would
% be (e.g. pooled particle fits). s includes the single-frame measurement
% noise of the binned fields, which pooling particles reduces, so it is on
% the conservative side for the particle method. Still random error only,
% frames assumed independent: drift over the run (shared by many bins) and
% systematic errors are not included.

    s = double(s(:));  n = double(n(:));  w = double(w(:));  phi = double(phi(:));
    nb = numel(phi);
    se = nan(1, nb);
    if nargin < 6 || isempty(M), M = eye(nb); end
    if numel(s) ~= nb || numel(n) ~= nb || numel(w) ~= nb, return; end

    ok_fit = w > 0;
    K = 2*H + 1;
    if nnz(ok_fit) < 3*K, return; end
    A = harmonic_basis(phi, H);              % nb x K
    Ao = A(ok_fit, :);  wo = w(ok_fit);
    G = Ao' * (Ao .* wo);
    if rcond(G / sum(wo)) < 1e-6, return; end
    L = zeros(nb, nb);
    L(:, ok_fit) = A * (G \ (Ao .* wo)');    % curve = L * y_raw

    v = s.^2 ./ max(n, 1);                   % noise variance of each bin's estimate
    % bins in the fit without an SD (e.g. a single frame): the median
    % noise of the others, not zero
    missing = ok_fit & ~(isfinite(v) & n > 0);
    v(missing) = median(v(ok_fit & ~missing), "omitnan");
    v(~ok_fit) = 0;                          % bins left out of the fit add nothing
    ML = M * L;
    se = sqrt(ML.^2 * v)';
    se(~any(isfinite(ML), 2)) = NaN;
end
