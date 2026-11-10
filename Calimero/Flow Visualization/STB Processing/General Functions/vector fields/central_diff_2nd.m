function d = central_diff_2nd(A, h, dim)
% CENTRAL_DIFF_2ND First derivative of A along dimension dim.
%
%   d = central_diff_2nd(A, h, dim)
%
%   Interior points: 2nd-order central difference (A(i+1) - A(i-1)) / (2h),
%   so on a 5-plane STB slab the centre plane uses planes 2 and 4 only.
%   First and last points: 1st-order one-sided difference, so the edges are
%   finite (as with MATLAB's gradient()). A can have any number of
%   dimensions (e.g. [nx ny nz] or [nx ny nz nFrames]); h is the grid
%   spacing along dim (pass a signed spacing for a derivative with respect
%   to the coordinate, |spacing| for one with respect to array index).

n = size(A, dim);
if n < 2
    d = NaN(size(A));
    return
end

perm = [dim, setdiff(1:max(ndims(A), dim), dim)];
B = permute(A, perm);
sz = size(B);
B = reshape(B, n, []);

D = NaN(size(B));
if n >= 3
    D(2:n-1, :) = (B(3:n, :) - B(1:n-2, :)) / (2 * h);
end
D(1, :) = (B(2, :) - B(1, :)) / h;
D(n, :) = (B(n, :) - B(n-1, :)) / h;

d = ipermute(reshape(D, sz), perm);
end
