function df = periodic_ddt(f, t, period, dim)
% PERIODIC_DDT Time derivative of a periodic, unevenly sampled signal.
%
%   df = periodic_ddt(f, t, period)       % along the last non-singleton dim
%   df = periodic_ddt(f, t, period, dim)
%
%   t (one value per sample along dim, increasing, within one period) is
%   e.g. from bin_times. Uses the 3-point, second-order formula for
%   unequal spacing, wrapping around the period:
%     h1 = t_k - t_{k-1},  h2 = t_{k+1} - t_k
%     f'_k = (h1^2 f_{k+1} - h2^2 f_{k-1} + (h2^2 - h1^2) f_k) / (h1 h2 (h1 + h2))
%   For uniform t this is the usual central difference.

if nargin < 4 || isempty(dim)
    dim = find(size(f) > 1, 1, 'last');
end
t = t(:);
n = numel(t);
if size(f, dim) ~= n
    error("periodic_ddt: size(f, %d) = %d but numel(t) = %d", dim, size(f, dim), n);
end

tp = [t(end) - period; t; t(1) + period];
h1 = tp(2:end-1) - tp(1:end-2);
h2 = tp(3:end)   - tp(2:end-1);
a = -h2.^2        ./ (h1.*h2.*(h1 + h2));   % weight on f_{k-1}
b = (h2.^2 - h1.^2) ./ (h1.*h2.*(h1 + h2)); % weight on f_k
c =  h1.^2        ./ (h1.*h2.*(h1 + h2));   % weight on f_{k+1}

shp = ones(1, max(ndims(f), dim)); shp(dim) = n;
a = reshape(a, shp); b = reshape(b, shp); c = reshape(c, shp);
df = a .* circshift(f, 1, dim) + b .* f + c .* circshift(f, -1, dim);
end
