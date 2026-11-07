function A = harmonic_basis(phi, H, deriv)
% HARMONIC_BASIS Fourier basis in wingbeat phase.
%
%   A = harmonic_basis(phi, H)         % values
%   A = harmonic_basis(phi, H, deriv)  % deriv-th derivative w.r.t. phase
%
%   phi   - phases in cycles (0 to 1 is one wingbeat), any shape
%   H     - number of harmonics
%   deriv - derivative order with respect to phi (default 0). For a time
%           derivative multiply the result by freq^deriv (phi = freq*t).
%
%   A is numel(phi) x K, K = 2H+1, with columns
%       [1, cos(2*pi*phi), sin(2*pi*phi), ..., cos(2*pi*H*phi), sin(2*pi*H*phi)]
%   A field with coefficients c (K x 1) is f(phi) = A*c.

if nargin < 3 || isempty(deriv), deriv = 0; end

phi = phi(:);
K = 2*H + 1;
A = zeros(numel(phi), K);
A(:,1) = double(deriv == 0);

% d^n/dphi^n cos(w*phi) = w^n cos(w*phi + n*pi/2), same for sin
shift = deriv * pi/2;
for h = 1:H
    w = 2*pi*h;
    A(:, 2*h)   = w^deriv * cos(w*phi + shift);
    A(:, 2*h+1) = w^deriv * sin(w*phi + shift);
end
end
