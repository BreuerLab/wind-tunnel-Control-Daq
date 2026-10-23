function m = periodic_mean(f, t, period, dim)
% PERIODIC_MEAN Time average over one period of an unevenly sampled
% periodic signal (trapezoidal weights, wrapping around the period).
% For uniform t this equals mean(f, dim).
if nargin < 4 || isempty(dim)
    dim = find(size(f) > 1, 1, 'last');
end
t = t(:);
tp = [t(end) - period; t; t(1) + period];
w = (tp(3:end) - tp(1:end-2)) / 2;           % sums to period
shp = ones(1, max(ndims(f), dim)); shp(dim) = numel(t);
m = sum(reshape(w, shp) .* f, dim) / period;
end
