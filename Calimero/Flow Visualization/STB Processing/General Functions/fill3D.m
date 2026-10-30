function A = fill3D(A, nIter)
% FILL3D Fill NaN holes in a 2-D or 3-D gridded field (one frame).
%
%   A = fill3D(A)          % 20 relaxation sweeps
%   A = fill3D(A, nIter)
%
%   1) Normalized convolution: each NaN bin bordering valid data takes the
%      average of its valid neighbours, growing inward until no holes are
%      left (small holes need 1-2 passes).
%   2) nIter Jacobi sweeps relax the hole values toward the Laplace
%      (harmonic) fill, the same interpolant regionfill uses.
%   Only NaN entries are modified. Vectorized with convn, so it is much
%   faster than the previous fillmissing-based version. Assumes uniform
%   grid spacing (regular binning). Arrays that are entirely NaN are
%   returned unchanged.

    if nargin < 2, nIter = 20; end
    holes = isnan(A);
    if ~any(holes, 'all'), return; end
    if all(holes, 'all'), return; end          % no data to fill from

    if ismatrix(A)
        K = ones(3);                                % 8 neighbours
        L = [0 1 0; 1 0 1; 0 1 0];                  % 4 face neighbours
    else
        K = ones(3,3,3);                            % 26 neighbours
        L = zeros(3,3,3); L([5 11 13 15 17 23]) = 1;    % 6 face neighbours
    end

    % 1) Fill inward from hole edges with the average of known neighbours
    filled = ~holes;
    A(holes) = 0;
    while ~all(filled, 'all')
        num = convn(A, K, 'same');
        den = convn(double(filled), K, 'same');
        newly = ~filled & den > 0;
        A(newly) = num(newly) ./ den(newly);
        filled = filled | newly;
    end

    % 2) Relax hole values toward the harmonic (Laplace) fill
    cnt = convn(ones(size(A)), L, 'same');          % neighbour count at edges
    for it = 1:nIter
        nb = convn(A, L, 'same') ./ cnt;
        A(holes) = nb(holes);
    end
end
