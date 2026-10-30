function [f0, dfdx, sig_f0, sig_dfdx, chi2red, n_used] = slab_poly_fit(F, sig, dx, order, i0)
% SLAB_POLY_FIT Weighted least-squares polynomial fit across the binned
% planes of the STB slab (dimension 1), evaluated at plane i0.
%
%   [f0, dfdx, sig_f0, sig_dfdx, chi2red, n_used] = slab_poly_fit(F, sig, dx, order, i0)
%
%   F      [nx, ...] field, planes along dim 1 (e.g. [5, ny, nz])
%   sig    same size as F (or [nx,1]): 1-sigma uncertainty of each value.
%          Weights are 1/sig^2. NaN/Inf/0 sigma or NaN F -> weight 0.
%   dx     plane spacing (same units as x)
%   order  polynomial order (default 2). With 5 planes, order 2 gives the
%          derivative at the centre plane without curvature bias even when
%          the weights are not symmetric about the centre.
%   i0     plane index to evaluate at (default: centre, (nx+1)/2)
%
%   Outputs are size(F) without dim 1 (squeezed to [ny, nz] for 3-D input):
%   f0       fitted value at plane i0 (noise-weighted smoothing across x)
%   dfdx     fitted derivative dF/dx at plane i0
%   sig_f0, sig_dfdx  1-sigma uncertainties from the WLS covariance
%   chi2red  reduced chi^2 of the fit (NaN when dof <= 0). ~1 means the
%            sigmas are consistent with the scatter about the fit; >>1
%            means the sigmas are too small or the polynomial is too low
%            order.
%   n_used   number of planes that carried weight
%
%   Columns with fewer than order+1 usable planes return NaN.

if nargin < 4 || isempty(order), order = 2; end
nx = size(F, 1);
if nargin < 5 || isempty(i0), i0 = (nx + 1) / 2; end

sz = size(F);
outSize = sz(2:end);
if numel(outSize) == 1, outSize = [outSize 1]; end

F = reshape(F, nx, []);
M = size(F, 2);
if isvector(sig) && numel(sig) == nx
    sig = repmat(sig(:), 1, M);
else
    sig = reshape(sig, nx, []);
end

% Fit in plane-index units (well conditioned), rescale derivative by dx.
s = (1:nx)' - i0;
p = order + 1;
X = s .^ (0:order);                     % [nx, p]

W = 1 ./ sig.^2;
valid = isfinite(F) & isfinite(W) & W > 0;
W(~valid) = 0;
F(~valid) = 0;
n_used = sum(valid, 1);

% Normal equations for every column at once: A = X'WX, b = X'WF
A = zeros(p, p, M);
b = zeros(p, 1, M);
for a = 1:p
    for c = a:p
        A(a, c, :) = reshape(sum(W .* (X(:, a) .* X(:, c)), 1), 1, 1, M);
        A(c, a, :) = A(a, c, :);
    end
    b(a, 1, :) = reshape(sum(W .* X(:, a) .* F, 1), 1, 1, M);
end

ok = n_used >= p;
C = nan(p, p, M);                       % covariance = inv(X'WX)
if any(ok)
    if exist('pageinv', 'builtin') || exist('pageinv', 'file')
        C(:, :, ok) = pageinv(A(:, :, ok));
    else
        idx = find(ok);
        for m = idx
            C(:, :, m) = inv(A(:, :, m));
        end
    end
end

coef = nan(p, M);
for a = 1:p
    coef(a, :) = reshape(sum(C(a, :, :) .* permute(b, [2 1 3]), 2), 1, M);
end

f0       = coef(1, :);
dfdx     = coef(2, :) / dx;
sig_f0   = sqrt(reshape(C(1, 1, :), 1, M));
sig_dfdx = sqrt(reshape(C(2, 2, :), 1, M)) / dx;

% Reduced chi^2 of the residuals
res = F - X * coef;
res(~valid) = 0;
dof = n_used - p;
chi2red = sum(W .* res.^2, 1) ./ dof;
chi2red(dof <= 0) = NaN;

f0(~ok) = NaN; dfdx(~ok) = NaN; sig_f0(~ok) = NaN; sig_dfdx(~ok) = NaN;

f0       = reshape(f0, outSize);
dfdx     = reshape(dfdx, outSize);
sig_f0   = reshape(sig_f0, outSize);
sig_dfdx = reshape(sig_dfdx, outSize);
chi2red  = reshape(chi2red, outSize);
n_used   = reshape(n_used, outSize);
end
