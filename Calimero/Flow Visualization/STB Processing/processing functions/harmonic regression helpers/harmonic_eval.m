function F = harmonic_eval(coef, phi, deriv, freq)
% HARMONIC_EVAL Evaluate a harmonic fit (or its derivative) at given phases.
%
%   F = harmonic_eval(coef, phi)                 % field values
%   F = harmonic_eval(coef, phi, deriv)          % d^deriv/dphi^deriv
%   F = harmonic_eval(coef, phi, deriv, freq)    % d^deriv/dt^deriv
%
%   coef  - [nx ny nz K] (as saved in *_hr_coef) or npts x K
%   phi   - phases in cycles, e.g. bin centres or any finer grid
%   deriv - derivative order (default 0)
%   freq  - wingbeat frequency (Hz). Given, the derivative is with respect
%           to time (phi = freq*t); omitted, with respect to phase.
%
%   F is [nx ny nz numel(phi)] (or npts x numel(phi) for npts x K input).
%   Derivatives are exact derivatives of the fitted series, so no finite
%   differences between bins are needed.

if nargin < 3 || isempty(deriv), deriv = 0; end

sz = size(coef);
K = sz(end);
H = (K - 1) / 2;
if H ~= round(H)
    error("harmonic_eval: last dimension of coef must be 2H+1, got %d", K)
end

E = harmonic_basis(phi, H, deriv);          % nphi x K
if nargin >= 4 && ~isempty(freq)
    E = E * freq^deriv;
end

C = reshape(coef, [], K);
F = C * E.';
if numel(sz) > 2
    F = reshape(F, [sz(1:end-1), numel(phi)]);
end
end
