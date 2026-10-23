function A = nanRegionFill(A)
% NANREGIONFILL Fill NaN holes in a velocity field by Laplace (harmonic)
% interpolation from the surrounding valid data, one 2-D plane at a time.
%
%   A = nanRegionFill(A)
%
%   A is [n1 n2 ...]; each 2-D slice A(:,:,k,...) (e.g. a y-z Trefftz
%   plane for one phase bin) is filled independently with regionfill
%   (Image Processing Toolbox). Use this on velocity components, then
%   compute vorticity from the filled field - don't fill vorticity itself.
%
%   Slices that are entirely NaN are left for the fallback at the end,
%   which uses the median of all valid values.

    if ~any(isnan(A), 'all')
        return
    end

    sz = size(A);
    A = reshape(A, sz(1), sz(2), []);

    for k = 1:size(A, 3)
        S = A(:,:,k);
        mask = isnan(S);
        if ~any(mask, 'all') || all(mask, 'all')
            continue
        end
        S(mask) = 0; % values under the mask are ignored by regionfill
        A(:,:,k) = regionfill(S, mask);
    end

    A = reshape(A, sz);

    % fallback for slices with no valid data at all
    if any(isnan(A), 'all')
        A(isnan(A)) = median(A, "all", "omitnan");
    end
end
